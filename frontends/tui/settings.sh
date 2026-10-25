#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: ayarlar
# ============================================================================

tui_settings() {
    local profiles=() items=() p upd
    while true; do
        upd=$(settings_get update_check on)
        ui_menu "Ayarlar" \
            "Varsayılan profil|Şu an: $(settings_get default_profile developer)|▸" \
            "Güncelleme kontrolü|Açılışta GitHub'a bakılsın mı? Şu an: $upd|▸" \
            "Şimdi güncelleme ara||▸" \
            "Dosya konumları|Defter, fotoğraf, log nerede|▸" || return 0
        case "$UI_CHOICE" in
            0)
                mapfile -t profiles < <(profile_list)
                items=()
                for p in "${profiles[@]}"; do items+=("$p|$(profile_description "$p")|▸"); done
                ui_menu "Varsayılan profil" "${items[@]}" && settings_set default_profile "${profiles[UI_CHOICE]}" ;;
            1) if [[ "$upd" == on ]]; then settings_set update_check off; else settings_set update_check on; fi ;;
            2) tui_run tui_update_check ;;
            3) tui_run tui_paths ;;
        esac
    done
}

tui_update_check() {
    update_check || log_ok "Güncel sürümdesiniz ($TS_VERSION)."
}

tui_paths() {
    ui_title "Dosya konumları"
    ui_card_top ""
    _status_kv "Defter" "$(ts_pretty_path "$TS_LEDGER")"
    _status_kv "Başlangıç fotoğrafı" "$(ts_pretty_path "$TS_BASELINE_DIR")"
    _status_kv "Zsh/tmux parçaları" "$(ts_pretty_path "$TS_CONFIG_DIR")"
    _status_kv "İndirilen araçlar" "$(ts_pretty_path "$TS_BIN_DIR")"
    _status_kv "Log" "$(ts_pretty_path "$TS_LOG_FILE")"
    ui_card_bottom
}
