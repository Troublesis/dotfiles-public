# ============================================================
# HERDR — `t` opens herdr (the persistent agent multiplexer)
# ============================================================
#
# `t` is a plain alias for `herdr`, so every argument passes straight through
# (`t --session work`, `t session list`, `t server stop`, ...). It used to be the
# psmux session picker; that now lives under `p` (see psmux.ps1).
#
# A bare `herdr` means "launch or attach to the persistent session":
#   - server running  -> reattaches to the session exactly as you left it
#   - after a restart -> starts the server, restores the most recent saved layout
#                        (workspaces, tabs, panes, cwds) and, via [session]
#                        resume_agents_on_restore in config.toml (default true),
#                        resumes each AI-agent pane's last native conversation
#                        (e.g. Claude Code)
# So it already opens the most recent session by default; herdr has no separate
# "last session" flag or option (docs: herdr.dev/docs/session-state).
#
# Dot-source from the PowerShell profile alongside the other managed snippets:
#
#   . "$HOME\.config\powershell\herdr.ps1"
#
# No-op if herdr isn't on PATH (it is opt-in on Windows: INSTALL_HERDR=1), so
# profile startup stays safe on machines that don't have it installed.

if (-not (Test-Cmd herdr)) { return }

# On Windows herdr reads %APPDATA%\herdr\config.toml by default; point it at the
# chezmoi-managed ~/.config/herdr/config.toml so keybindings match the mac/tmux.
$env:HERDR_CONFIG_PATH = Join-Path $HOME ".config\herdr\config.toml"

Set-Alias -Name t -Value herdr

# ---------------------------------------------------------------------------
# Auto-attach: every new interactive terminal enters herdr (PowerShell port of
# ~/.zsh/tmux-auto.zsh). profile.ps1 calls this as its LAST line, so the outer
# shell is fully configured before herdr takes the screen.
#
# Opt out for one shell:   $env:NO_AUTO_HERDR=1; powershell     (or pwsh)
# Opt out permanently:     setx NO_AUTO_HERDR 1
#
# Skipped: non-interactive/redirected hosts, -Command/-File/-NonInteractive
# launches, already inside herdr or psmux, VS Code/Cursor/Zed/JetBrains
# terminals, and Claude Code / agent-run shells.
#
# herdr is NOT exec'd: if it fails you keep a usable shell, and after you
# detach or quit you land in this plain shell (close the tab yourself).
function Invoke-HerdrAutoAttach {
    if ($env:NO_AUTO_HERDR -or $env:HERDR_ENV -or $env:HERDR_PANE_ID -or $env:TMUX) { return }
    if ($env:CLAUDECODE -or $env:AI_AGENT) { return }
    if ($env:TERM_PROGRAM -eq 'vscode' -or $env:ZED_TERM -or $env:TERMINAL_EMULATOR -like 'JetBrains-*') { return }
    if ($host.Name -ne 'ConsoleHost') { return }
    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { return }
    foreach ($a in [Environment]::GetCommandLineArgs()) {
        if ($a -match '^[-/](c|command|f|file|noninteractive|encodedcommand|e|ec)$') { return }
    }
    if (-not (Test-Cmd herdr)) { return }
    & herdr
}
