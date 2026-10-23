#!/bin/bash

# ============================================================================
# Terminal Setup - Ana Script (Orchestrator)
# v5.0.0 - Modular architecture refactor
# ============================================================================
# Dosya Yapısı:
#   terminal-setup.sh      (bu dosya - orchestration, ~120 satır)
#   terminal-ui.sh         (görsel arayüz, menüler)
#   terminal-router.sh     (menü yönlendirme, aksiyon mantığı)
#   terminal-assistant.sh  (otomatik teşhis ve çözüm)
#   core/                  (kurulum fonksiyonları)
#   utils/                 (yardımcı fonksiyonlar)
#   themes/                (tema tanımları)
# ============================================================================

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# VERSION dosyasından oku (fallback ile)
if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
    VERSION=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')
else
    VERSION="5.0.2"
fi

# Global değişkenler
BASE_DIR="$HOME/.terminal-setup"
BACKUP_DIR="$BASE_DIR/backups"
LOG_DIR="$BASE_DIR/logs"
CONFIG_DIR="$BASE_DIR/config"
TEMP_DIR=""
CONFIG_FILE="$CONFIG_DIR/settings.conf"
LOG_FILE="$LOG_DIR/terminal-setup.log"

# Flags
DEBUG_MODE=false
VERBOSE_MODE=false
CLEANUP_DONE=false

# Dizinleri oluştur
mkdir -p "$BACKUP_DIR" "$LOG_DIR" "$CONFIG_DIR" || {
    echo "ERROR: Required directories could not be created!"
    exit 1
}

# ============================================================================
# MODÜL YÜKLEME
# ============================================================================

load_modules() {
    local modules=(
        "utils/helpers.sh"           # 1. Logging sistemi (EN ÖNCE!)
        "utils/system.sh"             # 2. Terminal detection, internet
        "utils/config.sh"             # 3. Config, backup, snapshot
        "terminal-ui.sh"              # 4. UI fonksiyonları
        "core/terminal-base.sh"       # 5. Zsh, Oh My Zsh, P10k
        "core/terminal-tools.sh"      # 6. 14 CLI aracı
        "core/terminal-config.sh"     # 7. Tmux, tema uygulama
        "terminal-assistant.sh"       # 8. Diagnostic
        "terminal-router.sh"          # 9. Routing + config + aksiyonlar (SON!)
    )

    for module in "${modules[@]}"; do
        local module_path="$SCRIPT_DIR/$module"
        if [[ -f "$module_path" ]]; then
            # shellcheck source=/dev/null
            if ! source "$module_path"; then
                echo "ERROR: Failed to load module: $module" >&2
                exit 1
            fi
        else
            echo "ERROR: Module not found: $module" >&2
            echo "Expected location: $module_path" >&2
            exit 1
        fi
    done
}

load_modules

log_debug "Terminal Setup v$VERSION başlatıldı"
log_debug "Script dizini: $SCRIPT_DIR"

# ============================================================================
# CLEANUP
# ============================================================================

cleanup() {
    [[ "$CLEANUP_DONE" == true ]] && return 0
    CLEANUP_DONE=true

    log_debug "Cleanup başlatıldı"

    if [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
        log_debug "Temp directory temizlendi: $TEMP_DIR"
    fi

    if type cleanup_sudo &>/dev/null; then
        cleanup_sudo
    fi

    log_debug "Cleanup tamamlandı"
}

trap cleanup EXIT
trap 'echo; log_warning "İptal edildi"; exit 130' INT TERM

# ============================================================================
# ARGÜMAN İŞLEME
# ============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)  show_help; exit 0 ;;
        --version)  echo "Terminal Setup v$VERSION"; exit 0 ;;
        --debug)    DEBUG_MODE=true; log_info "Debug modu aktif"; shift ;;
        --verbose)  VERBOSE_MODE=true; log_info "Verbose mod aktif"; shift ;;
        --health)   show_banner; system_health_check; exit 0 ;;
        --update)   check_for_updates; exit 0 ;;
        *)          log_error "Bilinmeyen parametre: $1"; echo "Yardım için: $0 --help"; exit 1 ;;
    esac
done

# ============================================================================
# ROOT KONTROLÜ
# ============================================================================

if [[ $EUID -eq 0 ]]; then
    log_error "Bu scripti root olarak çalıştırmayın!"
    exit 1
fi

# ============================================================================
# BAŞLATMA
# ============================================================================

TEMP_DIR=$(mktemp -d -t terminal-setup.XXXXXXXXXX) || {
    echo "HATA: Geçici dizin oluşturulamadı!"
    exit 1
}

load_config
validate_config || log_warning "Config validation başarısız, varsayılanlar kullanılıyor"

if [[ "${AUTO_UPDATE:-false}" == "true" ]]; then
    check_for_updates --silent
fi

# İlk açılış animasyonu
show_animated_banner
sleep 1

# ============================================================================
# ANA PROGRAM DÖNGÜSÜ
# ============================================================================

while true; do
    show_banner
    show_menu
    read -r choice
    route_choice "$choice"
done
