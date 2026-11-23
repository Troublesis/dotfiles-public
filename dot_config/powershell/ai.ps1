# ============================================================
# AI LAUNCHER SHORTCUTS — Claude Code variants
# ============================================================
#
# Windows / PowerShell port of ~/.zsh/ai.zsh. Each function wraps the
# `claude` CLI with provider-specific model + endpoint env vars, then
# dispatches. Dot-source from the PowerShell profile AFTER secrets.ps1:
#
#   . "$HOME\.config\powershell\secrets.ps1"   # loads ~/.zsh_secrets
#   . "$HOME\.config\powershell\ai.ps1"
#
# Credentials come from ~/.zsh_secrets (same file zsh uses), loaded into
# process env vars by secrets.ps1. Var names are the _-prefixed shell
# originals so the SAME secrets file works on both shells:
#   _LOCAL_AI_URL / _LOCAL_AI_TOKEN  (local proxy: grok, gpt, cg, glm, cc)
#   _ZAI_URL / _ZAI_TOKEN            (Z.AI)
#   _DS_TOKEN                        (DeepSeek; base URL is hardcoded)

# Credentials default to empty if secrets.ps1 didn't run / file missing,
# so launchers fail with a clear auth error instead of "variable not set".
function Set-AiEnv {
    param(
        [string]$Haiku, [string]$Sonnet, [string]$Opus,
        [string]$Url,   [string]$Token
    )
    $env:ANTHROPIC_DEFAULT_HAIKU_MODEL  = $Haiku
    $env:ANTHROPIC_DEFAULT_SONNET_MODEL = $Sonnet
    $env:ANTHROPIC_DEFAULT_OPUS_MODEL   = $Opus
    $env:ANTHROPIC_BASE_URL             = $Url
    $env:ANTHROPIC_AUTH_TOKEN           = $Token
    $env:API_TIMEOUT_MS                 = "3000000"
}

# Mirror ai.zsh: CODEX_APIKEY falls back to _LOCAL_AI_TOKEN when unset.
if (-not $env:CODEX_APIKEY) { $env:CODEX_APIKEY = $env:_LOCAL_AI_TOKEN }

# --- DeepSeek (base URL is hardcoded, no _DS_URL in secrets) ---
function ds {
    $env:ANTHROPIC_BASE_URL             = "https://api.deepseek.com/anthropic"
    $env:ANTHROPIC_AUTH_TOKEN           = $env:_DS_TOKEN
    $env:ANTHROPIC_MODEL                = "deepseek-v4-pro[1m]"
    $env:ANTHROPIC_DEFAULT_OPUS_MODEL   = "deepseek-v4-pro[1m]"
    $env:ANTHROPIC_DEFAULT_SONNET_MODEL = "deepseek-v4-pro[1m]"
    $env:ANTHROPIC_DEFAULT_HAIKU_MODEL  = "deepseek-v4-flash[1m]"
    $env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
    $env:CLAUDE_CODE_EFFORT_LEVEL      = "max"
    claude @args
}

# --- Z.AI ---
function zai { Set-AiEnv "glm-4.5-air" "glm-5.1" "glm-5.2" $env:_ZAI_URL $env:_ZAI_TOKEN; claude @args }

# --- Local proxy ---
function grok { Set-AiEnv "x-ai/grok-4.1-fast" "x-ai/grok-4.1-fast" "x-ai/grok-4.1-fast" $env:_LOCAL_AI_URL $env:_LOCAL_AI_TOKEN; claude @args }
function gpt  { Set-AiEnv "gpt-5.4-mini" "gpt-5.5" "gpt-5.5" $env:_LOCAL_AI_URL $env:_LOCAL_AI_TOKEN; claude @args }
function cg   { Set-AiEnv "gemini-2.5-flash" "gemini-3-pro-preview" "gemini-3-pro-preview" $env:_LOCAL_AI_URL $env:_LOCAL_AI_TOKEN; claude @args }
function glm  { Set-AiEnv "glm-4.5-air" "glm-5.1" "glm-5.2" $env:_LOCAL_AI_URL $env:_LOCAL_AI_TOKEN; claude @args }

# --- Claude (Anthropic via local proxy) ---
function cc {
    # No proxy configured (e.g. secrets not decrypted yet) -> plain claude
    if ($env:_LOCAL_AI_URL) { Set-AiEnv "claude-haiku-5-5" "claude-sonnet-5-5" "claude-opus-5-5" $env:_LOCAL_AI_URL $env:_LOCAL_AI_TOKEN }
    claude @args
}

$env:CLAUDE_CODE_NO_FLICKER = 1
