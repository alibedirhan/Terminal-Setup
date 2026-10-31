#!/usr/bin/env bash
# Bileşen: fzf-tab — Tab tamamlamalarını fzf'li, aranabilir bir listede göster
#
# compinit'ten sonra (zsh temeli, 10), tuşları saran eklentilerden önce
# (öneriler 20, renklendirme 98) yüklenir. Oh My Zsh kullanılıyorsa onun
# plugins listesine eklenir.

component_register fzf-tab "fzf-tab" shell "Tab ile tamamlamayı aranabilir listede göster" "zsh fzf"

component_tip fzf-tab "Tab" "Tamamlamaları aranabilir listede gör"
component_tip fzf-tab "< >" "Liste grupları arasında geç"

FZF_TAB_DIR="$HOME/.oh-my-zsh/custom/plugins/fzf-tab"

_fzf_tab_dir() {
    if ohmyzsh_in_use; then REPLY="$FZF_TAB_DIR"; else REPLY="$TS_DATA_DIR/plugins/fzf-tab"; fi
}

comp_fzf_tab_install() {
    local dir styles
    _fzf_tab_dir; dir="$REPLY"
    act_clone https://github.com/Aloxaf/fzf-tab.git "$dir" || return 1
    styles="zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' switch-group '<' '>'
(( \$+commands[eza] )) && zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always \$realpath'"
    if [[ "$dir" == "$FZF_TAB_DIR" ]]; then
        act_zsh_snippet 18 fzf-tab "plugins+=(fzf-tab)
$styles
$(zsh_late_load fzf_tab '$+functions[enable-fzf-tab] || ! $+functions[compdef]' "$dir/fzf-tab.plugin.zsh")"
        return
    fi
    act_zsh_snippet 18 fzf-tab "$styles
(( \$+functions[compdef] && ! \$+functions[enable-fzf-tab] )) && source \"$dir/fzf-tab.plugin.zsh\""
}

comp_fzf_tab_verify() {
    [[ -f "$TS_CONFIG_DIR/zsh.d/18-fzf-tab.zsh" ]] &&
        [[ -d "$FZF_TAB_DIR" || -d "$TS_DATA_DIR/plugins/fzf-tab" ]]
}
