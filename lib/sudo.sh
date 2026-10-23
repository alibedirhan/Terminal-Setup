#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Yönetici yetkisi
# ============================================================================
# Tek bir yenileme döngüsü çalışır; ikinci çağrı yeni döngü açmaz.
# Döngü, script kapanırken (normal çıkış veya Ctrl+C) durdurulur.
# ============================================================================

SUDO_KEEPALIVE_PID=""

# Komutu yönetici olarak çalıştır
as_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

sudo_begin() {
    is_dry_run && return 0
    [[ $EUID -eq 0 ]] && return 0
    if [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
        return 0
    fi
    if ! sudo -n true 2>/dev/null; then
        log_info "Paket işlemleri için yönetici şifreniz gerekiyor."
        sudo -v || { log_err "Yönetici yetkisi alınamadı."; return 1; }
    fi
    local parent=$$
    (
        while kill -0 "$parent" 2>/dev/null; do
            sudo -n true 2>/dev/null || exit 0
            sleep 50
        done
    ) &
    SUDO_KEEPALIVE_PID=$!
    ts_on_exit sudo_end
}

sudo_end() {
    if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
        wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
        SUDO_KEEPALIVE_PID=""
    fi
}
