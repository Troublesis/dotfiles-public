# ============================================================
# PowerShell profile (AllHosts) — loaded by pwsh 7 AND Windows PowerShell 5.1
# for the current user in every host (console, ISE, psmux panes, nested shells).
# ============================================================
# Managed by chezmoi; deployed to ~/.config/powershell/profile.ps1 and loaded via a
# stub written by run_onchange_42-powershell-profile.ps1.tmpl (OneDrive-safe).
#
# Why AllHosts (profile.ps1) instead of CurrentUserCurrentHost
# (Microsoft.PowerShell_profile.ps1): AllHosts loads in *every* PowerShell host
# for the user, so psmux panes, `chezmoi cd` nested shells, `pwsh -Login`, and
# non-interactive dispatch all pick up starship + the managed snippets. The
# host-specific profile is intentionally left unmanaged.
#
# Sourcing order is load-bearing and mirrors run_once_40-windows-setup.ps1.tmpl:
#   secrets.ps1  →  ai.ps1  →  chezmoi.ps1  →  starship  →  vi/vim aliases
# ~/.zsh_secrets MUST load before ai.ps1 (token expansion); secrets.ps1 handles
# that. Each source is guarded so a missing file never breaks shell startup.

$cfgDir = Join-Path $HOME ".config\powershell"

# --- Fast command lookup ------------------------------------------------------
# Get-Command takes ~150ms per *missing* command (scans every PATH entry). A plain
# file-exists scan over PATH is ~1ms.
$script:pathDirs = $env:PATH -split ';' | Where-Object { $_ -and [IO.Directory]::Exists($_) }
function Test-Cmd([string]$Name) {
    foreach ($d in $script:pathDirs) {
        foreach ($e in '.exe', '.cmd', '.bat', '.ps1') {
            if ([IO.File]::Exists("$d\$Name$e")) { return $true }
        }
    }
    $false
}

# --- Secrets loader (~/.zsh_secrets → process env vars) ----------------------
$secrets = Join-Path $cfgDir "secrets.ps1"
if (Test-Path -LiteralPath $secrets) { . $secrets }

# --- Claude Code AI launchers (functions: cc, glm, ds, zai, grok, gpt, cg) ----
$ai = Join-Path $cfgDir "ai.ps1"
if (Test-Path -LiteralPath $ai) { . $ai }

# --- opencommit (OCO_* env, mirrors ai.zsh) ------------------------------------
$oco = Join-Path $cfgDir "oco.ps1"
if (Test-Path -LiteralPath $oco) { . $oco }

# --- chezmoi aliases (cz, cza, czd, cze, czs, czu, czp, czr, eb) -------------
$cz = Join-Path $cfgDir "chezmoi.ps1"
if (Test-Path -LiteralPath $cz) { . $cz }

# --- zsh alias ports (docker, nav, ssh hosts, edit shortcuts) ----------------
$al = Join-Path $cfgDir "aliases.ps1"
if (Test-Path -LiteralPath $al) { . $al }

# --- private overlay aliases (hosts etc.) — absent on a public-only machine ---
$pa = Join-Path $cfgDir "personal.ps1"
if (Test-Path -LiteralPath $pa) { . $pa }

# --- psmux wrapper (p: session picker + passthrough, ported from zsh `t`) ----
$p = Join-Path $cfgDir "psmux.ps1"
if (Test-Path -LiteralPath $p) { . $p }

# --- herdr (t: attach/restore the persistent session; psmux's picker is `p`) --
$hd = Join-Path $cfgDir "herdr.ps1"
if (Test-Path -LiteralPath $hd) { . $hd }

# --- PSReadLine (prediction, tab menu) --------------------------------------
$psrl = Join-Path $cfgDir "psreadline.ps1"
if (Test-Path -LiteralPath $psrl) { . $psrl }

# --- Starship prompt ---------------------------------------------------------
# Guard: (1) starship on PATH, (2) interactive session. psmux may spawn panes
# that run non-interactive dispatch (e.g. `pwsh -NoLogo -c ...`); init emits a
# PROMPT override that breaks non-interactive output, so skip it there.
# STARSHIP_CONFIG is unset → starship defaults to ~/.config/starship.toml
# (rendered by chezmoi from executable_starship.toml.tmpl), so no env var is needed.
if ((Test-Cmd starship) -and
    ($host.Name -ne 'Default Host' -and $host.UI -and $host.UI.RawUI)) {
    if (-not [Console]::IsOutputRedirected) {
        Invoke-Expression (& starship init powershell)
    }
}

# --- vi/vim → nvim if installed, else vim (Git's vim.exe / Vim on PATH) ------
$editor = if (Test-Cmd nvim) { 'nvim' }
          elseif (Test-Cmd vim) { 'vim' }
if ($editor) {
    $env:EDITOR = $editor; $env:VISUAL = $editor
    Set-Item -Path Function:global:vi -Value ([scriptblock]::Create("$editor @args"))
    if ($editor -eq 'nvim') { Set-Item -Path Function:global:vim -Value { nvim @args } }
}

# --- misc aliases ------------------------------------------------------------

# --- herdr auto-attach: MUST stay last (blocks while herdr is open) ----------
if (Get-Command Invoke-HerdrAutoAttach -ErrorAction SilentlyContinue) { Invoke-HerdrAutoAttach }
