#!/bin/bash

# ============================================================================
# Smart Release Manager v2.0
# GitHub release'lerini yönet
# ============================================================================

set -euo pipefail

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Config
REPO="alibedirhan/Terminal-Setup"

# ============================================================================
# YARDIM
# ============================================================================

show_help() {
    cat << 'EOF'
Smart Release Manager v2.0

KULLANIM:
  ./smart-release-manager.sh [KOMUT] [VERSION]

KOMUTLAR:
  create VERSION       Yeni release oluştur
  update VERSION       Mevcut release'i güncelle
  delete VERSION       Release'i sil
  list                 Tüm release'leri listele
  view VERSION         Release detaylarını göster

ÖRNEKLER:
  # Yeni release oluştur (CHANGELOG'dan notes alır)
  ./smart-release-manager.sh create v4.3.1
  
  # Release notes güncelle
  ./smart-release-manager.sh update v4.3.1
  
  # Release'leri listele
  ./smart-release-manager.sh list
  
  # Release sil
  ./smart-release-manager.sh delete v3.2.5

NOTLAR:
  • CHANGELOG.md'den otomatik release notes oluşturur
  • GitHub CLI (gh) gereklidir
  • GitHub'a giriş yapılmış olmalı (gh auth login)

KURULUM:
  # GitHub CLI kur
  Ubuntu/Debian:  sudo apt install gh
  macOS:          brew install gh
  
  # GitHub'a giriş yap
  gh auth login

EOF
}

# ============================================================================
# YARDIMCI FONKSİYONLAR
# ============================================================================

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*" >&2; }
log_warning() { echo -e "${YELLOW}[!]${NC} $*"; }

check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) kurulu değil"
        echo
        echo "Kurulum:"
        echo "  Ubuntu/Debian: sudo apt install gh"
        echo "  macOS: brew install gh"
        echo "  Diğer: https://cli.github.com/"
        return 1
    fi
    return 0
}

check_auth() {
    if ! gh auth status &> /dev/null; then
        log_error "GitHub'a giriş yapılmamış"
        echo
        echo "Giriş yapmak için:"
        echo "  gh auth login"
        echo
        echo "Veya bu script otomatik başlatabilir:"
        echo -ne "Giriş yapmak ister misiniz? (e/h): "
        read -r choice
        
        if [[ "$choice" =~ ^[eE]$ ]]; then
            gh auth login
        else
            return 1
        fi
    fi
    
    local username
    username=$(gh api user --jq .login 2>/dev/null)
    log_success "Giriş: $username"
    return 0
}

