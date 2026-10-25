#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: kaldırma
# ============================================================================

tui_uninstall() {
    local items=(
        "Görünümü sıfırla|Tema ve renkler eski haline döner, araçlar kalır|◐"
        "Planı göster|Tamamen kaldırınca ne olacağını gör (değişiklik yok)|◎"
        "Tamamen kaldır|Sistem kurulum öncesine döner|↺"
    )
    legacy_detect && items+=("v5 kurulumunu temizle|Eski sürümün bıraktıklarını adım adım kaldır|×")
    ui_menu "Kaldır" "${items[@]}" || return 0
    ui_clear
    case "$UI_CHOICE" in
        0) appearance_reset ;;
        1) if ledger_exists; then uninstall_show_plan; else log_info "Kayıtlı bir değişiklik yok."; fi ;;
        2) uninstall_all ;;
        3) legacy_uninstall ;;
    esac
    ui_pause
}
