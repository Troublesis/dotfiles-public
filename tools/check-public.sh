#!/usr/bin/env bash
# Public-repo leak gate. Blocks personal info and secrets before they reach a public repo.
#
#   tools/check-public.sh --staged      what is about to be committed (pre-commit)
#   tools/check-public.sh --tree        every tracked + untracked-unignored file
#   tools/check-public.sh --history     every added line in all commits + gitleaks history
#   tools/check-public.sh --identity    author/committer emails of all commits + local user.email
#   tools/check-public.sh --all         tree + history + identity   (pre-push, CI)
#
# Layer 1 (generic, always on): forbidden file names, IPv4 literals, home paths, emails,
#   private-key headers, gitleaks.
# Layer 2 (personal, local only): regexes from $DOTFILES_DENYLIST
#   (default ~/.config/dotfiles/denylist, shipped by the private overlay). Never lives in
#   this repo — a denylist here would itself leak the words. Skipped (with a warning) when
#   absent; set REQUIRE_DENYLIST=1 to make that an error.
#
# Output prints file:line and a label only (CI logs are public). VERBOSE=1 prints matches.
# Allow a deliberate exception on one line with the marker:  gate:allow
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
DENYLIST="${DOTFILES_DENYLIST:-$HOME/.config/dotfiles/denylist}"
NOREPLY_RE='^[0-9]+\+[A-Za-z0-9-]+@users\.noreply\.github\.com$'
FORBIDDEN_NAMES='(^|/)encrypted_|(^|/)id_(rsa|ed25519|ecdsa|dsa)[^/]*$|\.(age|key|pem|p12|pfx|gpg|kdbx)$|(^|/)\.env($|\.)|(^|/)\.?zsh_secrets'

red()  { printf '\033[1;31m%s\033[0m\n' "$*" >&2; }
warn() { printf '\033[1;33m%s\033[0m\n' "$*" >&2; }
fails=0
fail() { red "gate: $*"; fails=$((fails + 1)); }

# label<TAB>PCRE   (lookarounds → rg -P)
GENERIC=(
"ipv4-literal	(?<![\\d.~])(?!(?:127\\.0\\.0\\.1|0\\.0\\.0\\.0|255\\.255\\.255\\.\\d+)(?![\\d.]))(?:\\d{1,3}\\.){3}\\d{1,3}(?![\\d.]|/\\d)"
"home-path	/Users/(?!Shared\\b|user\\b|username\\b|you\\b|name\\b|\\{\\{|\\$|<|\\*)[A-Za-z0-9._-]+|/home/(?!linuxbrew\\b|user\\b|username\\b|you\\b|name\\b|\\{\\{|\\$|<|\\*)[a-z_][a-z0-9_-]*|[A-Za-z]:\\\\Users\\\\(?!\\{\\{|%|<)[A-Za-z0-9._ -]+"
"email	(?<![A-Za-z0-9._%+-])(?!git@github\\.com|git@gitlab\\.com|[0-9]+\\+[A-Za-z0-9-]+@users\\.noreply\\.github\\.com|[A-Za-z0-9._%+-]+@example\\.(?:com|org))[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,}"
"private-key	-----BEGIN [A-Z ]*PRIVATE KEY-----|AGE-SECRET-KEY-1[A-Z0-9]{10,}"
)