extract_changelog_notes() {
    local version=$1
    version=${version#v}  # v4.3.1 → 4.4.0
    
    if [[ ! -f "CHANGELOG.md" ]]; then
        log_warning "CHANGELOG.md bulunamadı"
        echo "Release v${version}"
        return
    fi
    
    # CHANGELOG'dan ilgili versiyonun notlarını çıkar
    local notes
    notes=$(awk -v ver="$version" '
        /^## \['"$version"'\]/ { found=1; next }
        found && /^## \[/ { exit }
        found && NF { print }
    ' CHANGELOG.md)
    
    if [[ -n "$notes" ]]; then
        echo "$notes"
    else
        log_warning "CHANGELOG'da v${version} bulunamadı"
        echo "Release v${version}"
    fi
}

# ============================================================================
# KOMUTLAR
# ============================================================================

cmd_list() {
    log_info "Release'ler listeleniyor..."
    echo
    
    local releases
    releases=$(gh release list --repo "$REPO" --limit 20 2>/dev/null)
    
    if [[ -z "$releases" ]]; then
        log_warning "Henüz release yok"
        return 0
    fi
    
    # Tablo başlığı
    printf "${BOLD}%-15s %-40s %-12s${NC}\n" "VERSION" "TITLE" "STATUS"
    echo "─────────────────────────────────────────────────────────────────────"
    
    # Release'leri yazdır
    echo "$releases" | while IFS=$'\t' read -r tag title status date; do
        local color="${GREEN}"
        [[ "$status" == "Draft" ]] && color="${YELLOW}"
        [[ "$status" == "Pre-release" ]] && color="${CYAN}"
        
        printf "%-15s %-40s ${color}%-12s${NC}\n" "$tag" "${title:0:40}" "$status"
    done
    
    echo
}

cmd_view() {
    local version=$1
    
    if [[ -z "$version" ]]; then
        log_error "Versiyon belirtilmedi"
        echo "Kullanım: $0 view VERSION"
        return 1
    fi
    
    log_info "Release bilgileri: $version"
    echo
    
    gh release view "$version" --repo "$REPO" 2>/dev/null || {
        log_error "Release bulunamadı: $version"
        return 1
    }
}

cmd_create() {
    local version=$1
    
    if [[ -z "$version" ]]; then
        log_error "Versiyon belirtilmedi"
        echo "Kullanım: $0 create VERSION"
        return 1
    fi
    
    log_info "Release oluşturuluyor: $version"
    echo
    
    # CHANGELOG'dan notes al
    local notes
    notes=$(extract_changelog_notes "$version")
    
    # Önizleme
    echo -e "${DIM}Release notes:${NC}"
    echo "─────────────────────────────────────────────"
    echo "$notes" | head -20
    echo "─────────────────────────────────────────────"
    echo
    
    echo -ne "Devam? (e/h): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[eE]$ ]]; then
        log_warning "İptal edildi"
        return 0
    fi
    
    # Release oluştur
    if gh release create "$version" \
        --repo "$REPO" \
        --title "Release $version" \
        --notes "$notes" 2>/dev/null; then
        
        log_success "Release oluşturuldu!"
        log_info "https://github.com/${REPO}/releases/tag/${version}"
    else
        log_error "Release oluşturulamadı"
        log_info "Tag var mı kontrol edin: git tag"
        return 1
    fi
}

cmd_update() {
    local version=$1
    
    if [[ -z "$version" ]]; then
        log_error "Versiyon belirtilmedi"
        echo "Kullanım: $0 update VERSION"
        return 1
    fi
    
    log_info "Release güncelleniyor: $version"
    echo
    
    # Mevcut release var mı kontrol et
    if ! gh release view "$version" --repo "$REPO" &>/dev/null; then
        log_error "Release bulunamadı: $version"
        log_info "Mevcut release'ler:"
        cmd_list
        return 1
    fi
    
    # CHANGELOG'dan yeni notes al
    local notes
    notes=$(extract_changelog_notes "$version")
    
    # Önizleme
    echo -e "${DIM}Yeni release notes:${NC}"
    echo "─────────────────────────────────────────────"
    echo "$notes" | head -20
    echo "─────────────────────────────────────────────"
    echo
    
    echo -ne "Güncelle? (e/h): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[eE]$ ]]; then
        log_warning "İptal edildi"
        return 0
    fi
    
    # Güncelle
    if gh release edit "$version" \
        --repo "$REPO" \
        --notes "$notes" 2>/dev/null; then
        
        log_success "Release güncellendi!"
        log_info "https://github.com/${REPO}/releases/tag/${version}"
    else
        log_error "Güncelleme başarısız"
        return 1
    fi
}

cmd_delete() {
    local version=$1
    
    if [[ -z "$version" ]]; then
        log_error "Versiyon belirtilmedi"
        echo "Kullanım: $0 delete VERSION"
        return 1
    fi
    
    log_warning "Release silinecek: $version"
    echo
    echo -ne "${RED}${BOLD}Emin misiniz? (e/h): ${NC}"
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[eE]$ ]]; then
        log_info "İptal edildi"
        return 0
    fi
    
    if gh release delete "$version" --repo "$REPO" --yes 2>/dev/null; then
        log_success "Release silindi"
    else
        log_error "Silme başarısız"
        return 1
    fi
}

# ============================================================================
# İNTERAKTİF MOD
# ============================================================================

show_banner() {
    clear
    echo -e "${BOLD}${MAGENTA}"
    
    # Banner çizgileri
    local lines=(
        "╔══════════════════════════════════════════════════════════════╗"
        "║                                                              ║"
        "║    ██████╗ ███████╗██╗     ███████╗ █████╗ ███████╗███████╗ ║"
        "║    ██╔══██╗██╔════╝██║     ██╔════╝██╔══██╗██╔════╝██╔════╝ ║"
        "║    ██████╔╝█████╗  ██║     █████╗  ███████║███████╗█████╗   ║"
        "║    ██╔══██╗██╔══╝  ██║     ██╔══╝  ██╔══██║╚════██║██╔══╝   ║"
        "║    ██║  ██║███████╗███████╗███████╗██║  ██║███████║███████╗ ║"
        "║    ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝ ║"
        "║                                                              ║"
        "║              Smart Release Manager v2.0                      ║"
        "║              GitHub Release Yönetimi                         ║"
        "║                                                              ║"
        "╚══════════════════════════════════════════════════════════════╝"
    )
    
    # Animasyonlu banner
    for line in "${lines[@]}"; do
        echo -e "$line"
        sleep 0.03
    done
    
    echo -e "${NC}"
}

