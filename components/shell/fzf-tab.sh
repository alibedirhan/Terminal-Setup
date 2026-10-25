#!/usr/bin/env bash
# Bileşen: fzf-tab — Tab tamamlamalarını fzf'li, aranabilir bir listede göster

component_register fzf-tab "fzf-tab" shell "Tab ile tamamlamayı aranabilir listede göster" "ohmyzsh fzf"

component_tip fzf-tab "Tab" "Tamamlamaları aranabilir listede gör"
component_tip fzf-tab "< >" "Liste grupları arasında geç"

FZF_TAB_DIR="$HOME/.oh-my-zsh/custom/plugins/fzf-tab"

comp_fzf_tab_install() {
    act_clone https://github.com/Aloxaf/fzf-tab.git "$FZF_TAB_DIR" || return 1
    # fzf-tab, compinit'ten sonra ama zsh-autosuggestions gibi tuşları saran
    # eklentilerden önce yüklenmeli: 18 < 20 (zsh-plugins)
    act_zsh_snippet 18 fzf-tab "plugins+=(fzf-tab)
zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' switch-group '<' '>'
(( \$+commands[eza] )) && zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always \$realpath'"
}

comp_fzf_tab_verify() {
    [[ -d "$FZF_TAB_DIR" && -f "$TS_CONFIG_DIR/zsh.d/18-fzf-tab.zsh" ]]
}