# scan_files: reads NUL-separated paths (relative to $PWD) on stdin
scan_files() {
  local files; files="$(mktemp)"; cat > "$files"
  [[ -s "$files" ]] || { rm -f "$files"; return 0; }
  local names; names="$(tr '\0' '\n' < "$files" | grep -E "$FORBIDDEN_NAMES" || true)"
  [[ -z "$names" ]] || { fail "forbidden file name(s):"; printf '    %s\n' $names >&2; }
  local entry label re out
  for entry in "${GENERIC[@]}"; do
    label="${entry%%$'\t'*}"; re="${entry#*$'\t'}"
    out="$(xargs -0 rg -n --no-heading -P -e "$re" < "$files" 2>/dev/null | grep -v 'gate:allow' || true)"
    if [[ -n "$out" ]]; then
      fail "[$label] in:"
      if [[ "${VERBOSE:-0}" == 1 ]]; then printf '%s\n' "$out" >&2
      else printf '%s\n' "$out" | sed -E 's/^([^:]+:[0-9]+):.*/    \1/' >&2; fi
    fi
  done
  if [[ -r "$DENYLIST" ]]; then
    local alt; alt="$(grep -Ev '^[[:space:]]*(#|$)' "$DENYLIST" | paste -sd '|' -)"
    if [[ -n "$alt" ]]; then
      out="$(xargs -0 rg -n --no-heading -i -e "$alt" < "$files" 2>/dev/null | grep -v 'gate:allow' || true)"
      if [[ -n "$out" ]]; then
        fail "[personal-denylist] in:"
        if [[ "${VERBOSE:-0}" == 1 ]]; then printf '%s\n' "$out" >&2
        else printf '%s\n' "$out" | sed -E 's/^([^:]+:[0-9]+):.*/    \1/' >&2; fi
      fi
    fi
  elif [[ "${REQUIRE_DENYLIST:-0}" == 1 ]]; then
    fail "personal denylist not found at $DENYLIST (REQUIRE_DENYLIST=1)"
  else
    warn "gate: personal denylist not found ($DENYLIST) — only generic checks ran"
  fi
  rm -f "$files"
}

scan_tree() { scan_files < <(git ls-files -z -co --exclude-standard); gitleaks_dir "$ROOT"; }

gitleaks_dir() {
  command -v gitleaks >/dev/null 2>&1 || { warn "gate: gitleaks not installed — secret scan skipped"; return 0; }
  gitleaks dir "$1" --redact --no-banner --exit-code 1 >/dev/null 2>&1 || fail "gitleaks found secret(s) in $1 (run: gitleaks dir . --redact)"
}

scan_staged() {
  local tmp; tmp="$(mktemp -d)"
  git checkout-index -a --prefix="$tmp/"
  pushd "$tmp" >/dev/null
  scan_files < <(git -C "$ROOT" diff --cached --name-only -z --diff-filter=ACMR)
  popd >/dev/null
  gitleaks_dir "$tmp"
  rm -rf "$tmp"
  check_local_identity
}

scan_history() {
  git rev-parse --verify -q HEAD >/dev/null || return 0
  local tmp; tmp="$(mktemp)"
  git log --all -p --format= -U0 | grep -E '^\+' | grep -vE '^\+\+\+' | grep -v 'gate:allow' > "$tmp" || true
  local entry label re
  for entry in "${GENERIC[@]}"; do
    label="${entry%%$'\t'*}"; re="${entry#*$'\t'}"
    if rg -q -P -e "$re" "$tmp"; then fail "[$label] present in git history (rewrite before publishing)"; fi
  done
  if [[ -r "$DENYLIST" ]]; then
    local alt; alt="$(grep -Ev '^[[:space:]]*(#|$)' "$DENYLIST" | paste -sd '|' -)"
    [[ -z "$alt" ]] || { rg -q -i -e "$alt" "$tmp" && fail "[personal-denylist] present in git history"; } || true
  fi
  rm -f "$tmp"
  if command -v gitleaks >/dev/null 2>&1; then
    gitleaks git . --redact --no-banner --exit-code 1 >/dev/null 2>&1 || fail "gitleaks found secret(s) in git history"
  fi
}

check_local_identity() {
  local e; e="$(git config --get user.email || true)"
  [[ "$e" =~ $NOREPLY_RE ]] || fail "git user.email is not a GitHub noreply address (set it with: git config user.email <id>+<login>@users.noreply.github.com)"
}

check_identity() {
  check_local_identity
  git rev-parse --verify -q HEAD >/dev/null || return 0
  local bad; bad="$(git log --all --format='%ae%n%ce' | sort -u | grep -Ev "$NOREPLY_RE" || true)"
  [[ -z "$bad" ]] || fail "commit author/committer email(s) are not noreply addresses ($(printf '%s\n' "$bad" | wc -l | tr -d ' ') distinct) — rewrite before publishing"
}

case "${1:-}" in
  --staged)   scan_staged ;;
  --tree)     scan_tree ;;
  --history)  scan_history ;;
  --identity) check_identity ;;
  --all)      scan_tree; scan_history; check_identity ;;
  *) echo "usage: $0 --staged|--tree|--history|--identity|--all" >&2; exit 2 ;;
esac

if (( fails > 0 )); then red "gate: $fails check(s) failed — nothing may be published."; exit 1; fi
echo "gate: ok ($1)"
