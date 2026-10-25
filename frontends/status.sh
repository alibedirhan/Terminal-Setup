#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Durum ekranı (CLI ve menü ortak kullanır)
# ============================================================================
# Ağa çıkmaz; yalnızca yerel durum okunur, bu yüzden hızlıdır.
# ============================================================================

# Bileşen durumunu simgeyle göster
status_symbol() {
    case "$1" in
        ours) printf '%s' "${U_OK}●${U_RST} kurulu" ;;
        external) printf '%s' "${U_INFO}●${U_RST} sizde vardı" ;;
        broken) printf '%s' "${U_ERR}●${U_RST} bozuk" ;;
        *) printf '%s' "${U_FAINT}○ yok${U_RST}" ;;
    esac
}

# Kart içinde "Etiket   değer" satırı
_status_kv() { ui_card_row "${U_MUTED}$(ui_pad "$1" 22)${U_RST}$2"; }

status_show() {
    local cat id theme terms=() cells=() col i cw
    ui_title "Terminal Setup $TS_VERSION — durum"
    ui_card_top "Sistem"
    _status_kv "Sistem" "$(sys_os) ($(sys_arch || uname -m))"
    _status_kv "Giriş kabuğu" "$(sys_login_shell)"
    theme=$(settings_get theme)
    if [[ -n "$theme" ]] && theme_load "$theme" >/dev/null 2>&1; then
        _status_kv "Tema" "${U_ACC}●${U_RST} ${THEME[NAME]}"
    else
        _status_kv "Tema" "${U_MUTED}yok${U_RST}"
    fi
    for id in $(renderers_available); do
        [[ "$id" == tmux ]] && continue
        terms+=("${RENDERER_NAME[$id]}")
    done
    _status_kv "Terminaller" "${terms[*]:-bulunamadı}"
    if baseline_exists; then
        _status_kv "Başlangıç fotoğrafı" "$(baseline_created_at)"
        _status_kv "Defter" "$(ledger_count) kayıt"
    else
        _status_kv "Başlangıç fotoğrafı" "${U_MUTED}henüz yok (ilk kurulumda alınır)${U_RST}"
    fi
    ui_card_bottom

    # Bileşenler geniş ekranda iki sütun halinde
    cw=$((UI_W / 2))
    ((UI_W >= 72)) && col=2 || col=1
    for cat in "${COMP_CATEGORIES[@]}"; do
        ui_line ""
        ui_section "${COMP_CAT_LABEL[$cat]}"
        cells=()
        for id in $(component_ids_by_cat "$cat"); do
            cells+=("  $(ui_pad "${COMP_NAME[$id]}" 18)$(status_symbol "$(component_state "$id")")")
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
