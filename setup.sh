#!/bin/bash
# Resilient chezmoi bootstrap — continues past failures and summarizes at the end.
# Usage: bash setup.sh [git-repo-url]
#
# When age key is missing, encrypted files are skipped but all other setup
# (packages, dev tools, shell config) still completes.

set -uo pipefail

REPO="${1:-https://github.com/Troublesis/dotfiles-public.git}"
CHEZMOI_SRC="$HOME/.local/share/chezmoi"
CONFIG_FILE="$HOME/.config/chezmoi/chezmoi.toml"
KEY_FILE="$HOME/.config/chezmoi/key.txt"
BOOTSTRAP_STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi-bootstrap"
OPTIONAL_PKG_FILE="$BOOTSTRAP_STATE_DIR/optional-packages.list"
FAILURES=()
STEP_COUNT=0
apply_rc=0

# ── Helpers ──────────────────────────────────────────────────────────────────
log_info()  { printf "\033[34m[INFO]\033[0m  %s\n" "$*"; }
log_ok()    { printf "\033[32m[OK]\033[0m    %s\n" "$*"; }
log_warn()  { printf "\033[33m[WARN]\033[0m  %s\n" "$*"; }
log_fail()  { printf "\033[31m[FAIL]\033[0m  %s\n" "$*"; FAILURES+=("$1"); }

run_step() {
  local label="$1"
  shift
  STEP_COUNT=$((STEP_COUNT + 1))
  log_info "[$STEP_COUNT] $label"
  local output rc=0
  output=$("$@" 2>&1) || rc=$?
  if [ "$rc" -eq 0 ]; then
    log_ok "$label"
  else
    log_fail "$label (exit $rc)"
    if [ -n "$output" ]; then
      echo "$output" | tail -5 | sed 's/^/    /'
    fi
  fi
}

summary() {
  echo ""
  echo "══════════════════════════════════════════════════════════════"
  if [ ${#FAILURES[@]} -eq 0 ]; then
    log_ok "Setup complete — all steps succeeded."
  else
    log_warn "Setup complete with ${#FAILURES[@]} failure(s):"
    for f in "${FAILURES[@]}"; do
      echo "  ✗ $f"
    done
    echo ""
    echo "Remediation:"
    if [ ! -f "$KEY_FILE" ]; then
      echo "  → Age key missing — encrypted files (SSH keys, secrets) were skipped."
      echo "    Fix: copy key.txt from another host, then run 'chezmoi apply'."
    fi
    echo "  → Re-run this script to retry failed steps (idempotent)."
  fi

  # Next-steps block — printed regardless of failure count so the user
  # always knows how to enter zsh and (if applicable) drop in the age key.
  echo ""
  echo "Next steps:"
  local zsh_bin login_shell
  zsh_bin="$(command -v zsh 2>/dev/null || echo zsh)"
  login_shell="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)"
  [ -z "$login_shell" ] && login_shell="${SHELL:-}"
  if [ "$(basename "${login_shell:-}")" != "zsh" ]; then
    echo "  → Login shell is not zsh yet. To switch this session immediately:"
    echo "      exec $zsh_bin -l"
    echo "  → To make it permanent (if chsh didn't already take effect):"
    echo "      chsh -s \"$zsh_bin\""
    echo "    (the bootstrap also drops a zsh-handoff into ~/.bash_profile as"
    echo "     a fallback, so a new bash login will exec zsh automatically)"
  else
    echo "  → Default shell is already zsh. Open a new terminal to confirm."
  fi
  if [ ! -f "$KEY_FILE" ]; then
    echo "  → Only if you use a private overlay: copy its age key, then re-apply to install its encrypted files:"
    echo "      mkdir -p ~/.config/chezmoi && chmod 700 ~/.config/chezmoi"
    echo "      scp other-host:~/.config/chezmoi/key.txt ~/.config/chezmoi/key.txt"
    echo "      chmod 600 ~/.config/chezmoi/key.txt && chezmoi apply"
  fi
  echo "══════════════════════════════════════════════════════════════"
}

trap summary EXIT

# ── Optional-package picker (typed number ranges) ────────────────────────────
# Catalog: "pkgname|binname|description". pkgname is passed to the package
# manager / fallback table; binname is what `command -v` checks.
OPTIONAL_PACKAGES_CATALOG=(
  "btop|btop|Resource monitor (CPU/mem/network/disk)"
  "gh|gh|GitHub CLI"
  "lazygit|lazygit|Git TUI"
  "htop|htop|Interactive process viewer"
  "ncdu|ncdu|Disk usage analyzer (NCurses)"
  "tldr|tldr|Simplified, community-driven man pages"
  "neovim|nvim|Modern Vim"
  "httpie|http|Human-friendly HTTP CLI"
  "dust|dust|Modern du, written in Rust"
  "procs|procs|Modern ps replacement"
)

# parse_index_spec RAW COUNT
#   Echoes one 1-based index per line for selections like
#     "1 2 4" / "1,3,5" / "1-5" / "1-3,5 7" / "all" / "" (none)
#   Out-of-range / non-numeric tokens go to stderr and are skipped.
parse_index_spec() {
  local raw="$1" count="$2"
  local lower
  lower="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ')"
  lower="${lower# }"; lower="${lower% }"

  case "$lower" in
    ''|none|n|no|skip|0)
      return 0
      ;;
    all|a|'*')
      local i
      for ((i = 1; i <= count; i++)); do echo "$i"; done
      return 0
      ;;
  esac

  # Replace commas with spaces, collapse whitespace, then tokenise.
  local norm
  norm=$(printf '%s' "$raw" | tr ',' ' ' | tr -s '[:space:]' ' ')
  norm="${norm# }"; norm="${norm% }"

  local tok lo hi i swap
  for tok in $norm; do
    if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      lo=${BASH_REMATCH[1]}; hi=${BASH_REMATCH[2]}
      if (( lo > hi )); then swap=$lo; lo=$hi; hi=$swap; fi
      for ((i = lo; i <= hi; i++)); do
        if (( i >= 1 && i <= count )); then
          echo "$i"
        else
          printf '  ⚠ ignoring out-of-range: %d\n' "$i" >&2
        fi
      done
    elif [[ "$tok" =~ ^[0-9]+$ ]]; then
      i=$tok
      if (( i >= 1 && i <= count )); then
        echo "$i"
      else
        printf '  ⚠ ignoring out-of-range: %d\n' "$i" >&2
      fi
    else
      printf '  ⚠ ignoring invalid token: %q\n' "$tok" >&2
    fi
  done
}

