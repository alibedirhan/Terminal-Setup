#!/usr/bin/env bash

# ============================================================================
# Terminal Setup - Quick Installer
# v5.0.2
# ============================================================================
# Usage:
#   wget https://raw.githubusercontent.com/alibedirhan/Terminal-Setup/main/install.sh
#   chmod +x install.sh
#   ./install.sh
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

readonly PROJECT_NAME="Terminal Setup"
readonly VERSION="5.0.2"
readonly REPO_RAW_URL="https://raw.githubusercontent.com/alibedirhan/Terminal-Setup/main"
readonly INSTALL_DIR="$HOME/.terminal-setup-installer"
readonly REQUIRED_FILES=(
    "VERSION"
    "terminal-setup.sh"
    "terminal-ui.sh"
    "terminal-assistant.sh"
    "terminal-router.sh"
    "core/terminal-base.sh"
    "core/terminal-tools.sh"
    "core/terminal-config.sh"
    "utils/helpers.sh"
    "utils/system.sh"
    "utils/config.sh"
    "themes/dracula.sh"
    "themes/nord.sh"
    "themes/gruvbox.sh"
    "themes/tokyo-night.sh"
    "themes/catppuccin.sh"
    "themes/one-dark.sh"
    "themes/solarized.sh"
    "aliases/.aliases"
)

log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }

show_banner() {
    clear
    echo -e "${BOLD}${CYAN}"
    cat <<EOF_BANNER
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║                    Terminal Setup                        ║
║                                                           ║
║        Zsh • Oh My Zsh • Powerlevel10k • CLI Tools        ║
║                                                           ║
║                     Quick Installer                       ║
║                       v${VERSION}                         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF_BANNER
    echo -e "${NC}"
}

cleanup_on_error() {
    if [[ -d "$INSTALL_DIR" ]]; then
        log_info "Geçici kurulum dizini temizleniyor..."
        rm -rf -- "$INSTALL_DIR" 2>/dev/null || true
    fi
}

trap cleanup_on_error INT TERM ERR

check_requirements() {
    log_info "Gereksinimler kontrol ediliyor..."

    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        log_error "Bu scripti root olarak çalıştırmayın. Normal kullanıcıyla çalıştırın."
        exit 1
    fi

    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        log_error "curl veya wget bulunamadı. Önce şunu çalıştırın: sudo apt install curl wget"
        exit 1
    fi

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL --connect-timeout 8 "$REPO_RAW_URL/VERSION" >/dev/null; then
            log_error "GitHub raw dosyalarına erişilemiyor. İnternet/VPN/DNS durumunu kontrol edin."
            exit 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q --timeout=8 -O /dev/null "$REPO_RAW_URL/VERSION"; then
            log_error "GitHub raw dosyalarına erişilemiyor. İnternet/VPN/DNS durumunu kontrol edin."
            exit 1
        fi
    fi

    log_success "Gereksinimler tamam"
}

download_one() {
    local file="$1"
    local url="$REPO_RAW_URL/$file"
    local target="$INSTALL_DIR/$file"
    local dir
    dir=$(dirname "$target")
    mkdir -p "$dir"

    echo -ne "${CYAN}↓${NC} $file... "

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL --connect-timeout 10 --retry 2 --retry-delay 2 -o "$target" "$url"; then
            echo -e "${RED}✗${NC}"
            return 1
        fi
    else
        if ! wget -q --timeout=15 --tries=2 -O "$target" "$url"; then
            echo -e "${RED}✗${NC}"
            return 1
        fi
    fi

    if [[ ! -s "$target" ]]; then
        echo -e "${RED}✗${NC} (boş dosya)"
        return 1
    fi

    if grep -q "404: Not Found" "$target" 2>/dev/null; then
        echo -e "${RED}✗${NC} (404)"
        return 1
    fi

    chmod +x "$target" 2>/dev/null || true
    echo -e "${GREEN}✓${NC}"
    return 0
}

download_files() {
    log_info "Dosyalar indiriliyor..."
    rm -rf -- "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"

    local failed=0
    for file in "${REQUIRED_FILES[@]}"; do
        if ! download_one "$file"; then
            failed=$((failed + 1))
        fi
    done

    if [[ $failed -ne 0 ]]; then
        log_error "$failed dosya indirilemedi. Kurulum durduruldu."
        return 1
    fi

    log_success "Tüm dosyalar indirildi"
}

verify_files() {
    log_info "Dosyalar doğrulanıyor..."
    cd "$INSTALL_DIR"

    local file
    for file in "${REQUIRED_FILES[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Eksik dosya: $file"
            return 1
        fi
        if [[ "$file" == *.sh ]]; then
            if ! bash -n "$file"; then
                log_error "Sözdizimi hatası: $file"
                return 1
            fi
        fi
    done

    log_success "Dosya doğrulaması tamam"
}

launch_installer() {
    log_info "Ana kurulum menüsü başlatılıyor..."
    cd "$INSTALL_DIR"
    exec ./terminal-setup.sh
}

main() {
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   Terminal Setup kuruluma hazırlanıyor                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    check_requirements
    echo
    download_files
    echo
    verify_files
    echo
    log_success "Hazır. Menü açılıyor..."
    sleep 1
    trap - INT TERM ERR
    launch_installer
}

main "$@"
