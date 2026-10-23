#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Eylem: git ayarları, dconf anahtarları, giriş kabuğu
# ============================================================================
# Her ayarın ÖNCEKİ değeri ilk değişiklikte deftere yazılır (base64 ile);
# kaldırırken o değere dönülür ya da ayar silinir.
# ============================================================================

TS_GITCONFIG="${TS_GITCONFIG:-$HOME/.gitconfig}"
TS_SHELLS_FILE="${TS_SHELLS_FILE:-/etc/shells}"

# act_gitcfg anahtar değer
act_gitcfg() {
    local key="$1" value="$2" prev
    has_cmd git || { log_err "git bulunamadı"; return 1; }
    if is_dry_run; then
        log_plan "git config --global $key '$value'"
        return 0
    fi
    act_snapshot "$TS_GITCONFIG" || return 1
    if prev=$(git config --global --get "$key" 2>/dev/null); then
        ledger_add gitcfg "$key" "$(ledger_encode "$prev")"
    else
        ledger_add gitcfg "$key" "NONE"
    fi
    git config --global "$key" "$value"
}

# act_dconf_key /yol/anahtar "GVariant-değeri"
act_dconf_key() {
    local key="$1" value="$2" prev
    has_cmd dconf || return 1
    if is_dry_run; then
        log_plan "dconf write $key $value"
        return 0
    fi
    prev=$(dconf read "$key" 2>/dev/null)
    if [[ -n "$prev" ]]; then
        ledger_add dconf "$key" "$(ledger_encode "$prev")"
    else
        ledger_add dconf "$key" "NONE"
    fi
    dconf write "$key" "$value"
}

# Giriş kabuğunu değiştir: act_login_shell /usr/bin/zsh
act_login_shell() {
    local target="$1" current
    current=$(sys_login_shell)
    [[ "$current" == "$target" ]] && return 0
    if is_dry_run; then
        log_plan "chsh -s $target"
        return 0
    fi
    if ! grep -qxF "$target" "$TS_SHELLS_FILE" 2>/dev/null; then
        log_err "$target /etc/shells içinde yok"
        return 1
    fi
    sudo_begin || return 1
    ledger_add shell "$current"
    run_logged as_root chsh -s "$target" "$USER" || {
        log_err "Giriş kabuğu değiştirilemedi"
        return 1
    }
}

# ----------------------------------------------------------------------------
# Geri alma işleyicileri (lib/undo.sh dağıtır)
# ----------------------------------------------------------------------------
undo_gitcfg() {
    local key="$1" prev="$2" section
    has_cmd git || return 0
    is_dry_run && { log_plan "git config geri al: $key"; return 0; }
    if [[ "$prev" == "NONE" ]]; then
        git config --global --unset-all "$key" 2>/dev/null || true
        # Boş kalan bölümü de kaldır ([delta] gibi)
        section="${key%.*}"
        if ! git config --global --get-regexp "^${section//./\\.}\\." >/dev/null 2>&1; then
            git config --global --remove-section "$section" 2>/dev/null || true
        fi
    else
        git config --global "$key" "$(ledger_decode "$prev")"
    fi
}

undo_dconf() {
    local key="$1" prev="$2"
    has_cmd dconf || return 0
    is_dry_run && { log_plan "dconf geri al: $key"; return 0; }
    if [[ "$prev" == "NONE" ]]; then
        dconf reset "$key"
    else
        dconf write "$key" "$(ledger_decode "$prev")"
    fi
}

undo_shell() {
    local orig="$1"
    [[ -n "$orig" && "$(sys_login_shell)" != "$orig" ]] || return 0
    is_dry_run && { log_plan "chsh -s $orig"; return 0; }
    sudo_begin || return 1
    run_logged as_root chsh -s "$orig" "$USER"
}
