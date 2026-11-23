# ============================================================
# ALIASES — PowerShell port of the portable parts of ~/.zsh/{common,docker}.zsh
# ============================================================
# Functions (not Set-Alias) so arguments can be bound. Names that collide with
# built-in PowerShell aliases (r, h, md, cls, ls, cat, cp, mv, rm, type, where)
# are deliberately skipped: aliases outrank functions, so they would be ignored.

# --- navigation --------------------------------------------------------------
function ..    { Set-Location .. }
function ...   { Set-Location ../.. }
function ....  { Set-Location ../../.. }
function dl    { Set-Location (Join-Path $HOME 'Downloads') }
function x     { Clear-Host }
function c     { claude @args }

# --- docker ------------------------------------------------------------------
function d      { docker @args }
function dc     { docker-compose @args }
function dup    { docker-compose up -d @args }
function db     { docker-compose up --build -d @args }
function ddown  { docker-compose down @args }
function dstop  { docker-compose stop @args }
function dps    { docker ps @args }
function dpsa   { docker ps -a @args }
function dlogs  { docker logs -f @args }

# --- ssh hosts: live in the private overlay (personal.ps1) -------------------

# --- eza (only if installed) -------------------------------------------------
if (Test-Cmd eza) {
    function tree  { eza --tree @args }
    function treel { eza --tree --long @args }
}

# --- edit shortcuts (use $env:EDITOR set in profile.ps1) ---------------------
function Edit-File([string]$Path) {
    $ed = if ($env:EDITOR) { $env:EDITOR } else { 'notepad' }   # no `??`: must parse on PS 5.1
    & $ed $Path
}
function etmux { Edit-File (Join-Path $HOME '.tmux.conf') }
function evi   { Edit-File (Join-Path $HOME '.config/nvim/init.lua') }
function eyy   { Edit-File (Join-Path $HOME '.config/yazi/yazi.toml') }
function essh  { Edit-File (Join-Path $HOME '.ssh/config') }
function ecc   { Edit-File (Join-Path $HOME '.claude/settings.json') }
function ep    { Edit-File $PROFILE.CurrentUserAllHosts }

# --- reload tmux conf (psmux) ------------------------------------------------
function rt { psmux source-file (Join-Path $HOME '.tmux.conf') @args }
