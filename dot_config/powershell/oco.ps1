# ============================================================
# OPENCOMMIT (oco) — PowerShell port of the `--- Opencommit (oco) ---` block in
# ~/.zsh/ai.zsh. Configured purely via OCO_* env vars (oco reads them before
# ~/.opencommit), so keys stay in ~/.zsh_secrets and never land in plaintext config.
# Dot-source AFTER secrets.ps1 (needs _LOCAL_AI_TOKEN). Set OCO_API_URL (your endpoint,
# e.g. https://<gateway>/v1) and optionally OCO_API_KEY in ~/.zsh_secrets.
# ============================================================
if (-not $env:OCO_API_KEY)     { $env:OCO_API_KEY     = $env:_LOCAL_AI_TOKEN }
if (-not $env:OCO_AI_PROVIDER) { $env:OCO_AI_PROVIDER = 'openai' }
if (-not $env:OCO_MODEL)       { $env:OCO_MODEL       = 'claude-haiku-5-5' }
if (-not $env:OCO_OMIT_SCOPE)  { $env:OCO_OMIT_SCOPE  = 'true' }
if (-not $env:OCO_GITPUSH)     { $env:OCO_GITPUSH     = 'false' }
