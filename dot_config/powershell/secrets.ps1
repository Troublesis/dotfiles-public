# ============================================================
# SECRETS LOADER — PowerShell port of ~/.zshrc's `source ~/.zsh_secrets`
# ============================================================
#
# chezmoi age-decrypts encrypted_private_dot_zsh_secrets.tmpl.age to
# ~/.zsh_secrets on every host (when the age key is present), so the SAME
# file already holds the AI launcher credentials (_LOCAL_AI_*, _ZAI_*, etc.)
# used by ai.zsh on macOS/Linux. This loader parses that shell-syntax file
# into PowerShell process env vars so ai.ps1 can read them.
#
# Dot-source from the PowerShell profile BEFORE ai.ps1:
#   . "$HOME\.config\powershell\secrets.ps1"

$secretsFile = Join-Path $HOME ".zsh_secrets"
if (-not (Test-Path $secretsFile)) { return }

# Match: export KEY="VALUE" | export KEY='VALUE' | export KEY=VALUE
# Captures KEY and VALUE (without quotes). Skips comments (#) and blanks.
$pattern = '^\s*export\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*["'']?(.*?)["'']?\s*$'

Get-Content -Path $secretsFile | ForEach-Object {
    if ($_ -match $pattern) {
        $key = $matches[1]
        $val = $matches[2]
        # Process scope so child claude.exe inherits them this session.
        [Environment]::SetEnvironmentVariable($key, $val, "Process")
    }
}
