#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - v5 ve öncesi kurulumların temizliği
# ============================================================================
# v5 değişiklik defteri tutmuyordu; neyin script'ten önce var olduğu
# bilinemez. Bu yüzden burada hiçbir şey otomatik silinmez: v5'in bilinen
# kurulum yerleri taranır, bulunanlar kategori kategori gösterilir ve her
# kategori için ayrı onay istenir. Kullanıcı verileri silinmez, arşivlenir.
# ============================================================================

LEGACY_DIR="$TS_STATE_DIR"

# v5 izi var mı? Yalnızca v5'in kendi durum dizinine bakılır; sistemde
# lazygit, fzf gibi araçların bulunması v5'in kurduğu anlamına gelmez.
legacy_detect() {
    ledger_exists && return 1
    [[ -d "$LEGACY_DIR/backups" || -f "$LEGACY_DIR/config/settings.conf" ]]
}

_legacy_existing() {
    local p
    for p in "$@"; do
        [[ -e "$p" ]] && echo "$p"
    done
}

_legacy_step() {
    local title="$1"
    shift
    (($# == 0)) && return 1
    printf '\n%s\n' "${C_BOLD}$title${C_RESET}"
    printf '  %s\n' "$@"
    # Prova modunda yalnızca listelenir, soru sorulmaz
    is_dry_run && return 1
    ui_confirm "Bunlar kaldırılsın mı?" e
}

legacy_uninstall() {
    local -a items pkgs=() p
    ui_title "v5 kurulumu temizliği"
    log_info "Bu sistemde eski bir Terminal Setup (v5 veya öncesi) kurulumu bulundu."
    log_info "v5 neyin önceden var olduğunu kaydetmediği için her adım ayrıca sorulur."
    is_dry_run && { log_info "Prova modu: yalnızca bulunanlar listelenir."; }

    mapfile -t items < <(_legacy_existing "$HOME/.oh-my-zsh" "$HOME/.fzf" "$HOME/.fzf.zsh" "$HOME/.atuin" \
        "$HOME/.ripgreprc" "$HOME/.local/bin/zoxide" "$TS_FONT_DIR"/MesloLGS*.ttf)
    if _legacy_step "Kullanıcı dizinindeki v5 dosyaları" "${items[@]}" && ! is_dry_run; then
        for p in "${items[@]}"; do undo_path "$p"; done
        act_font_cache
    fi

    mapfile -t items < <(_legacy_existing /usr/local/bin/{lazygit,eza,dust,delta,procs,atuin})
    if _legacy_step "v5'in /usr/local/bin altına kurduğu araçlar" "${items[@]}" && ! is_dry_run; then
        sudo_begin && for p in "${items[@]}"; do run_logged as_root rm -f -- "$p"; done
    fi

    mapfile -t items < <(_legacy_existing "$HOME/.zsh_history" "$HOME/.p10k.zsh" "$HOME/.zshrc" "$HOME/.tmux.conf")
    if _legacy_step "Ayar ve geçmiş dosyaları (silinmez, arşive taşınır)" "${items[@]}" && ! is_dry_run; then
        for p in "${items[@]}"; do fs_archive "$p" "taşı"; done
        # v5'in kurulum öncesi .zshrc yedeği varsa geri koy
        p=$(find "$LEGACY_DIR/backups" -name zshrc -path '*pre_install*' 2>/dev/null | sort | head -1)
        [[ -n "$p" ]] && cp -p "$p" "$HOME/.zshrc" && log_ok "$(ts_pretty_path "$HOME/.zshrc") v5 öncesi yedeğinden geri yüklendi"
    fi

    if has_cmd git && [[ "$(git config --global --get core.pager 2>/dev/null)" == "delta" ]]; then
        if _legacy_step "v5'in eklediği git ayarları" core.pager interactive.diffFilter "delta.*" && ! is_dry_run; then
            git config --global --unset core.pager
            git config --global --unset interactive.diffFilter
            git config --global --remove-section delta 2>/dev/null
        fi
    fi

    if [[ "$(sys_login_shell)" == */zsh ]] && _legacy_step "Giriş kabuğu" "zsh -> /bin/bash" && ! is_dry_run; then
        sudo_begin && run_logged as_root chsh -s /bin/bash "$USER"
    fi

    for p in zsh tmux bat ripgrep fd-find btop duf du-dust tldr git-delta eza fonts-powerline; do
        pkg_installed "$p" && pkgs+=("$p")
    done
    if ((${#pkgs[@]} > 0)); then
        printf '\n%s\n  %s\n' "${C_BOLD}v5'in kurmuş olabileceği paketler${C_RESET}" "${pkgs[*]}"
        log_warn "Bu paketleri v5'ten önce kendiniz kurmuş olabilirsiniz."
        if ! is_dry_run && ui_confirm "Paketler kaldırılsın mı?" h; then
            sudo_begin && run_logged as_root env DEBIAN_FRONTEND=noninteractive apt-get purge -y -q "${pkgs[@]}"
        fi
    fi

    if [[ -d "$LEGACY_DIR" ]] && _legacy_step "v5 durum dizini (yedekler arşive taşınır)" "$LEGACY_DIR" && ! is_dry_run; then
        fs_archive "$LEGACY_DIR" "taşı"
    fi
    is_dry_run || log_ok "v5 temizliği tamamlandı. Arşiv: $(ts_pretty_path "${TS_ARCHIVE_DIR:-yok}")"
}
