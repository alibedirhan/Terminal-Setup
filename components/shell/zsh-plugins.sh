#!/usr/bin/env bash
# Bileşen: Zsh eklentileri — komut önerisi ve sözdizimi renklendirme

component_register zsh-plugins "Zsh eklentileri" shell "Komut önerisi + sözdizimi renklendirme" "ohmyzsh"

ZSH_PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins"

comp_zsh_plugins_install() {
    act_clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_PLUGIN_DIR/zsh-autosuggestions" || return 1
    act_clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" || return 1
    # syntax-highlighting listenin sonunda olmalı
    act_zsh_snippet 20 zsh-plugins 'plugins+=(zsh-autosuggestions zsh-syntax-highlighting)'
}

comp_zsh_plugins_verify() {
    [[ -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" && -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]] \
        && [[ -f "$TS_CONFIG_DIR/zsh.d/20-zsh-plugins.zsh" ]]
}
