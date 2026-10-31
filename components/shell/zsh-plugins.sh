#!/usr/bin/env bash
# Bileşen: Zsh eklentileri — komut önerisi ve sözdizimi renklendirme

component_register zsh-plugins "Zsh eklentileri" shell "Komut önerisi + sözdizimi renklendirme" "ohmyzsh"

component_tip zsh-plugins "→" "Gri öneriyi kabul et"
component_tip zsh-plugins "Alt+→" "Önerinin bir kelimesini al"

ZSH_PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins"

comp_zsh_plugins_install() {
    act_clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_PLUGIN_DIR/zsh-autosuggestions" || return 1
    act_clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" || return 1
    # syntax-highlighting listenin sonunda olmalı
    act_zsh_snippet 20 zsh-plugins "plugins+=(zsh-autosuggestions zsh-syntax-highlighting)
$(zsh_late_load zsh_autosuggest '$+functions[_zsh_autosuggest_start]' \
    "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" _zsh_autosuggest_start)
$(zsh_late_load zsh_highlight '$+functions[_zsh_highlight]' \
    "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh")"
}

comp_zsh_plugins_verify() {
    [[ -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" && -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]] \
        && [[ -f "$TS_CONFIG_DIR/zsh.d/20-zsh-plugins.zsh" ]]
}
