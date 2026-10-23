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

# Tüm kontrolleri çalıştır: run_doctor [--fix]
run_doctor() {
    local fix=0 id msg rc warn=0 err=0 fixable=()
    [[ "${1:-}" == "--fix" ]] && fix=1
    ui_title "Sağlık kontrolü"
    for id in "${DIAG_IDS[@]}"; do
        msg=$("diag_${id}_check" 2>/dev/null)
        rc=$?
        case "$rc" in
            0) printf '  %s %s%s\n' "${C_GREEN}✓${C_RESET}" "$(ui_pad "${DIAG_TITLE[$id]}" 20)" "${C_DIM}$msg${C_RESET}" ;;
            1) printf '  %s %s%s\n' "${C_YELLOW}⚠${C_RESET}" "$(ui_pad "${DIAG_TITLE[$id]}" 20)" "$msg"; warn=$((warn + 1)) ;;
            *) printf '  %s %s%s\n' "${C_RED}✗${C_RESET}" "$(ui_pad "${DIAG_TITLE[$id]}" 20)" "$msg"; err=$((err + 1)) ;;
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
    log_info "$err hata, $warn uyarı."
    ((${#fixable[@]} == 0)) && return 1
    if ((fix)) || ui_confirm "Otomatik düzeltilebilen ${#fixable[@]} sorun düzeltilsin mi?" e; then
        for id in "${fixable[@]}"; do
            log_step "Düzeltiliyor: ${DIAG_TITLE[$id]}"
            "diag_${id}_fix" || log_err "${DIAG_TITLE[$id]} düzeltilemedi"
        done
    fi
    return 1
}
