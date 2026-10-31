#!/usr/bin/env bash
# Bileşen: Zsh eklentileri — komut önerisi ve sözdizimi renklendirme
#
# Oh My Zsh kullanılıyorsa eklentiler onun klasörüne klonlanır ve plugins
# listesine eklenir (listesi ~/.zshrc'de yeniden yazılırsa ilk istemde
# doğrudan yüklenir). Kullanılmıyorsa (v7 varsayılanı) Terminal Setup'ın veri
# klasörüne klonlanır ve doğrudan yüklenir: öneriler 20'de, sözdizimi
# renklendirme bütün widget'lar tanımlandıktan sonra, 98'de.

component_register zsh-plugins "Zsh eklentileri" shell "Komut önerisi + sözdizimi renklendirme" "zsh"

component_tip zsh-plugins "→" "Gri öneriyi kabul et"
component_tip zsh-plugins "Alt+→" "Önerinin bir kelimesini al"

ZSH_PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins"
TS_PLUGIN_DIR="$TS_DATA_DIR/plugins"

comp_zsh_plugins_install() {
    local dir="$TS_PLUGIN_DIR"
    ohmyzsh_in_use && dir="$ZSH_PLUGIN_DIR"
    act_clone https://github.com/zsh-users/zsh-autosuggestions.git "$dir/zsh-autosuggestions" || return 1
    act_clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$dir/zsh-syntax-highlighting" || return 1
    if [[ "$dir" == "$ZSH_PLUGIN_DIR" ]]; then
        # syntax-highlighting listenin sonunda olmalı
        act_zsh_snippet 20 zsh-plugins "plugins+=(zsh-autosuggestions zsh-syntax-highlighting)
$(zsh_late_load zsh_autosuggest '$+functions[_zsh_autosuggest_start]' \
    "$dir/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" _zsh_autosuggest_start)
$(zsh_late_load zsh_highlight '$+functions[_zsh_highlight]' \
    "$dir/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh")"
        return
    fi
    act_zsh_snippet 20 zsh-plugins "(( \$+functions[_zsh_autosuggest_start] )) ||
    source \"$dir/zsh-autosuggestions/zsh-autosuggestions.zsh\"" || return 1
    act_zsh_snippet 98 zsh-highlight "(( \$+functions[_zsh_highlight] )) ||
    source \"$dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\""
}

comp_zsh_plugins_verify() {
    local dir
    for dir in "$TS_PLUGIN_DIR" "$ZSH_PLUGIN_DIR"; do
        [[ -d "$dir/zsh-autosuggestions" && -d "$dir/zsh-syntax-highlighting" ]] &&
            [[ -f "$TS_CONFIG_DIR/zsh.d/20-zsh-plugins.zsh" ]] && return 0
    done
    return 1
}
