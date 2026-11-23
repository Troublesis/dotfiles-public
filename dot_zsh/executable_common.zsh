# =============================================================================
# Common Zsh Configuration (cross-platform, OS-agnostic)
# Aliases & utilities sourced from ~/.zshrc's explicit module array.
# macOS-specific aliases are in ~/.zsh/os.zsh (chezmoi template).
# Secrets, PATH, and TERM fallback are handled in ~/.zshrc (load-order critical).
# =============================================================================

# Short-circuit for non-interactive shells (scp, rsync, git hooks, ssh cmd).
[[ -o interactive ]] || return 0

# --- Alias ---

# linux
alias ms="/config/.local/bin/moshi-hook serve"


# chezmoi
alias cz="chezmoi"
alias cza="chezmoi add"
alias czd="chezmoi diff"
alias cze="chezmoi edit"
alias czs="chezmoi status"
alias czu="chezmoi update"
alias czp="chezmoi git push"
alias czr="chezmoi re-add"

# aic2 wrapper
ac() {
  command aic2 "$@"
}

# look: view images in the terminal via kitty's `kitten icat`
look() {
  if ! command -v kitten &>/dev/null; then
    print -u2 "look: kitty is not available (kitten not found in PATH)"
    return 127
  fi
  kitten icat "$@"
}


# =============================================================================
# Standard Command Overrides
# =============================================================================

alias vi="nvim"
alias md="vim README.md"
alias x="clear"
alias c="claude"
alias cls="clear"
alias type="type -a"
alias where="which"
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ============================================================
# Configuration Editing
# Uses chezmoi edit when available, falls back to vi on error
# ============================================================

_edit() {
  local file="$1"
  # `chezmoi managed <unmanaged-path>` exits 0 with no output, so test source-path
  # (non-zero + "not managed" when the target has no source — e.g. a half-applied host).
  if command -v chezmoi &>/dev/null && [[ -n "$(chezmoi source-path "$file" 2>/dev/null)" ]]; then
    chezmoi edit --apply "$file" || vi "$file"
  else
    vi "$file"
  fi
}

# --- Core Config Files ---
alias ez="_edit ~/.zshrc"                   # Edit zshrc
alias etmux="_edit ~/.tmux.conf"            # Edit tmux config
alias evi="_edit ~/.config/nvim/init.lua"   # Edit Neovim config
alias eyy="_edit ~/.config/yazi/yazi.toml"  # Edit Yazi config
alias essh="_edit ~/.ssh/config"            # Edit SSH config
alias eh="_edit ~/.zsh_history"             # Edit Zsh history
alias er="_edit ~/README.md"               # Edit Dotfiles README
alias eb="chezmoi cd"                       # Open chezmoi source dir

# ai config
alias ecc="_edit ~/.claude/settings.json"

# --- Zsh Modules ---
alias ea="_edit ~/.zsh/common.zsh"          # Edit common.zsh
alias egit="vi ~/.gitconfig.local"           # Edit git.zsh
alias ed="_edit ~/.zsh/docker.zsh"          # Edit docker.zsh
alias ek="_edit ~/.zsh/bindkey.zsh"         # Edit bindkey.zsh
alias eai="_edit ~/.zsh/ai.zsh"             # Edit ai.zsh
alias eplatform="_edit ~/.zsh/platform.zsh" # Edit platform helpers
alias ec="_edit ~/.zsh/common.zsh"
alias es="_edit ~/.zsh_secrets"

# --- Chezmoi Templates (chezmoi edit preferred, vi fallback) ---
alias eosi="_edit ~/.zsh/os.zsh"            # Edit OS-specific config
alias ehost="_edit ~/.zsh/host.zsh"         # Edit host-specific config

# --- Source/Reload ---
alias r="source ~/.zshrc"                    # Reload zshrc
alias rt="tmux source ~/.tmux.conf"      # Reload tmux conf
alias senv="source .venv/bin/activate"               # Activate venv

# --- Navigation Shortcuts ---
alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"
alias dl="cd ~/Downloads"


# =============================================================================
# File Operations & Navigation
# =============================================================================

