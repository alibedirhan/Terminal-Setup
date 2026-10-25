#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: ayarlar
# ============================================================================

tui_settings() {
    local profiles=() items=() p upd cur_profile cur_upd cur_lang
    while true; do
        upd=$(settings_get update_check on)
        _t "Şu an: %s" "$(settings_get default_profile developer)"
        cur_profile="$TR"
        _t "$upd"
        _t "Açılışta GitHub'a bakılsın mı? Şu an: %s" "$TR"
        cur_upd="$TR"
        _tui_language_name "$(settings_get language auto)"
        _t "Şu an: %s" "$TR"
        cur_lang="$TR"
        ui_menu "Ayarlar" \
            "Dil / Language|$cur_lang|▸" \
            "Varsayılan profil|$cur_profile|▸" \
            "Güncelleme kontrolü|$cur_upd|▸" \
            "Şimdi güncelleme ara||▸" \
            "Dosya konumları|Defter, fotoğraf, log nerede|▸" || return 0
        case "$UI_CHOICE" in
            0) tui_language ;;
            1)
                mapfile -t profiles < <(profile_list)
                items=()
                for p in "${profiles[@]}"; do items+=("$p|$(profile_description "$p")|▸"); done
                ui_menu "Varsayılan profil" "${items[@]}" && settings_set default_profile "${profiles[UI_CHOICE]}" ;;
            2) if [[ "$upd" == on ]]; then settings_set update_check off; else settings_set update_check on; fi ;;
            3) tui_run tui_update_check ;;
            4) tui_run tui_paths ;;
        esac
    done
}

tui_update_check() {
    update_check || log_ok "Güncel sürümdesiniz (%s)." "$TS_VERSION"
}

LANGUAGE_CHOICES=(auto tr en)

# Dil ayarının görünen adı -> TR: _tui_language_name auto|tr|en
_tui_language_name() {
    case "$1" in
        tr) TR="Türkçe" ;;
        en) TR="English" ;;
        *) _t "Sistem diline göre" ;;
    esac
}

tui_language() {
    _tui_language_name auto
    ui_menu "Dil / Language" "$TR|LANG=${LANG:-?}|▸" "Türkçe||▸" "English||▸" || return 0
    settings_set language "${LANGUAGE_CHOICES[UI_CHOICE]}"
    i18n_init "${LANGUAGE_CHOICES[UI_CHOICE]}"
    UI_HEADER_STALE=1
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
