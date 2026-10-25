#!/usr/bin/env bash
# Teşhis: Powerlevel10k yapılandırılmış mı?

diag_register p10k "Prompt ayarı"

diag_p10k_check() {
    if [[ "$(component_state p10k)" != "ours" ]]; then
        echo "Powerlevel10k kurulu değil"
        return 0
    fi
    if [[ -f "$HOME/.p10k.zsh" ]]; then
        echo "$(ts_pretty_path "$HOME/.p10k.zsh") mevcut"
        return 0
    fi
    echo "Henüz yapılandırılmadı: zsh içinde 'p10k configure' çalıştırın"
    return 1
}
