#!/usr/bin/env bash
# Teşhis: Zsh kurulu ama varsayılan kabuk değil

diag_register shell "Varsayılan kabuk"

diag_shell_check() {
    local login
    login=$(sys_login_shell)
    if [[ "$(component_state zsh)" != "ours" ]]; then
        echo "${login:-?} (Zsh bileşeni kurulu değil)"
        return 0
    fi
    if [[ "$login" == */zsh ]]; then
        echo "$login"
        return 0
    fi
    echo "Zsh kurulu ama varsayılan kabuk $login"
    return 1
}

diag_shell_fix() {
    TS_CURRENT_COMPONENT="zsh"
    act_login_shell "$(command -v zsh)"
    TS_CURRENT_COMPONENT="core"
}
