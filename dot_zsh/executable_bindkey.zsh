# ===================================
# Keybindings for Navigation and Search
# ===================================
# Binds the 'Esc' followed by 'w' to kill the region (cut selected text).
bindkey '^[w' kill-region

# Binds left and right arrow keys to search the history backwards and forwards.
# bindkey "^[[A" history-search-backword
# bindkey "^[[B" history-search-forword

autoload -Uz add-zsh-hook

# --- Apply bindings after zsh-vi-mode initializes (avoids override) ---
# If zvm (zsh-vi-mode) is loaded, defer until its init completes.
# Otherwise apply immediately (e.g. when vi-mode plugin is absent).
function _apply_custom_bindkeys() {
    local _keymap

    # fzf's history search in emacs/viins; ^R stays redo in vicmd.
    # Guard: fzf-history-widget only exists when fzf key-bindings were sourced
    # (requires fzf >= 0.48 with --zsh, or a key-bindings file fallback).
    if (( ${+widgets[fzf-history-widget]} )); then
        bindkey -M emacs '^R' fzf-history-widget
        bindkey -M viins '^R' fzf-history-widget
    fi
    # fzf --zsh sets ^R in vicmd too — override it back to standard vi redo.
    bindkey -M vicmd '^R' redo

    # Re-bind Tab to fzf-tab after vi-mode initializes (vi-mode overrides it).
    # Guard: fzf-tab-complete only exists when fzf-tab plugin is loaded.
    if (( ${+widgets[fzf-tab-complete]} )); then
        bindkey '^I' fzf-tab-complete
    fi

    # Keep vi-mode-specific bindings inside zsh-vi-mode's own hook.
    if (( ${+widgets[fzf-file-widget]} )); then
        for _keymap in emacs; do
            bindkey -M "${_keymap}" '^T' fzf-file-widget
        done
    fi

    # Final Tab bind — ensure fzf-tab owns it after all other setup runs.
    if (( ${+widgets[fzf-tab-complete]} )); then
        bindkey '^I' fzf-tab-complete
    fi

    unset _keymap
}

function zvm_after_lazy_keybindings() {
    if (( ${+widgets[fzf-history-widget]} )); then
        zvm_bindkey viins '^R' fzf-history-widget
    fi

    # Restore ^R as redo in vicmd — fzf/global binds override it otherwise
    zvm_bindkey vicmd '^R' redo

    if (( ${+widgets[fzf-file-widget]} )); then
        zvm_bindkey viins '^T' fzf-file-widget
    fi
}

function _apply_custom_bindkeys_once() {
    _apply_custom_bindkeys
    add-zsh-hook -d precmd _apply_custom_bindkeys_once
}

if (( ${+functions[zvm_after_init]} )); then
    if (( ${+parameters[_post_zvm_hooks]} )); then
        _post_zvm_hooks+=("_apply_custom_bindkeys")
    fi
else
    _apply_custom_bindkeys
fi

add-zsh-hook precmd _apply_custom_bindkeys_once
