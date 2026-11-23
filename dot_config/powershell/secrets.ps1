# ============================================================
# SECRETS LOADER — PowerShell port of ~/.zshrc's `source ~/.zsh_secrets`
# ============================================================
#
# ~/.zsh_secrets (shell syntax: export NAME="value") holds the AI launcher
# credentials (_LOCAL_AI_*, _ZAI_*, OCO_*, etc.) used by ai.zsh on macOS/Linux.
# chezmoi creates it once as an empty template; you fill in the values by hand.
# This loader parses that file into PowerShell process env vars so ai.ps1 and
# oco.ps1 can read them.
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
