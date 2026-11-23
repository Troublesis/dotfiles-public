#!/bin/zsh
# =============================================================================
# Platform helpers shared by OS/host alternates
# =============================================================================

typeset -g ZSH_PLATFORM_OS="$(uname -s 2>/dev/null || printf 'unknown')"
typeset -g ZSH_PLATFORM_HOST="${HOST:-$(hostname -s 2>/dev/null || hostname 2>/dev/null || printf 'unknown')}"

is_macos() {
    [[ "${ZSH_PLATFORM_OS}" == "Darwin" ]]
}

is_linux() {
    [[ "${ZSH_PLATFORM_OS}" == "Linux" ]]
}

is_nas_host() {
    [[ "${ZSH_PLATFORM_HOST}" == "code-server" || "${ZSH_PLATFORM_HOST}" == *nas* ]]
}

append_path_if_dir() {
    local _dir

    for _dir in "$@"; do
        if [[ -d "${_dir}" ]]; then
            path=("${_dir}" ${path:#"${_dir}"})
        fi
    done

    export PATH="${(j.:.)path}"
    unset _dir
}

first_command_path() {
    local _cmd

    for _cmd in "$@"; do
        if command -v "${_cmd}" >/dev/null 2>&1; then
            command -v "${_cmd}"
            return 0
        fi
    done

    return 1
}

queue_post_zvm_hook() {
    local _hook_name="$1"

    [[ -n "${_hook_name}" ]] || return 1

    if (( ${+parameters[_post_zvm_hooks]} )); then
        _post_zvm_hooks+=("${_hook_name}")
        return 0
    fi

    return 1
}

load_moshi_webhook_token() {
    [[ -n "${MOSHI_WEBHOOK_TOKEN:-}" ]] && return 0
    [[ -f "${HOME}/.zsh_secrets" ]] || return 1

    source "${HOME}/.zsh_secrets"
    [[ -n "${MOSHI_WEBHOOK_TOKEN:-}" ]]
}