# write_optional_pkg_list PAIR1 PAIR2 ...
#   Each pair is "pkgname:binname". Writes $OPTIONAL_PKG_FILE.
write_optional_pkg_list() {
  mkdir -p "$BOOTSTRAP_STATE_DIR"
  {
    echo "# Optional packages selected during setup.sh — one per line."
    echo "# Format: <pkgname> [binname]"
    echo "# Consumed by run_once_before_10-install-packages-linux.sh.tmpl"
    local item name bin
    for item in "$@"; do
      name="${item%%:*}"
      bin="${item##*:}"
      [[ -z "$name" ]] && continue
      if [[ "$name" == "$bin" ]]; then
        echo "$name"
      else
        echo "$name $bin"
      fi
    done
  } > "$OPTIONAL_PKG_FILE"
  log_ok "Wrote $OPTIONAL_PKG_FILE"
}

# resolve_names_to_pairs NAME1 NAME2 ...
#   Looks up bin for each pkg name. Unknown names pass through with bin == name.
resolve_names_to_pairs() {
  local name entry pkg bin desc found
  for name in "$@"; do
    found=0
    for entry in "${OPTIONAL_PACKAGES_CATALOG[@]}"; do
      IFS='|' read -r pkg bin desc <<<"$entry"
      if [[ "$pkg" == "$name" ]]; then
        printf '%s:%s\n' "$pkg" "$bin"
        found=1
        break
      fi
    done
    if (( found == 0 )); then
      log_warn "Unknown optional package: $name (treating as bin == name)"
      printf '%s:%s\n' "$name" "$name"
    fi
  done
}

