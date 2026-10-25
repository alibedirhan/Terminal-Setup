#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Durum ekranı (CLI ve menü ortak kullanır)
# ============================================================================
# Ağa çıkmaz; yalnızca yerel durum okunur, bu yüzden hızlıdır.
# ============================================================================

# Bileşen durumunu simgeyle göster
status_symbol() {
    case "$1" in
        ours) _t "kurulu"; printf '%s' "${U_OK}●${U_RST} $TR" ;;
        external) _t "sizde vardı"; printf '%s' "${U_INFO}●${U_RST} $TR" ;;
        broken) _t "bozuk"; printf '%s' "${U_ERR}●${U_RST} $TR" ;;
        *) _t "yok"; printf '%s' "${U_FAINT}○ $TR${U_RST}" ;;
    esac
}

_status_system_card() {
    local theme terms=() id
    ui_card_top "Sistem"
    _status_kv "Sistem" "$(sys_os) ($(sys_arch || uname -m))"
    _status_kv "Giriş kabuğu" "$(sys_login_shell)"
    theme=$(settings_get theme)
    if [[ -n "$theme" ]] && theme_load "$theme" >/dev/null 2>&1; then
        _status_kv "Tema" "${U_ACC}●${U_RST} ${THEME[NAME]}"
    else
        _t "yok"
        _status_kv "Tema" "${U_MUTED}${TR}${U_RST}"
    fi
    for id in $(renderers_available terminal); do
        terms+=("${RENDERER_NAME[$id]}")
    done
    _t "bulunamadı"
    _status_kv "Terminaller" "${terms[*]:-$TR}"
    if baseline_exists; then
        _status_kv "Başlangıç fotoğrafı" "$(baseline_created_at)"
        _t "%s kayıt" "$(ledger_count)"
        _status_kv "Defter" "$TR"
    else
        _t "henüz yok (ilk kurulumda alınır)"
        _status_kv "Başlangıç fotoğrafı" "${U_MUTED}${TR}${U_RST}"
    fi
    ui_card_bottom
}

# Kart içinde "Etiket   değer" satırı; etiket çevrilir
_status_kv() {
    _t "$1"
    ui_padr "$TR" 22
    ui_card_row "${U_MUTED}${REPLY}${U_RST}$2"
}

status_show() {
    local cat id cells=() col i cw
    ui_title "Terminal Setup %s — durum" "$TS_VERSION"
    _status_system_card

    # Bileşenler geniş ekranda iki sütun halinde
    cw=$((UI_W / 2))
    ((UI_W >= 72)) && col=2 || col=1
    for cat in "${COMP_CATEGORIES[@]}"; do
        ui_line ""
        ui_section "${COMP_CAT_LABEL[$cat]}"
        cells=()
        for id in $(component_ids_by_cat "$cat"); do
            cells+=("  $(ui_pad "$(comp_label "$id")" 18)$(status_symbol "$(component_state "$id")")")
        done
        for ((i = 0; i < ${#cells[@]}; i += col)); do
            if ((col == 2 && i + 1 < ${#cells[@]})); then
                ui_line "$(ui_pad "${cells[i]}" "$cw")${cells[i + 1]}"
            else
                ui_line "${cells[i]}"
            fi
        done
    done
    ui_line ""
}
