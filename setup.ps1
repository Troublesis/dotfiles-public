# =============================================================================
# Windows bootstrap wrapper — every question up front, then unattended.
#
# On a fresh PC:
#   winget install twpayne.chezmoi          # then open a NEW shell
#   chezmoi init Troublesis/dotfiles-public # clone over HTTPS (public repo, no login)
#   & "$(chezmoi source-path)\setup.ps1"    # this script
# (running this script directly also works: it clones if needed.)
#
# Order matters: the age key must exist BEFORE `chezmoi apply` starts, because
# .chezmoiignore decides at the start of apply whether encrypted files are
# skipped. So:
#   1. execution policy + chezmoi            (no questions)
#   2. chezmoi init  -> clone + config questions: is_home, SSH sync, SSH key
#                       email, enable sshd         (all questions, no install yet)
#   3. age key                               (last question)
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

$keyFile = Join-Path $HOME '.config\chezmoi\key.txt'

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

# --- 2b. Age key ---------------------------------------------------------------
# Accepts the AGE-SECRET-KEY-1... line pasted (input hidden), or a path to an
# existing key.txt. Enter skips: encrypted files (secrets, tokens) are then
# skipped until you add the key and run `chezmoi apply`.
function Read-AgeKey {
    $secret = Read-Host 'Age key: paste the AGE-SECRET-KEY-1... line, or a path to key.txt (Enter to skip)' -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr).Trim().Trim('"') }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Save-AgeKey([string]$Value) {
    New-Item -ItemType Directory -Force -Path (Split-Path $keyFile) | Out-Null
    if (Test-Path -LiteralPath $Value -PathType Leaf) {
        Copy-Item -LiteralPath $Value -Destination $keyFile -Force
    } else {
        [IO.File]::WriteAllText($keyFile, "$Value`n", (New-Object Text.UTF8Encoding($false)))
    }
    # Private to the current user, like chmod 600.
    icacls $keyFile /inheritance:r /grant:r "$($env:USERNAME):(R,W)" | Out-Null
}

if (Test-Path -LiteralPath $keyFile) {
    Log-Ok "Age key present: $keyFile"
} elseif ([Console]::IsInputRedirected) {
    Log-Warn 'No interactive input - skipping age key prompt (encrypted files will be skipped).'
} else {
    for ($try = 1; $try -le 3; $try++) {
        $v = Read-AgeKey
        if (-not $v) { Log-Warn 'Age key skipped - encrypted files will be skipped.'; break }
        if ((Test-Path -LiteralPath $v -PathType Leaf) -or $v -match '^AGE-SECRET-KEY-1[A-Z0-9]+$') {
            Save-AgeKey $v
            Log-Ok "Age key saved: $keyFile"
            break
        }
        Log-Warn 'Not a valid AGE-SECRET-KEY-1... line or existing file path. Try again.'
        if ($try -eq 3) { Log-Warn 'Giving up on the age key - encrypted files will be skipped.' }
    }
}

# --- 3. chezmoi apply (no more questions) -----------------------------------
Log-Info 'chezmoi apply - unattended from here'
chezmoi apply
exit $LASTEXITCODE
