#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: ana ekran
# ============================================================================

# Her menü çiziminde üstte görünen durum satırı (ağa çıkmaz)
tui_header() {
    local zsh_s p10k_s theme
    [[ "$(component_state zsh)" == ours ]] && zsh_s="${C_GREEN}✓${C_RESET}" || zsh_s="${C_DIM}-${C_RESET}"
    [[ "$(component_state p10k)" == ours ]] && p10k_s="${C_GREEN}✓${C_RESET}" || p10k_s="${C_DIM}-${C_RESET}"
    theme=$(settings_get theme)
    printf ' %s  %s\n' "${C_BOLD}${C_CYAN}Terminal Setup${C_RESET} ${C_DIM}$TS_VERSION${C_RESET}" \
        "${C_DIM}│${C_RESET} Zsh $zsh_s  P10k $p10k_s  Tema: ${theme:-yok}  Kayıt: $(ledger_count)"
}

tui_main() {
    UI_HEADER_FN=tui_header
    if [[ "$(settings_get update_check on)" == "on" ]]; then
        update_check && ui_pause
    fi
    while true; do
        ui_menu "Ana menü" \
            "Kurulum sihirbazı|Profil ve tema seçerek kur" \
            "Tema dene|Önizle, uygula, beğenmezsen geri al" \
            "Bileşenler|Araçları tek tek kur ya da kaldır" \
            "Durum ve teşhis|Neler kurulu, sorun var mı" \
            "Kaldır|Görünümü sıfırla ya da tamamen kaldır" \
            "Ayarlar|Varsayılan profil, güncelleme kontrolü" \
            "Çıkış|" || return 0
        ui_clear
        case "$UI_CHOICE" in
            0) tui_install_wizard ;;
            1) tui_theme_browser ;;
            2) tui_components ;;
            3) status_show; run_doctor; ui_pause ;;
            4) tui_uninstall ;;
            5) tui_settings ;;
            6) return 0 ;;
        esac
    done
}
