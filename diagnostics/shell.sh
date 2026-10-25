#!/usr/bin/env bash
# Teşhis: Zsh kurulu ama varsayılan kabuk değil

diag_register shell "Varsayılan kabuk"

diag_shell_check() {
    local login
    login=$(sys_login_shell)
    if [[ "$(component_state zsh)" != "ours" ]]; then
        diag_say "%s (Zsh bileşeni kurulu değil)" "${login:-?}"
        return 0
    fi
    if [[ "$login" == */zsh ]]; then
        echo "$login"
        return 0
    fi
    diag_say "Zsh kurulu ama varsayılan kabuk %s" "$login"
    return 1
}

diag_shell_fix() {
    TS_CURRENT_COMPONENT="zsh"
    act_login_shell "$(command -v zsh)"
    TS_CURRENT_COMPONENT="core"
}
