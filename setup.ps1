# =============================================================================
# Windows bootstrap wrapper — every question up front, then unattended.
#
# On a fresh PC:
#   winget install twpayne.chezmoi          # then open a NEW shell
#   chezmoi init Troublesis/dotfiles-public # clone over HTTPS (public repo, no login)
#   & "$(chezmoi source-path)\setup.ps1"    # this script
# (running this script directly also works: it clones if needed.)
#
# Secrets come from Bitwarden (bw CLI) when it is installed and unlocked; otherwise they are
# skipped and everything else still applies. Order:
#   1. execution policy + chezmoi            (no questions)
#   2. chezmoi init  -> clone + config questions: is_home, SSH sync, SSH key
#                       email, enable sshd         (all questions, no install yet)
#   3. (no key prompt; Bitwarden is optional, see README)
#   4. chezmoi apply                         (fully unattended from here)
#
# Tip: run from an *Administrator* PowerShell to avoid the one UAC prompt the
# bootstrap otherwise raises when it enables sshd.
#
# Windows PowerShell 5.1 compatible (no `??`, no `?.`).
# =============================================================================
param([string]$Repo = 'Troublesis/dotfiles-public')

$ErrorActionPreference = 'Stop'
function Log-Info { param([string]$m) Write-Host "[INFO] $m" }
function Log-Ok   { param([string]$m) Write-Host "[OK]   $m" }
function Log-Warn { param([string]$m) Write-Warning $m }


# --- 1. Execution policy + chezmoi ------------------------------------------
if ((Get-ExecutionPolicy -Scope CurrentUser) -in 'Undefined', 'Restricted') {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Log-Ok 'ExecutionPolicy (CurrentUser) = RemoteSigned'
}

function Update-SessionPath {
    $env:Path = (@([Environment]::GetEnvironmentVariable('Path', 'Machine'),
                   [Environment]::GetEnvironmentVariable('Path', 'User')) | Where-Object { $_ }) -join ';'
}

if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    Log-Info 'Installing chezmoi via winget'
    winget install --id twpayne.chezmoi --source winget --accept-package-agreements --accept-source-agreements
    Update-SessionPath
    if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
        throw 'chezmoi not on PATH after install - open a new shell and re-run setup.ps1'
    }
}
Log-Ok "chezmoi $(chezmoi --version)"

# --- 2. chezmoi init: clone + ALL config questions (no install yet) -----------
# Re-running is safe: promptBoolOnce/promptStringOnce keep existing answers.
Log-Info 'chezmoi init (answer the config questions)'
chezmoi init $Repo
if ($LASTEXITCODE -ne 0) { throw "chezmoi init failed (exit $LASTEXITCODE)" }

# --- 2b. Secrets --------------------------------------------------------------
# No key prompt any more. If `bw` is installed and BW_SESSION is set, secret-backed files are
# filled from the vault; otherwise they are skipped (fill them by hand later).
if (-not (Get-Command bw -ErrorAction SilentlyContinue)) {
    Log-Warn 'Bitwarden CLI (bw) not found - secret-backed files will be skipped. See README: Bitwarden secrets.'
} elseif (-not $env:BW_SESSION) {
    Log-Warn 'BW_SESSION not set - secret-backed files will be skipped. Run: $env:BW_SESSION = (bw unlock --raw)'
}

# --- 3. chezmoi apply (no more questions) -----------------------------------
Log-Info 'chezmoi apply - unattended from here'
chezmoi apply
exit $LASTEXITCODE
