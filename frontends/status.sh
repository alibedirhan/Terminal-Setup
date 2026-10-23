#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Durum ekranı (CLI ve menü ortak kullanır)
# ============================================================================
# Ağa çıkmaz; yalnızca yerel durum okunur, bu yüzden hızlıdır.
# ============================================================================

# Bileşen durumunu simgeyle göster
status_symbol() {
    case "$1" in
        ours) printf '%s' "${C_GREEN}✓ kurulu${C_RESET}" ;;
        external) printf '%s' "${C_BLUE}● sizde vardı${C_RESET}" ;;
        broken) printf '%s' "${C_RED}✗ bozuk${C_RESET}" ;;
        *) printf '%s' "${C_DIM}- yok${C_RESET}" ;;
    esac
}

status_show() {
    local cat id theme terms=()
    ui_title "Terminal Setup $TS_VERSION — durum"
    printf '  %s%s\n' "$(ui_pad "Sistem" 22)" "$(sys_os) ($(sys_arch || uname -m))"
    printf '  %s%s\n' "$(ui_pad "Giriş kabuğu" 22)" "$(sys_login_shell)"
    theme=$(settings_get theme)
    printf '  %s%s\n' "$(ui_pad "Tema" 22)" "${theme:-yok}"
    for id in $(renderers_available); do terms+=("${RENDERER_NAME[$id]}"); done
    printf '  %s%s\n' "$(ui_pad "Terminaller" 22)" "${terms[*]:-bulunamadı}"
    if baseline_exists; then
        printf '  %s%s\n' "$(ui_pad "Başlangıç fotoğrafı" 22)" "$(baseline_created_at)"
        printf '  %s%s\n' "$(ui_pad "Defter" 22)" "$(ledger_count) kayıt"
    else
        printf '  %s%s\n' "$(ui_pad "Başlangıç fotoğrafı" 22)" "henüz yok (ilk kurulumda alınır)"
    fi
    for cat in "${COMP_CATEGORIES[@]}"; do
        printf '\n  %s\n' "${C_BOLD}${COMP_CAT_LABEL[$cat]}${C_RESET}"
        for id in $(component_ids_by_cat "$cat"); do
            printf '    %s%s\n' "$(ui_pad "${COMP_NAME[$id]}" 20)" "$(status_symbol "$(component_state "$id")")"
        done
    done
    printf '\n'
}