show_help_interactive() {
    clear
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}                         ${BOLD}YARDIM${NC}                               ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BOLD}Bu program ne yapar?${NC}"
    echo "  GitHub release'lerini oluşturur, günceller ve yönetir."
    echo "  CHANGELOG.md'den otomatik release notes oluşturur."
    echo
    echo -e "${BOLD}Komut satırı kullanımı:${NC}"
    echo -e "  ${CYAN}./smart-release-manager.sh list${NC}           → Release'leri listele"
    echo -e "  ${CYAN}./smart-release-manager.sh create v4.3.1${NC}  → Yeni release oluştur"
    echo -e "  ${CYAN}./smart-release-manager.sh update v4.3.1${NC}  → Release'i güncelle"
    echo -e "  ${CYAN}./smart-release-manager.sh view v4.3.1${NC}    → Release detayları"
    echo -e "  ${CYAN}./smart-release-manager.sh delete v3.2.5${NC}  → Release sil"
    echo
    echo -e "${BOLD}Gereksinimler:${NC}"
    echo "  • GitHub CLI (gh) kurulu olmalı"
    echo "  • GitHub'a giriş yapılmış olmalı (gh auth login)"
    echo "  • CHANGELOG.md dosyası (release notes için)"
    echo
    echo -e "${BOLD}GitHub CLI Kurulumu:${NC}"
    echo -e "  Ubuntu/Debian: ${DIM}sudo apt install gh${NC}"
    echo -e "  macOS:         ${DIM}brew install gh${NC}"
    echo -e "  Diğer:         ${DIM}https://cli.github.com/${NC}"
    echo
    echo -e "${BOLD}İpuçları:${NC}"
    echo "  • CHANGELOG.md'de versiyon başlığı olmalı: ## [4.4.0]"
    echo "  • Release oluşturmadan önce git tag oluşturun"
    echo "  • Release notes önizleme yapılır, onaylamanız gerekir"
    echo
    echo -e "${DIM}Detaylı yardım: ./smart-release-manager.sh --help${NC}"
    echo
}

interactive_mode() {
    while true; do
        show_banner
        
        # Kullanıcı bilgisi animasyonlu
        echo -ne "${DIM}Kontrol ediliyor"
        for i in {1..3}; do
            sleep 0.1
            echo -n "."
        done
        echo -ne "\r                    \r"
        
        if gh auth status &> /dev/null; then
            local username
            username=$(gh api user --jq .login 2>/dev/null)
            echo -e "${GREEN}[✓]${NC} Giriş: ${BOLD}${username}${NC}"
        else
            echo -e "${YELLOW}[!]${NC} Giriş yapılmadı"
        fi
        
        echo
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}ANA MENÜ${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "  ${GREEN}1)${NC} ${BOLD}Release'leri listele${NC}"
        echo -e "  ${GREEN}2)${NC} ${BOLD}Yeni release oluştur${NC}"
        echo -e "  ${GREEN}3)${NC} ${BOLD}Release güncelle${NC}"
        echo -e "  ${GREEN}4)${NC} ${BOLD}Release detaylarını göster${NC}"
        echo -e "  ${GREEN}5)${NC} ${BOLD}Release sil${NC}"
        echo -e "  ${GREEN}6)${NC} ${BOLD}Yardım${NC} ${DIM}(nasıl kullanılır?)${NC}"
        echo -e "  ${GREEN}0)${NC} Çıkış"
        echo
        echo -ne "${BOLD}Seçim (0-6): ${NC}"
        read -r choice
        
        echo
        
        case $choice in
            0)
                # Çıkış animasyonu
                echo -ne "${CYAN}Çıkış yapılıyor"
                for i in {1..3}; do
                    sleep 0.2
                    echo -n "."
                done
                echo -e "${NC}"
                exit 0
                ;;
            1)
                cmd_list
                echo
                read -p "Devam için Enter'a basın..."
                ;;
            2)
                echo -ne "Versiyon (örn: v4.3.1): "
                read -r version
                echo
                cmd_create "$version"
                echo
                read -p "Devam için Enter'a basın..."
                ;;
            3)
                cmd_list
                echo
                echo -ne "Güncellenecek versiyon: "
                read -r version
                echo
                cmd_update "$version"
                echo
                read -p "Devam için Enter'a basın..."
                ;;
            4)
                echo -ne "Versiyon: "
                read -r version
                echo
                cmd_view "$version"
                echo
                read -p "Devam için Enter'a basın..."
                ;;
            5)
                cmd_list
                echo
                echo -ne "Silinecek versiyon: "
                read -r version
                echo
                cmd_delete "$version"
                echo
                read -p "Devam için Enter'a basın..."
                ;;
            6)
                show_help_interactive
                read -p "Devam için Enter'a basın..."
                ;;
            *)
                log_error "Geçersiz seçim!"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# ANA PROGRAM
# ============================================================================

main() {
    # --help kontrolü
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    # GitHub CLI kontrol
    if ! check_gh_cli; then
        exit 1
    fi
    
    # Auth kontrol
    if ! check_auth; then
        exit 1
    fi
    
    echo
    
    # Komut parse
    local command=${1:-}
    local version=${2:-}
    
    case $command in
        list)
            cmd_list
            ;;
        view)
            cmd_view "$version"
            ;;
        create)
            cmd_create "$version"
            ;;
        update)
            cmd_update "$version"
            ;;
        delete)
            cmd_delete "$version"
            ;;
        "")
            interactive_mode
            ;;
        *)
            log_error "Bilinmeyen komut: $command"
            echo
            echo "Yardım: $0 --help"
            exit 1
            ;;
    esac
}

main "$@"
