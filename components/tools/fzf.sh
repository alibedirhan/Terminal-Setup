#!/usr/bin/env bash
# Bileşen: fzf — bulanık arama (Ctrl+R geçmiş, Ctrl+T dosya)

component_register fzf "fzf" tools "Bulanık arama: geçmiş ve dosyalar" ""

component_tip fzf "Ctrl+R" "Komut geçmişinde bulanık ara (atuin kuruluysa atuin açılır)"
component_tip fzf "Ctrl+T" "Dosya seçip komut satırına ekle"
component_tip fzf "Alt+C" "Alt dizine bulanık arayarak geç"

comp_fzf_install() {
    act_gh_binary junegunn/fzf 'linux_amd64\.tar\.gz$' 'linux_arm64\.tar\.gz$' fzf || return 1
    act_zsh_snippet 60 fzf 'if (( $+commands[fzf] )); then
    source <(fzf --zsh)
    if (( $+commands[fdfind] )); then
        export FZF_DEFAULT_COMMAND="fdfind --type f --hidden --follow --exclude .git"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi'$'\n'"$(zsh_late_rebind fzf fzf-history-widget)"
}

comp_fzf_verify() { has_cmd fzf; }
