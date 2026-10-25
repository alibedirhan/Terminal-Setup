#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Teşhis çerçevesi
# ============================================================================
# Her kontrol diagnostics/ altında kendi dosyasındadır:
#
#   diag_register kimlik "Başlık"
#   diag_<kimlik>_check   tek satır mesaj yazar; 0 iyi, 1 uyarı, 2 hata
#   diag_<kimlik>_fix     (isteğe bağlı) sorunu eylemlerle düzeltir
#
# Düzeltmeler de lib/actions/ üzerinden yapılır; yani deftere düşer ve
# kaldırmada geri alınır.
# ============================================================================

declare -ga DIAG_IDS=()
declare -gA DIAG_TITLE=()

diag_register() {
    DIAG_IDS+=("$1")
    DIAG_TITLE[$1]="$2"
}

# Kontrol sonucunu çevirip yazdır (diag_*_check içinde): diag_say "Biçim %s" ARG...
diag_say() {
    _t "$@"
    printf '%s\n' "$TR"
}

# Tüm kontrolleri çalıştır: run_doctor [--fix]
run_doctor() {
    local fix=0 id msg rc title warn=0 err=0 fixable=()
    [[ "${1:-}" == "--fix" ]] && fix=1
    ui_title "Sağlık kontrolü"
    for id in "${DIAG_IDS[@]}"; do
        msg=$("diag_${id}_check" 2>/dev/null)
        rc=$?
        _t "${DIAG_TITLE[$id]}"
        title=$(ui_pad "$TR" 22)
        case "$rc" in
            0) ui_line "  ${U_OK}✓${C_RESET} ${title}${U_MUTED:-$C_DIM}$msg" ;;
            1) ui_line "  ${U_WARN}▲${C_RESET} ${title}$msg"; warn=$((warn + 1)) ;;
            *) ui_line "  ${U_ERR}✗${C_RESET} ${title}$msg"; err=$((err + 1)) ;;
        esac
        if ((rc != 0)) && declare -F "diag_${id}_fix" >/dev/null; then
            fixable+=("$id")
        fi
    done
    printf '\n'
    if ((warn + err == 0)); then
        log_ok "Sorun bulunmadı."
        return 0
    fi
    log_info "%s hata, %s uyarı." "$err" "$warn"
    ((${#fixable[@]} == 0)) && return 1
    if ((fix)) || ui_confirm "Otomatik düzeltilebilen %s sorun düzeltilsin mi?" e "${#fixable[@]}"; then
        for id in "${fixable[@]}"; do
            _t "${DIAG_TITLE[$id]}"
            log_step "Düzeltiliyor: %s" "$TR"
            "diag_${id}_fix" || log_err "%s düzeltilemedi" "$TR"
        done
    fi
    return 1
}