alias rm="rm -i -v"      # Verbose & interactive delete
alias mv="mv -v"         # Verbose move
alias cp="cp -v"         # Verbose copy
alias chmox="chmod -x"   # Remove executable
alias tree="eza --tree"
alias treel="eza --tree --long"

# Enhanced listing (eza)
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons=auto"
  alias ll="eza --icons=auto -lh"
  alias la="eza --icons=auto -lah"
else
  alias ls="ls --color=auto"
  alias ll="ls -lh"
  alias la="ls -lah"
fi

# Yazi (File Manager)
function ya() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
  alias zz='cd "$(zoxide query -i)"'
else
  alias zz='cd'
fi


# =============================================================================
# SSH & Remote Connections (host aliases live in the private overlay: ~/.zsh/personal.zsh)
# =============================================================================


function pem() {
    echo "Input ssh.key path to regenerate key file:"
    autoload -Uz compinit; compinit
    zmodload zsh/zle
    bindkey '^I' expand-or-complete
    vared -p 'ssh.key path: ' -c SSHKEY_PATH
    chmod 600 "$SSHKEY_PATH"
    ssh-keygen -f "$SSHKEY_PATH" -m PEM -p
}


# =============================================================================
# Network & Connectivity (cross-platform)
# =============================================================================

alias hosts="sudo vi /etc/hosts"
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias urlencode='python3 -c "import sys, urllib as ul; print(ul.quote_plus(sys.argv[1]));"'


# =============================================================================
# Development Tools
# =============================================================================

# # HTTP Methods (Perl lwp-request)
# for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
#     alias "${method}"="lwp-request -m '${method}'"
# done
#
# # PDF Utils
# alias mergepdf='gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=_merged.pdf'

# =============================================================================
# Interactive Utilities
# =============================================================================
unalias size 2>/dev/null
size() {
    # Default to current directory if no path is provided
    local target_path="${1:-.}"

    # Check if the path exists to avoid errors
    if [ -e "$target_path" ]; then
        du -h -d 1 "$target_path" | sort -h
    else
        echo "Error: Path '$target_path' does not exist."
        return 1
    fi
}

# fsize with fzf and zoxide
function fsize() {
    local selected_path

    if command -v zoxide >/dev/null 2>&1; then
        selected_path=$(zoxide query -l | fzf --prompt="Select directory to check size: " --height=40% --layout=reverse --border)
    fi

    if [[ -z "$selected_path" ]]; then
        selected_path="."
    fi

    echo "Checking size for: $selected_path"
    du -h -d 1 "$selected_path" | sort -h
}

# Safe top function for btop
function top() {
    if command -v btop >/dev/null 2>&1; then
        btop
    else
        command top "$@"
    fi
}


# =============================================================================
# Miscellaneous
# =============================================================================

alias week='date +%V'
alias map="xargs -n1"

function t() {
    # No arguments: interactive session picker
    if [ $# -eq 0 ]; then
        local sessions
        sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

        if [ -z "$sessions" ]; then
            echo "No active tmux sessions found."
            echo -n "Create a new session? [Y/n]: "
            read -r response
            if [[ ! "$response" =~ ^[Nn]$ ]]; then
                echo -n "Session name (leave blank for default): "
                read -r SESSION_NAME
                if [ -z "$SESSION_NAME" ]; then
                    tmux new-session
                else
                    tmux new-session -s "$SESSION_NAME"
                fi
            fi
            return 0
        fi

        local session_count
        session_count=$(echo "$sessions" | wc -l | tr -d ' ')

        # If only one session exists, attach to it directly
        if [ "$session_count" -eq 1 ]; then
            echo "Attaching to session: $sessions"
            tmux attach-session -t "$sessions"
            return 0
        fi

        # Multiple sessions: show numbered list
        echo "Active tmux sessions:"
        local i=1
        while IFS= read -r session; do
            echo "  [$i] $session"
            ((i++))
        done <<< "$sessions"

        echo -n "Select session [1-${session_count}] or enter name: "
        read -r input

        local target
        if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le "$session_count" ]; then
            # Numeric input: pick by index
            target=$(echo "$sessions" | sed -n "${input}p")
        else
            # Non-numeric: treat as session name
            target="$input"
        fi

        if tmux has-session -t "$target" 2>/dev/null; then
            tmux attach-session -t "$target"
        else
            echo "Error: Session '$target' not found."
            return 1
        fi

    else
        # Pass all arguments directly to tmux (e.g. t new -s work)
        command tmux "$@"
    fi
}

