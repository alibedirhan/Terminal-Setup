#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: ayarlar
# ============================================================================

tui_settings() {
    local profiles=() items=() p upd
    while true; do
        upd=$(settings_get update_check on)
        ui_menu "Ayarlar" \
            "Varsayılan profil|Şu an: $(settings_get default_profile developer)" \
            "Güncelleme kontrolü|Açılışta GitHub'a bakılsın mı? Şu an: $upd" \
            "Şimdi güncelleme ara|" \
            "Dosya konumları|Defter, fotoğraf, log nerede" || return 0
        ui_clear
        case "$UI_CHOICE" in
            0)
                mapfile -t profiles < <(profile_list)
                items=()
                for p in "${profiles[@]}"; do items+=("$p|$(profile_description "$p")"); done
                ui_menu "Varsayılan profil" "${items[@]}" && settings_set default_profile "${profiles[UI_CHOICE]}" ;;
            1) [[ "$upd" == on ]] && settings_set update_check off || settings_set update_check on ;;
            2) update_check || log_ok "Güncel sürümdesiniz ($TS_VERSION)."; ui_pause ;;
            3)
                ui_title "Dosya konumları"
                printf '  %s%s\n' "$(ui_pad "Defter" 22)" "$(ts_pretty_path "$TS_LEDGER")"
                printf '  %s%s\n' "$(ui_pad "Başlangıç fotoğrafı" 22)" "$(ts_pretty_path "$TS_BASELINE_DIR")"
                printf '  %s%s\n' "$(ui_pad "Zsh/tmux parçaları" 22)" "$(ts_pretty_path "$TS_CONFIG_DIR")"
                printf '  %s%s\n' "$(ui_pad "İndirilen araçlar" 22)" "$(ts_pretty_path "$TS_BIN_DIR")"
                printf '  %s%s\n' "$(ui_pad "Log" 22)" "$(ts_pretty_path "$TS_LOG_FILE")"
                ui_pause ;;
        esac
    done
}
