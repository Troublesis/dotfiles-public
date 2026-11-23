# ======================================================
# AI LAUNCHER CREDENTIALS & SHORTCUTS
# ======================================================
#
# --- Credentials (skip silently if secrets file missing) ---
# Variables are used unconditionally below; provide safe defaults to avoid
# "parameter not set" errors on first source or incomplete secrets file.
_LOCAL_AI_URL="${_LOCAL_AI_URL:-}"
_LOCAL_AI_TOKEN="${_LOCAL_AI_TOKEN:-}"
_ZAI_URL="${_ZAI_URL:-}"
_ZAI_TOKEN="${_ZAI_TOKEN:-}"
_DS_URL="${_DS_URL:-}"
_DS_TOKEN="${_DS_TOKEN:-}"


export CODEX_APIKEY="${CODEX_APIKEY:-$_LOCAL_AI_TOKEN}"

# --- Opencommit (oco) ---
# Configured entirely via env vars (oco reads OCO_* env before ~/.opencommit), so keys stay
# in ~/.zsh_secrets and never land in plaintext config. Set OCO_API_URL (your endpoint,
# e.g. https://<gateway>/v1) in ~/.zsh_secrets; the key defaults to the local-gateway token.
# An EMPTY exported OCO_API_KEY would override the key stored in ~/.opencommit, so only export it
# when there is a value (and drop an empty one).
if [[ -z "${OCO_API_KEY:-}" ]]; then
    if [[ -n "${_LOCAL_AI_TOKEN:-}" ]]; then export OCO_API_KEY="$_LOCAL_AI_TOKEN"; else unset OCO_API_KEY; fi
fi
export OCO_AI_PROVIDER="${OCO_AI_PROVIDER:-openai}"
export OCO_MODEL="${OCO_MODEL:-claude-haiku-5-5}"
export OCO_OMIT_SCOPE="${OCO_OMIT_SCOPE:-true}"   # "feat: x", not "feat(scope): x"
export OCO_GITPUSH="${OCO_GITPUSH:-false}"        # oco commits only; pushing stays explicit

# --- Dispatcher: ai_dispatch <haiku> <sonnet> <opus> <url> <token> <cmd> [args...] ---
ai_dispatch() {
    local haiku="$1" sonnet="$2" opus="$3" url="$4" token="$5" cmd="$6"
    shift 6
    if [[ -z "$cmd" ]] || ! command -v "$cmd" &>/dev/null; then
        echo "ai_dispatch: '${cmd:-<none>}' not found in PATH (bootstrap incomplete? check node/npm, then 'chezmoi apply')" >&2
        return 127
    fi
    if [[ -z "$url" || -z "$token" ]]; then
        echo "ai_dispatch: endpoint URL/token empty — set the matching _*_URL / _*_TOKEN variables in ~/.zsh_secrets" >&2
        return 1
    fi
    ANTHROPIC_DEFAULT_HAIKU_MODEL="$haiku" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="$sonnet" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="$opus" \
    ANTHROPIC_BASE_URL="$url" \
    ANTHROPIC_AUTH_TOKEN="$token" \
    API_TIMEOUT_MS="3000000" \
    "$cmd" "$@"
}

# --- DEEPSEEK ---
ds() {
    ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" \
    ANTHROPIC_AUTH_TOKEN="$_DS_TOKEN" \
    ANTHROPIC_MODEL="deepseek-v4-pro[1m]" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash[1m]" \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1" \
    CLAUDE_CODE_EFFORT_LEVEL="max" \
    claude "$@"
}

# --- Z.AI ---
zai()    { ai_dispatch "glm-4.5-air"      "glm-5.1"              "glm-5.2"                  "$_ZAI_URL"      "$_ZAI_TOKEN"      claude    "$@"; }

# --- Local proxy ---
grok()   { ai_dispatch "x-ai/grok-4.1-fast"    "x-ai/grok-4.1-fast"        "x-ai/grok-4.1-fast"            "$_LOCAL_AI_URL" "$_LOCAL_AI_TOKEN" claude    "$@"; }
gpt()    { ai_dispatch "gpt-5.4-mini"     "gpt-5.6-luna"              "gpt-5.6-terra"                  "$_LOCAL_AI_URL" "$_LOCAL_AI_TOKEN" claude    "$@"; }
cg() { ai_dispatch "gemini-2.5-flash" "gemini-3-pro-preview" "gemini-3-pro-preview"     "$_LOCAL_AI_URL" "$_LOCAL_AI_TOKEN" claude    "$@"; }
glm()     { ai_dispatch "glm-4.5-air" "glm-5.1"    "glm-5.2" "$_LOCAL_AI_URL" "$_LOCAL_AI_TOKEN" claude    "$@"; }

cc()     { ai_dispatch "claude-haiku-5-5"           "claude-sonnet-5-5"    "claude-opus-5-5" "$_LOCAL_AI_URL" "$_LOCAL_AI_TOKEN" claude    "$@"; }


export CLAUDE_CODE_NO_FLICKER=1

rx() {
  if command -v reasonix &>/dev/null; then
    reasonix "$@"
    return $?
  fi

  echo "reasonix not found, starting global installation..."
  if npm install -g reasonix; then
    echo "Installation completed successfully"
    reasonix "$@"
  else
    echo "Failed to install reasonix, please check npm network and permissions"
    return 1
  fi
}