# herdr session picker — mirrors t(): no-arg = pick/attach, args pass through
function h() {
    # Not interactive or no herdr: pass through (e.g. `h --help`)
    if [ $# -gt 0 ]; then
        command herdr "$@"
        return $?
    fi

    local json
    json=$(command herdr session list --json 2>/dev/null)
    if [ -z "$json" ]; then
        echo "herdr not running or unavailable. Launching default session..."
        command herdr --session default
        return $?
    fi

    # Extract session names from JSON (no jq dependency)
    local sessions
    sessions=$(echo "$json" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')

    if [ -z "$sessions" ]; then
        echo "No herdr sessions found."
        echo -n "Create default session? [Y/n]: "
        read -r response
        if [[ ! "$response" =~ ^[Nn]$ ]]; then
            command herdr --session default
        fi
        return 0
    fi

    local session_count
    session_count=$(echo "$sessions" | wc -l | tr -d ' ')

    # Single session: attach directly
    if [ "$session_count" -eq 1 ]; then
        echo "Attaching to session: $sessions"
        command herdr session attach "$sessions"
        return $?
    fi

    # Multiple sessions: numbered list
    echo "Active herdr sessions:"
    local i=1
    while IFS= read -r session; do
        echo "  [$i] $session"
        ((i++))
    done <<< "$sessions"

    echo -n "Select session [1-${session_count}] or enter name: "
    read -r input

    local target
    if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le "$session_count" ]; then
        target=$(echo "$sessions" | sed -n "${input}p")
    else
        target="$input"
    fi

    if [ -n "$target" ]; then
        command herdr session attach "$target"
    fi
}


# --- Basic Configuration ---
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="yyyy-mm-dd"

# Completion styling
zstyle ':omz:update' mode disable
zstyle ':omz:update' frequency 90
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# History
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt auto_cd
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# --- Exports (cross-platform) ---
# Locale: en_US.UTF-8 where the host really has it (always on macOS). Minimal Linux
# hosts/containers often don't generate it, and an unavailable LC_ALL (also forwarded by
# ssh from the client) makes every child bash print "setlocale: cannot change locale".
_dl_loc="en_US.UTF-8"
if [[ "$OSTYPE" == linux* ]]; then
    _dl_have="$(locale -a 2>/dev/null)"
    if print -r -- "$_dl_have" | grep -qix 'en_US\.utf-\?8'; then _dl_loc="en_US.UTF-8"
    elif print -r -- "$_dl_have" | grep -qix 'C\.utf-\?8'; then _dl_loc="C.UTF-8"
    else _dl_loc=""
    fi
    unset _dl_have
fi
if [[ -n "$_dl_loc" ]]; then
    export LANG="$_dl_loc" LC_ALL="$_dl_loc"
else
    unset LC_ALL
    export LANG=C
fi
unset _dl_loc
export YAZI_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
export YAZI_ZOXIDE_OPTS="--height=40% --layout=reverse --border=rounded --info=inline"
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border=rounded --info=inline"
export FZF_DEFAULT_COMMAND="fd --type f --strip-cwd-prefix --hidden --follow --exclude .git"

# Preferred editor — honored by chezmoi (edit/edit-config), git, sudoedit,
# crontab, etc. The `vi` alias below is NOT inherited by subprocesses, so
# without this export chezmoi falls back to its built-in default (`vi`) and
# fails on hosts lacking a real vi binary. Guarded so a box without nvim
# keeps chezmoi's fallback rather than pointing at a missing binary.
# (Previously set only in os.zsh_darwin + host.zsh_code-server; moved here
# so Linux/default hosts get it too.)
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
fi

# PATH is consolidated in ~/.zshrc (phase 6); per-OS extras stay in os.zsh.

typeset -g ZSH_HAS_TTY=0
if [[ -o interactive && -t 0 && -t 1 ]]; then
    ZSH_HAS_TTY=1
fi

# --- fzf key-bindings only (skip completion to avoid conflicting with fzf-tab) ---
# fzf --zsh outputs BOTH key-bindings (lines 1–199) and completion (200+).
# Completion rebinds Tab, clobbering fzf-tab. Source only the key-bindings portion.
# Fallback order:
#   1. fzf --zsh        (fzf >= 0.48, e.g. GitHub-releases install)
#   2. ~/.fzf/shell/… (git-clone install)
#   3. /usr/share/doc/fzf/examples/… (Ubuntu/Debian apt package)
#   4. /usr/share/fzf/…  (Arch/Fedora package paths)
typeset -g _fzf_init="" _fzf_end=$'\n### end: key-bindings.zsh ###'
(( ZSH_HAS_TTY )) && _fzf_init="$(command fzf --zsh 2>/dev/null)"
if [[ -n "$_fzf_init" ]]; then
    eval "${_fzf_init%%"$_fzf_end"*}" 2>/dev/null
elif (( ZSH_HAS_TTY )) && [[ -r "${HOME}/.fzf/shell/key-bindings.zsh" ]]; then
    source "${HOME}/.fzf/shell/key-bindings.zsh"
elif (( ZSH_HAS_TTY )) && [[ -r "/usr/share/doc/fzf/examples/key-bindings.zsh" ]]; then
    source "/usr/share/doc/fzf/examples/key-bindings.zsh"
elif (( ZSH_HAS_TTY )) && [[ -r "/usr/share/fzf/key-bindings.zsh" ]]; then
    source "/usr/share/fzf/key-bindings.zsh"
fi

# NOTE: TERM ghostty fallback and ~/.zsh_secrets are sourced in ~/.zshrc
# (phases 3 and 5) so they run before any consumer (ai.zsh, plugins, tools).

# --- thefuck (interactive shells only) ---
if [[ -z "${_THEFUCK_ALIAS_LOADED:-}" ]] && command -v thefuck >/dev/null 2>&1; then
    _thefuck_alias="$(thefuck --alias 2>/dev/null)" || _thefuck_alias=""
    if [[ -n "$_thefuck_alias" ]]; then
        eval "$_thefuck_alias"
        export _THEFUCK_ALIAS_LOADED=1
    fi
    unset _thefuck_alias
fi

# --- Zoxide init ---
# Eagerly initialize when available. The old lazy-load wrapper caused
# "defining function based on alias `z'" on shell reload: the first call to z
# triggers `zoxide init zsh` which sets `alias z=__zoxide_z`, then `source
# ~/.zshrc` tries to define z() again and zsh rejects redefining an alias as
# a function. Eager init is idempotent and takes < 1 ms.
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# --- Reset terminal input modes ---
if (( ZSH_HAS_TTY )); then
    autoload -Uz add-zsh-hook
    _reset_terminal_input_modes() {
        [[ -t 1 ]] || return
        printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1007l\e[?2004h'
    }
    add-zsh-hook precmd _reset_terminal_input_modes
fi

# --- Lazy load history search ---
if (( ZSH_HAS_TTY )); then
    autoload -Uz add-zsh-hook
    _load_history_search() {
        autoload -U up-line-or-beginning-search down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        add-zsh-hook -d precmd _load_history_search
    }
    add-zsh-hook precmd _load_history_search
fi

# --- Lazy load tmuxinator ---
function tmuxinator mux {
    unfunction tmuxinator mux
    [ -f "$HOME/.config/tmuxinator/tmuxinator.zsh" ] && source "$HOME/.config/tmuxinator/tmuxinator.zsh"
    $0 "$@"
}

# Custom cd function
cd() {
  if [ $# -eq 0 ]; then
    zz
  else
    builtin cd "$@"
  fi
}

# Tmux auto-attach lives in ~/.zsh/tmux-auto.zsh (sourced last by ~/.zshrc).
# Set NO_AUTO_TMUX=1 to opt out.

# `moshi DIR` is provided by the moshi-hook Homebrew package as a symlink to
# moshi-hook. Do not define a shell helper here — it would shadow the packaged
# launcher in interactive zsh sessions.

export no_proxy="localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,.local"   # gate:allow (generic RFC1918 ranges)
export NO_PROXY="localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,.local"   # gate:allow (generic RFC1918 ranges)
