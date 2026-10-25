#!/usr/bin/env bash
# Teşhis: Powerlevel10k yapılandırılmış mı?

diag_register p10k "Prompt ayarı"

diag_p10k_check() {
    if [[ "$(component_state p10k)" != "ours" ]]; then
        diag_say "Powerlevel10k kurulu değil"
        return 0
    fi
    if [[ -f "$HOME/.p10k.zsh" ]]; then
        diag_say "%s mevcut" "$(ts_pretty_path "$HOME/.p10k.zsh")"
        return 0
    fi
    diag_say "Henüz yapılandırılmadı: zsh içinde '%s' çalıştırın" "p10k configure"
    return 1
}