pick_optional_packages() {
  # Idempotent: skip if list already written and not reconfiguring.
  if [[ -f "$OPTIONAL_PKG_FILE" && "${RECONFIGURE:-0}" != "1" ]]; then
    log_info "Optional package list already exists ($OPTIONAL_PKG_FILE)"
    log_info "  → set RECONFIGURE=1 to re-pick"
    return 0
  fi

  # Non-interactive: honour CHEZMOI_OPTIONAL_PACKAGES env var (space-separated).
  if [[ "${NONINTERACTIVE:-0}" == "1" || "${CI:-0}" == "1" || ! -t 0 ]]; then
    local pairs=() line
    if [[ -n "${CHEZMOI_OPTIONAL_PACKAGES:-}" ]]; then
      # shellcheck disable=SC2086
      while IFS= read -r line; do
        [[ -n "$line" ]] && pairs+=("$line")
      done < <(resolve_names_to_pairs $CHEZMOI_OPTIONAL_PACKAGES)
    fi
    if (( ${#pairs[@]} == 0 )); then
      log_info "Non-interactive — no optional packages (set CHEZMOI_OPTIONAL_PACKAGES to choose)"
      write_optional_pkg_list
    else
      local names=()
      local p
      for p in "${pairs[@]}"; do names+=("${p%%:*}"); done
      log_info "Non-interactive — optional packages: ${names[*]}"
      write_optional_pkg_list "${pairs[@]}"
    fi
    return 0
  fi

  echo ""
  echo "══════════════════════════════════════════════════════════════"
  printf "\033[1m  Optional packages\033[0m\n"
  echo "══════════════════════════════════════════════════════════════"

  local count=${#OPTIONAL_PACKAGES_CATALOG[@]} i=0
  local entry pkg bin desc
  for entry in "${OPTIONAL_PACKAGES_CATALOG[@]}"; do
    IFS='|' read -r pkg bin desc <<<"$entry"
    i=$((i + 1))
    printf "  %2d) %-10s %s\n" "$i" "$pkg" "$desc"
  done

  echo ""
  echo "Enter numbers to install. Examples:"
  echo "    1 2 4        items 1, 2, 4"
  echo "    1,3,5        commas work too"
  echo "    1-5          range 1 through 5"
  echo "    1-3,5 7      mix and match"
  echo "    all          install everything"
  echo "    (empty)      install nothing"
  echo ""

  local raw=""
  read -r -p "Selection: " raw || raw=""

  # Parse → unique sorted indices.
  local warnings_file
  warnings_file=$(mktemp 2>/dev/null || echo "/tmp/.optpkg_warnings.$$")
  local sorted
  sorted=$(parse_index_spec "$raw" "$count" 2>"$warnings_file" | sort -un)
  if [[ -s "$warnings_file" ]]; then cat "$warnings_file"; fi
  rm -f "$warnings_file"

  local -a sel=()
  if [[ -n "$sorted" ]]; then
    while IFS= read -r line; do sel+=("$line"); done <<<"$sorted"
  fi

  local -a pairs=()
  local n
  if (( ${#sel[@]} > 0 )); then
    for n in "${sel[@]}"; do
      IFS='|' read -r pkg bin desc <<<"${OPTIONAL_PACKAGES_CATALOG[n-1]}"
      pairs+=("$pkg:$bin")
    done
  fi

  if (( ${#pairs[@]} == 0 )); then
    printf "  → \033[2m(no optional packages selected)\033[0m\n"
    write_optional_pkg_list
  else
    local names=()
    local p
    for p in "${pairs[@]}"; do names+=("${p%%:*}"); done
    printf "  → installing: \033[36m%s\033[0m\n" "${names[*]}"
    write_optional_pkg_list "${pairs[@]}"
  fi
}

pick_optional_packages

# ── Step 1: Install chezmoi if missing ───────────────────────────────────────
if ! command -v chezmoi >/dev/null 2>&1; then
  log_info "chezmoi not found — installing..."
  if command -v brew >/dev/null 2>&1; then
    run_step "Install chezmoi (brew)" brew install chezmoi
  elif command -v apt-get >/dev/null 2>&1; then
    run_step "Install chezmoi (apt)" sudo apt-get install -y chezmoi
  else
    run_step "Install chezmoi (script)" sh -c "$(curl -fsSL get.chezmoi.io)"
  fi
fi

command -v chezmoi >/dev/null 2>&1 || { log_fail "chezmoi not available — cannot continue"; exit 1; }

# ── Step 2: Initialize chezmoi (clone repo + generate config) ────────────────
if [ ! -d "$CHEZMOI_SRC/.git" ]; then
  # chezmoi init --apply clones, renders config template, and applies.
  # It may fail on encrypted files if key.txt is missing — that's OK.
  log_info "Initializing chezmoi from $REPO..."
  init_output="" init_rc=0
  init_output=$(chezmoi init --apply "$REPO" 2>&1) || init_rc=$?

  if [ "$init_rc" -eq 0 ]; then
    log_ok "chezmoi init --apply — full setup succeeded"
  elif [ ! -f "$CONFIG_FILE" ]; then
    # Config wasn't generated — try init without --apply, then apply separately
    log_warn "chezmoi init --apply failed before generating config"
    run_step "chezmoi init (clone only)" chezmoi init "$REPO"
  else
    # Config exists but apply had errors (likely encrypted files)
    encrypted_fails=$(echo "$init_output" | grep -ci "age\|decrypt\|key.txt" || true)
    if [ "$encrypted_fails" -gt 0 ]; then
      log_warn "chezmoi init — encrypted files skipped (age key missing at $KEY_FILE)"
    else
      log_fail "chezmoi init --apply"
      echo "$init_output" | tail -10 | sed 's/^/    /'
    fi
  fi
fi

[ -d "$CHEZMOI_SRC/.git" ] || { log_fail "chezmoi source not cloned — cannot continue"; exit 1; }

# ── Step 3: Apply dotfiles (retry if init didn't fully apply) ────────────────
if [ -f "$CONFIG_FILE" ]; then
  log_info "Applying remaining dotfiles..."
  apply_output="" apply_rc=0
  apply_output=$(chezmoi apply --force 2>&1) || apply_rc=$?

  if [ "$apply_rc" -eq 0 ]; then
    log_ok "chezmoi apply — all files applied"
  else
    encrypted_fails=$(echo "$apply_output" | grep -ci "age\|decrypt\|key.txt" || true)
    if [ "$encrypted_fails" -gt 0 ]; then
      log_warn "chezmoi apply — encrypted files skipped (no age key)"
    else
      log_fail "chezmoi apply"
      echo "$apply_output" | tail -10 | sed 's/^/    /'
    fi
  fi
else
  log_warn "Config not generated — skipping chezmoi apply"
  log_warn "Run 'chezmoi init --apply $REPO' manually after creating $CONFIG_FILE"
fi

# ── Step 4: Run bootstrap scripts ────────────────────────────────────────────
# .sh scripts (non-template) execute directly.
# .sh.tmpl scripts need chezmoi rendering — if apply succeeded they already ran;
# if apply failed, we render and execute them here as a fallback.
apply_succeeded=false
[ "$apply_rc" -eq 0 ] && apply_succeeded=true

for script in "$CHEZMOI_SRC"/run_once_*.sh; do
  [ -f "$script" ] || continue
  [[ "$script" == *.tmpl ]] && continue

  script_name="$(basename "$script")"
  run_step "Bootstrap: $script_name" bash "$script"
done

if [ "$apply_succeeded" = false ]; then
  for script_tmpl in "$CHEZMOI_SRC"/run_once_*.sh.tmpl; do
    [ -f "$script_tmpl" ] || continue
    script_name="$(basename "$script_tmpl" .tmpl)"

    # Render the template and execute — skip the shebang line for piping
    log_info "Rendering + running template: $script_name"
    rendered="" render_rc=0
    rendered=$(chezmoi execute-template -f "$script_tmpl" 2>&1) || render_rc=$?

    if [ "$render_rc" -ne 0 ]; then
      log_fail "Render template: $script_name"
      continue
    fi

    # Filter out empty conditional blocks (templates that render to nothing for this OS/host)
    if [ -z "$(echo "$rendered" | tr -d '[:space:]')" ]; then
      log_info "Skipping $script_name (not applicable to this OS/host)"
      continue
    fi

    STEP_COUNT=$((STEP_COUNT + 1))
    log_info "[$STEP_COUNT] Bootstrap: $script_name"
    exec_rc=0
    echo "$rendered" | bash 2>&1 || exec_rc=$?
    if [ "$exec_rc" -eq 0 ]; then
      log_ok "Bootstrap: $script_name"
    else
      log_fail "Bootstrap: $script_name (exit $exec_rc)"
    fi
  done
fi

# ── Step 5: Verify core tools ────────────────────────────────────────────────
echo ""
log_info "Tool verification:"
for cmd in zsh git chezmoi; do
  if command -v "$cmd" >/dev/null 2>&1; then
    log_ok "$cmd ✓"
  else
    log_fail "$cmd not found"
  fi
done

for cmd in nvim tmux fzf rg; do
  if command -v "$cmd" >/dev/null 2>&1; then
    log_ok "$cmd ✓"
  else
    log_warn "$cmd not found (optional)"
  fi
done
