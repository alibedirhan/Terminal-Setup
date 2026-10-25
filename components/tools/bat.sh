#!/usr/bin/env bash
# Bileşen: bat — sözdizimi renklendirmeli cat

component_register bat "bat" tools "Renkli cat" ""

component_tip bat "cat dosya" "Sözdizimi renklendirmesiyle göster"

comp_bat_install() {
    act_pkg bat || return 1
    # Ubuntu'da komutun adı batcat'tir
    act_zsh_snippet 60 bat "(( \$+commands[batcat] && ! \$+commands[bat] )) && alias bat='batcat'
alias cat='bat --paging=never --style=plain'" || return 1
    act_glob "$HOME/.cache/bat"
}

comp_bat_verify() { has_cmd batcat || has_cmd bat; }
