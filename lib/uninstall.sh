#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Kaldırma senaryoları
# ============================================================================
# İki seviye:
#   Görünümü sıfırla  tema ve terminal renkleri eski haline döner; araçlar kalır
#   Tamamen kaldır    defterin tamamı geri alınır, sistem kurulum öncesine döner
#
# Silinmeyen tek şey arşiv klasörüdür (~/terminal-setup-kaldirilan-TARİH):
# kullanımla oluşan veriler (komut geçmişi, prompt ayarı), kurulumdan sonra
# değiştirdiğiniz dosyaların son hali ve kaldırma raporu oraya konur.
# ============================================================================

# Kaldırmada ne yapılacağını göster (hiçbir şey değiştirmez)
uninstall_show_plan() {
    local saved="$TS_DRY_RUN" ext
    ui_title "Kaldırma planı"
    TS_DRY_RUN=1
    ledger_lines | undo_lines
    TS_DRY_RUN="$saved"
    ext=$(ledger_lines | awk -F'\t' '$2 == "note" && $3 ~ /^external:/ { sub(/^external:/, "", $3); print $3 }')
    if [[ -n "$ext" ]]; then
        _t "Dokunulmayacak"
        printf '\n%s' "${C_BOLD}${TR}${C_RESET}"
        _t "(kurulumdan önce sizde vardı):"
        printf ' %s\n' "$TR"
        printf '  %s\n' $ext
    fi
}

uninstall_all() {
    if ! ledger_exists || (( $(ledger_count) == 0 )); then
        if legacy_detect; then
            legacy_uninstall
            return $?
        fi
        log_info "Kaldırılacak bir şey yok: Terminal Setup bu sistemde bir değişiklik kaydetmemiş."
        return 0
    fi

    uninstall_show_plan
    if is_dry_run; then
        _t "Prova modu: hiçbir şey değiştirilmedi."
        printf '\n%s\n' "${C_DIM}${TR}${C_RESET}"
        return 0
    fi
    printf '\n'
    ui_type_confirm "kaldır" || { log_info "İptal edildi."; return 1; }

    sudo_begin || return 1
    undo_archive_init
    UNDO_FAILED=0
    log_step "Değişiklikler geri alınıyor"
    ledger_lines | undo_lines
    undo_rcfile_gc
    # İkinci tur: ortak dizinler ve core'a devredilen kayıtlar
    ledger_lines | undo_lines
    undo_rcfile_gc

    printf '\n'
    local report="$TS_ARCHIVE_DIR/kaldirma-raporu.txt"
    verify_against_baseline | tee "$report"
    local verdict=${PIPESTATUS[0]}
    sed -i 's/\x1b\[[0-9;]*m//g' "$report"
    cp -f "$TS_LOG_FILE" "$TS_ARCHIVE_DIR/terminal-setup.log" 2>/dev/null || true

    if (( $(ledger_count) == 0 )); then
        TS_LOG_FILE="$TS_ARCHIVE_DIR/terminal-setup.log"
        rm -rf -- "$TS_STATE_DIR"
    else
        log_warn "Bazı kayıtlar geri alınamadı; defter korunuyor: %s" "$(ts_pretty_path "$TS_LEDGER")"
    fi

    printf '\n'
    log_ok "Kaldırma tamamlandı."
    log_info "Arşiv: %s (rapor, log ve kullanıcı verileri)" "$(ts_pretty_path "$TS_ARCHIVE_DIR")"
    if ((${#UNDO_ARCHIVED[@]} > 0)); then
        log_info "Arşive taşınanlar: %s" "${UNDO_ARCHIVED[*]}"
    fi
    log_info "Değişikliklerin tamamı için terminali kapatıp yeniden açın."
    return "$verdict"
}

# Görünümü sıfırla: tema kayıtlarını geri al; istenirse prompt ayarını da
appearance_reset() {
    if ! ledger_component_has_entries theme; then
        log_info "Uygulanmış bir tema yok."
    else
        log_step "Tema geri alınıyor"
        undo_component theme
        settings_set theme ""
        log_ok "Terminal renkleri kurulum öncesine döndü."
    fi
    if [[ -f "$HOME/.p10k.zsh" ]] && ledger_has userdata "$HOME/.p10k.zsh"; then
        if ui_confirm "Powerlevel10k prompt görünümü de sıfırlansın mı? (sihirbaz yeniden açılır)" h; then
            undo_userdata "$HOME/.p10k.zsh"
            log_ok "Prompt ayarı arşive taşındı: %s" "$(ts_pretty_path "$TS_ARCHIVE_DIR")"
            log_info "Yeni bir terminal açtığınızda Powerlevel10k sihirbazı başlar."
        fi
    fi
}
