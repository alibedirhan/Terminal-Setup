#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: ana ekran
# ============================================================================

tui_main() {
    UI_HEADER_FN=tui_header
    ui_session_begin
    if [[ "$(settings_get update_check on)" == "on" ]]; then
        update_check && ui_pause
    fi
    while true; do
        TUI_BIG_HEADER=1 UI_FOOTER_FN=tui_hint
        ui_menu "Ne yapmak istersiniz?" \
            "#Kurulum" \
            "Kurulum sihirbazı|Profil ve tema seçerek adım adım kur|✦" \
            "Tema dene|7 temayı canlı önizle, beğenmezsen geri al|◐" \
            "Bileşenler|Araçları tek tek kur ya da kaldır|▦" \
            "#Yönetim" \
            "Durum ve teşhis|Neler kurulu, sorun var mı|◎" \
            "Kaldır|Görünümü sıfırla ya da tamamen kaldır|↺" \
            "Ayarlar|Varsayılan profil, güncelleme kontrolü|≡" \
            "Çıkış||×"
        local rc=$?
        TUI_BIG_HEADER=0 UI_FOOTER_FN=""
        if ((rc != 0)) || ((UI_CHOICE == 6)); then
            tui_goodbye
            return 0
        fi
        ui_clear
        case "$UI_CHOICE" in
            0) tui_install_wizard ;;
            1) tui_theme_browser ;;
            2) tui_components ;;
            3) status_show; run_doctor; ui_pause ;;
            4) tui_uninstall ;;
            5) tui_settings ;;
        esac
    done
}

tui_goodbye() {
    ui_session_end
    ui_clear
    printf '%s %s\n' "$(ui_gradient_text "Terminal Setup")" "${U_MUTED}· görüşmek üzere${U_RST}"
    if ((_TUI_ST_COUNT > 0)); then
        printf '%s\n' "${U_MUTED}Değişiklikleri görmek için yeni bir terminal açın. Geri almak için: ./terminal-setup.sh uninstall${U_RST}"
    fi
}
