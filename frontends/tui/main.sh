#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: uygulama girişi
# ============================================================================
# Menü ekranları yalnızca seçim yapar. Sistemi değiştiren ya da çıktı üreten
# her işlem tui_run ile çalışır: terminal normal kipe ve ana ekrana döner,
# işlemin çıktısı kaydırılabilir geçmişte kalır; Enter'dan sonra menüye
# dönülür ve başlıktaki durum yenilenir.
# ============================================================================

tui_main() {
    UI_HEADER_FN=tui_header
    ui_term_enter
    if [[ "$(settings_get update_check on)" == "on" ]]; then
        tui_run_quiet update_check
    fi
    while tui_main_menu; do
        case "$UI_CHOICE" in
            0) tui_install_wizard ;;
            1) tui_theme_browser ;;
            2) tui_components ;;
            3) tui_run tips_show ;;
            4) tui_run tui_status ;;
            5) tui_run upgrade_run ;;
            6) tui_uninstall ;;
            7) tui_settings ;;
            *) break ;;
        esac
    done
    tui_goodbye
}

tui_main_menu() {
    ui_menu --hero --footer tui_hint "Ne yapmak istersiniz?" \
        "#Kurulum" \
        "Kurulum sihirbazı|Profil ve tema seçerek adım adım kur|✦" \
        "Tema dene|7 temayı canlı önizle, beğenmezsen geri al|◐" \
        "Bileşenler|Araçları tek tek kur ya da kaldır|▦" \
        "Kısayollar|Kurulan araçlar nasıl kullanılır|?" \
        "#Yönetim" \
        "Durum ve teşhis|Neler kurulu, sorun var mı|◎" \
        "Güncelle|Kurulan araçları son sürüme yükselt|↑" \
        "Kaldır|Görünümü sıfırla ya da tamamen kaldır|↺" \
        "Ayarlar|Dil, varsayılan profil, güncelleme kontrolü|≡" \
        "Çıkış||×"
}

# İşlemi menü dışında çalıştır, bitince Enter bekle: tui_run KOMUT [ARG...]
tui_run() {
    local rc
    ui_term_suspend
    printf '\n'
    "$@"
    rc=$?
    ui_pause
    UI_HEADER_STALE=1
    ui_term_resume
    return "$rc"
}

# Yalnızca bir şey söylediyse beklet (güncelleme bildirimi gibi)
tui_run_quiet() {
    ui_term_suspend
    if "$@"; then ui_pause; fi
    ui_term_resume
}

tui_status() {
    status_show
    run_doctor
}

tui_goodbye() {
    ui_term_leave
    ui_gradient_text "Terminal Setup"
    _t "görüşmek üzere"
    printf '%s %s\n' "$REPLY" "${U_MUTED}· ${TR}${U_RST}"
    if ((_TUI_ST_COUNT > 0)); then
        _t "Değişiklikleri görmek için yeni bir terminal açın. Geri almak için: %s" "./terminal-setup.sh uninstall"
        printf '%s\n' "${U_MUTED}${TR}${U_RST}"
    fi
}
