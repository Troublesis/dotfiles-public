#!/bin/zsh
# =============================================================================
# tmux auto-attach (shared, all OS / host classes)
# Sourced LAST by ~/.zshrc so PATH, secrets and plugins are already loaded.
#
# Behaviour: every new interactive terminal enters tmux, attaching to the most
# recently attached session, or creating a new one if none exist.
#
# Opt out for one shell:   NO_AUTO_TMUX=1 zsh
# Opt out permanently:     export NO_AUTO_TMUX=1   (e.g. in ~/.zshenv)
#
# Not run (guards below): non-interactive shells, already inside tmux, no TTY,
# tmux missing, VS Code/Cursor terminals, JetBrains/Zed terminals, herdr panes,
# and Claude Code / agent-run shells.
# =============================================================================

function _tmux_auto_attach() {
    # Interactive + real terminal on stdin/stdout only.
    [[ -o interactive && -t 0 && -t 1 ]] || return 0
    # Opt-out and nesting guards.
    [[ -z "${NO_AUTO_TMUX:-}" && -z "${TMUX:-}" ]] || return 0
    # IDE-integrated terminals (Cursor also reports TERM_PROGRAM=vscode).
    [[ "${TERM_PROGRAM:-}" != vscode ]] || return 0
    [[ -z "${ZED_TERM:-}" && "${TERMINAL_EMULATOR:-}" != JetBrains-* ]] || return 0
    # herdr panes and agent-run shells (Claude Code etc.).
    [[ -z "${HERDR_ENV:-}" && -z "${CLAUDECODE:-}" && -z "${AI_AGENT:-}" ]] || return 0
    # tmux must be installed.
    (( ${+commands[tmux]} )) || return 0

    # Most recently attached session, addressed by its unique id ("$N", immune
    # to odd session names). Never-attached sessions report an empty or 0
    # timestamp and sort last. Errors (no server) are silenced and yield an
    # empty result, in which case a new session is created (detached) first.
    local latest sid msg
    local -a notice=()
    latest=$(command tmux list-sessions -F '#{session_last_attached} #{session_id}' 2>/dev/null \
        | sort -rn | head -n 1)
    sid="${latest#* }"
    if [[ -z "$sid" ]]; then
        sid=$(command tmux new-session -d -P -F '#{session_id}' 2>/dev/null) || return 0
    elif (( ${+functions[tmux_server_notice]} )); then
        # Optional per-OS hook (defined in os.zsh fragments): prints a warning
        # about the existing server, shown in the status line once attached.
        msg=$(tmux_server_notice)
        [[ -n "$msg" ]] && notice=(';' display-message -d 15000 "$msg")
    fi

    # Not exec'd on purpose: if tmux fails (bad config, etc.) you keep a usable
    # shell. After tmux returns: if the session still exists you only detached
    # (Ctrl-b d) -> stay in this plain shell; if it is gone (last shell exited)
    # -> close the terminal as before.
    command tmux attach-session -t "$sid" "${notice[@]}" || return 0
    command tmux has-session -t "$sid" 2>/dev/null || exit
}

_tmux_auto_attach
unfunction _tmux_auto_attach
