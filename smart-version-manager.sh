#!/bin/bash

# ============================================================================
# Smart Version Manager v2.0
# Proje versiyonunu tek komutla güncelle
# ============================================================================

set -euo pipefail

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Config
REPO="alibedirhan/Terminal-Setup"
VERSION_FILE="VERSION"

# Güncellenecek dosyalar
declare -A FILES_TO_UPDATE=(
    ["install.sh"]='v[0-9]+\.[0-9]+\.[0-9]+'
    ["terminal-setup.sh"]='v[0-9]+\.[0-9]+\.[0-9]+'
    ["terminal-ui.sh"]='v[0-9]+\.[0-9]+\.[0-9]+'
    ["terminal-assistant.sh"]='v[0-9]+\.[0-9]+\.[0-9]+'
    ["core/terminal-base.sh"]='v[0-9]+\.[0-9]+\.[0-9]+'
    ["core/terminal-tools.sh"]='v[0-9]+\.[0-9]+\.[0-9]+'
    ["core/terminal-config.sh"]='v[0-9]+\.[0-9]+\.[0-9]+'
    ["utils/helpers.sh"]='v[0-9]+\.[0-9]+\.[0-9]+'
    ["utils/system.sh"]='v[0-9]+\.[0-9]+\.[0-9]+'
    ["utils/config.sh"]='v[0-9]+\.[0-9]+\.[0-9]+'
    ["README.md"]='[vV]?[0-9]+\.[0-9]+\.[0-9]+'
)

# ============================================================================
# YARDIM
# ============================================================================

show_help() {
    cat << 'EOF'
Smart Version Manager v2.0

KULLANIM:
  ./smart-version-manager.sh [VERSION] [BAYRAKLAR]

ÖRNEKLER:
  # Direkt versiyon belirt
  ./smart-version-manager.sh 4.4.0
  
  # Otomatik artır
  ./smart-version-manager.sh --patch      # 4.3.1 → 4.3.2 (küçük düzeltmeler)
  ./smart-version-manager.sh --minor      # 4.3.1 → 4.4.0  (yeni özellikler)
  ./smart-version-manager.sh --major      # 4.3.1 → 4.0.0  (büyük değişiklikler)
  
  # GitHub release ile birlikte
  ./smart-version-manager.sh 4.4.0 --release
  ./smart-version-manager.sh --minor --release

  # İnteraktif mod (eski usul)
  ./smart-version-manager.sh

BAYRAKLAR:
  --patch         Patch versiyonu artır (X.Y.Z → X.Y.Z+1)
  --minor         Minor versiyonu artır (X.Y.Z → X.Y+1.0)
  --major         Major versiyonu artır (X.Y.Z → X+1.0.0)
  --release       GitHub release oluştur
  --no-commit     Git commit atla
  --no-push       Git push atla
  --help, -h      Bu yardımı göster

NE YAPAR?
  ✓ VERSION dosyasını günceller
  ✓ Tüm script dosyalarındaki versiyonları değiştirir
  ✓ README.md'yi günceller
  ✓ Git commit + push yapar
  ✓ (İstersen) GitHub tag oluşturur
  ✓ (İstersen) GitHub release yayınlar

HANGİ DOSYALARI GÜNCELLİYOR?
  • VERSION
  • install.sh
  • terminal-setup.sh, terminal-ui.sh, terminal-assistant.sh
  • core/terminal-base.sh, terminal-tools.sh, terminal-config.sh
  • utils/helpers.sh, system.sh, config.sh
  • README.md

SEMANTIC VERSIONING:
  MAJOR.MINOR.PATCH
  
  • MAJOR (1.0.0 → 2.0.0): Breaking changes, büyük yenilikler
  • MINOR (1.0.0 → 1.1.0): Yeni özellikler, geriye uyumlu
  • PATCH (1.0.0 → 1.0.1): Hata düzeltmeleri

İPUÇLARI:
  • Küçük bug fix → --patch
  • Yeni özellik → --minor
  • Breaking change → --major
  • Release yapmak istiyorsan → --release ekle
  • CHANGELOG.md'yi önce güncelle (release notes için)

EOF
}

# ============================================================================
# YARDIMCI FONKSİYONLAR
# ============================================================================

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*" >&2; }
log_warning() { echo -e "${YELLOW}[!]${NC} $*"; }

get_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE" | tr -d '[:space:]'
    else
        echo "0.0.0"
    fi
}

validate_version() {
    local version=$1
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Geçersiz versiyon formatı: $version"
        log_error "Beklenen: MAJOR.MINOR.PATCH (örn: 4.4.0)"
        return 1
    fi
    return 0
}

bump_version() {
    local current=$1
    local type=$2
    
    IFS='.' read -r major minor patch <<< "$current"
    
    case $type in
        major)
            echo "$((major + 1)).0.0"
            ;;
        minor)
            echo "${major}.$((minor + 1)).0"
            ;;
        patch)
            echo "${major}.${minor}.$((patch + 1))"
            ;;
        *)
            echo "$current"
            ;;
    esac
}

# ============================================================================
# VERSİYON GÜNCELLEME
# ============================================================================

update_version_in_file() {
    local file=$1
    local old_version=$2
    local new_version=$3
    local pattern=$4
    
    if [[ ! -f "$file" ]]; then
        log_warning "Dosya bulunamadı: $file"
        return 1
    fi
    
    # Regex ile değiştir
    if sed -i.bak -E "s/${pattern}/${new_version}/g" "$file" 2>/dev/null; then
        rm -f "${file}.bak"
        return 0
    else
        log_warning "Güncelleme başarısız: $file"
        return 1
    fi
}

update_all_versions() {
    local new_version=$1
    local old_version
    old_version=$(get_current_version)
    
    log_info "Versiyon güncelleniyor: $old_version → $new_version"
    echo
    
    # VERSION dosyası
    echo "$new_version" > "$VERSION_FILE"
    log_success "VERSION"
    
    # Diğer dosyalar
    local success=0
    local failed=0
    
    for file in "${!FILES_TO_UPDATE[@]}"; do
        local pattern="${FILES_TO_UPDATE[$file]}"
        
        if update_version_in_file "$file" "$old_version" "v$new_version" "$pattern"; then
            log_success "$file"
            ((success++))
        else
            ((failed++))
        fi
    done
    
    # Tema dosyaları
    if ls themes/*.sh &>/dev/null; then
        for theme in themes/*.sh; do
            if update_version_in_file "$theme" "$old_version" "v$new_version" 'v[0-9]+\.[0-9]+\.[0-9]+'; then
                log_success "$theme"
                ((success++))
            fi
        done
    fi
    
    echo
    log_success "Güncelleme tamamlandı ($success başarılı, $failed başarısız)"
}

# ============================================================================
# GİT İŞLEMLERİ
# ============================================================================

git_commit_and_push() {
    local version=$1
    local do_push=${2:-true}
    
    log_info "Git işlemleri..."
    
    if ! git rev-parse --git-dir &> /dev/null; then
        log_warning "Git repository değil, atlanıyor"
        return 0
    fi
    
    # Add
    git add .
    
    # Commit
    git commit -m "chore: bump version to v${version}

- Updated VERSION file
- Updated all script files
- Updated documentation

Generated by Smart Version Manager v2.0" || {
        log_warning "Commit başarısız (belki değişiklik yok?)"
        return 1
    }
    
    log_success "Commit yapıldı"
    
    # Push
    if [[ "$do_push" == "true" ]]; then
        local branch
        branch=$(git branch --show-current 2>/dev/null || echo "main")
        
        if git push origin "$branch" 2>/dev/null; then
            log_success "Push yapıldı ($branch)"
        else
            log_warning "Push başarısız"
            log_info "Manuel push: git push origin $branch"
            return 1
        fi
    fi
    
    return 0
}

create_git_tag() {
    local version=$1
    
    log_info "Git tag oluşturuluyor..."
    
    if git tag "v${version}" 2>/dev/null; then
        log_success "Tag oluşturuldu: v${version}"
        
        if git push origin "v${version}" 2>/dev/null; then
            log_success "Tag push edildi"
        else
            log_warning "Tag push edilemedi"
            log_info "Manuel push: git push origin v${version}"
        fi
    else
        log_warning "Tag zaten var veya oluşturulamadı"
    fi
}

# ============================================================================
# GITHUB RELEASE
# ============================================================================

create_github_release() {
    local version=$1
    
    log_info "GitHub release oluşturuluyor..."
    
    # GitHub CLI kontrolü
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) kurulu değil"
        log_info "Kurulum: https://cli.github.com/"
        return 1
    fi
    
    # Auth kontrolü
    if ! gh auth status &> /dev/null; then
        log_error "GitHub'a giriş yapılmamış"
        log_info "Giriş: gh auth login"
        return 1
    fi
    
    # CHANGELOG'dan notes al
    local notes
    if [[ -f "CHANGELOG.md" ]]; then
        notes=$(extract_changelog_notes "$version")
    else
        notes="Release v${version}"
    fi
    
    # Release oluştur
    if gh release create "v${version}" \
        --repo "$REPO" \
        --title "Release v${version}" \
        --notes "$notes" 2>/dev/null; then
        
        log_success "GitHub release oluşturuldu!"
        log_info "https://github.com/${REPO}/releases/tag/v${version}"
    else
        log_error "Release oluşturulamadı"
        return 1
    fi
}

extract_changelog_notes() {
    local version=$1
    
    # CHANGELOG.md'den ilgili bölümü çıkar
    if [[ -f "CHANGELOG.md" ]]; then
        awk -v ver="$version" '
            /^## \['"$version"'\]/ { found=1; next }
            found && /^## \[/ { exit }
            found { print }
        ' CHANGELOG.md | head -50
    else
        echo "Release v${version}"
    fi
}

# ============================================================================
# İNTERAKTİF MOD
# ============================================================================

show_banner() {
    clear
    echo -e "${BOLD}${CYAN}"
    
    # Banner çizgileri
    local lines=(
        "╔══════════════════════════════════════════════════════════════╗"
        "║                                                              ║"
        "║    ██╗   ██╗███████╗██████╗ ███████╗██╗ ██████╗ ███╗   ██╗ ║"
        "║    ██║   ██║██╔════╝██╔══██╗██╔════╝██║██╔═══██╗████╗  ██║ ║"
        "║    ██║   ██║█████╗  ██████╔╝███████╗██║██║   ██║██╔██╗ ██║ ║"
        "║    ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██║██║   ██║██║╚██╗██║ ║"
        "║     ╚████╔╝ ███████╗██║  ██║███████║██║╚██████╔╝██║ ╚████║ ║"
        "║      ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ║"
        "║                                                              ║"
        "║              Smart Version Manager v2.0                      ║"
        "║              Versiyon Yönetim Asistanı                       ║"
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
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                         ${BOLD}YARDIM${NC}                               ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BOLD}Bu program ne yapar?${NC}"
    echo "  Tüm dosyalardaki versiyon numaralarını tek seferde günceller."
    echo
    echo -e "${BOLD}Komut satırı kullanımı:${NC}"
    echo "  ${CYAN}./smart-version-manager.sh 4.4.0${NC}           → Direkt versiyon"
    echo "  ${CYAN}./smart-version-manager.sh --patch${NC}         → 4.3.1 → 4.3.2"
    echo "  ${CYAN}./smart-version-manager.sh --minor${NC}         → 4.3.1 → 4.4.0"
    echo "  ${CYAN}./smart-version-manager.sh --major${NC}         → 4.3.1 → 4.0.0"
    echo "  ${CYAN}./smart-version-manager.sh 4.4.0 --release${NC} → Versiyon + GitHub release"
    echo
    echo -e "${BOLD}Hangi dosyaları günceller?${NC}"
    echo "  • VERSION, install.sh, README.md"
    echo "  • terminal-setup.sh, terminal-ui.sh, terminal-assistant.sh"
    echo "  • core/terminal-base.sh, terminal-tools.sh, terminal-config.sh"
    echo "  • utils/helpers.sh, system.sh, config.sh"
    echo "  • themes/*.sh (tüm tema dosyaları)"
    echo
    echo -e "${BOLD}Semantic Versioning:${NC}"
    echo "  ${GREEN}Patch${NC} (4.3.1 → 4.3.2) = Bug fix, küçük düzeltme"
    echo "  ${YELLOW}Minor${NC} (4.3.1 → 4.4.0)  = Yeni özellik, geriye uyumlu"
    echo "  ${RED}Major${NC} (4.3.1 → 4.0.0)  = Breaking change, büyük değişiklik"
    echo
    echo -e "${BOLD}İpuçları:${NC}"
    echo "  • CHANGELOG.md'yi önce güncelle (release notes için)"
    echo "  • --release bayrağı GitHub release da oluşturur"
    echo "  • Git commit mesajı otomatik oluşturulur"
    echo
    echo -e "${DIM}Detaylı yardım: ./smart-version-manager.sh --help${NC}"
    echo
}

interactive_mode() {
    while true; do
        show_banner
        
        local current
        current=$(get_current_version)
        
        echo -e "${BOLD}Mevcut versiyon: ${YELLOW}v${current}${NC}"
        echo
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${BOLD}ANA MENÜ${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "  ${GREEN}1)${NC} ${BOLD}Patch${NC}  → v$(bump_version "$current" "patch")  ${DIM}(küçük düzeltmeler)${NC}"
        echo -e "  ${GREEN}2)${NC} ${BOLD}Minor${NC}  → v$(bump_version "$current" "minor")  ${DIM}(yeni özellikler)${NC}"
        echo -e "  ${GREEN}3)${NC} ${BOLD}Major${NC}  → v$(bump_version "$current" "major")  ${DIM}(büyük değişiklikler)${NC}"
        echo -e "  ${GREEN}4)${NC} ${BOLD}Özel versiyon belirt${NC}"
        echo -e "  ${GREEN}5)${NC} ${BOLD}Yardım${NC} ${DIM}(nasıl kullanılır?)${NC}"
        echo -e "  ${GREEN}0)${NC} Çıkış"
        echo
        echo -ne "${BOLD}Seçim (0-5): ${NC}"
        read -r choice
        
        case $choice in
            0)
                echo
                # Çıkış animasyonu
                echo -ne "${CYAN}Çıkış yapılıyor"
                for i in {1..3}; do
                    sleep 0.2
                    echo -n "."
                done
                echo -e "${NC}"
                exit 0
                ;;
            1|2|3)
                local bump_type
                case $choice in
                    1) bump_type="patch" ;;
                    2) bump_type="minor" ;;
                    3) bump_type="major" ;;
                esac
                local new_version
                new_version=$(bump_version "$current" "$bump_type")
                process_version_update "$current" "$new_version"
                ;;
            4)
                echo
                echo -ne "Versiyon (örn: 4.4.0): "
                read -r new_version
                
                if ! validate_version "$new_version"; then
                    echo
                    read -p "Devam için Enter'a basın..."
                    continue
                fi
                
                process_version_update "$current" "$new_version"
                ;;
            5)
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

show_spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        printf "\r${CYAN}${spin:$i:1}${NC} ${message}"
        sleep 0.1
    done
    printf "\r${GREEN}✓${NC} ${message}\n"
}

process_version_update() {
    local current=$1
    local new_version=$2
    
    echo
    # Versiyon değişikliği animasyonu
    echo -ne "${DIM}$current${NC}"
    for i in {1..3}; do
        sleep 0.15
        echo -ne " →"
    done
    echo -e " ${BOLD}${GREEN}$new_version${NC}"
    sleep 0.3
    
    echo
    echo -ne "Devam? (e/h): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[eE]$ ]]; then
        log_warning "İptal edildi"
        echo
        read -p "Devam için Enter'a basın..."
        return
    fi
    
    echo
    # Progress bar ile güncelleme
    echo -ne "${BLUE}[INFO]${NC} Dosyalar güncelleniyor"
    for i in {1..3}; do
        sleep 0.2
        echo -n "."
    done
    echo
    
    update_all_versions "$new_version"
    
    echo
    echo -ne "Git commit + push? (e/h): "
    read -r git_choice
    
    if [[ "$git_choice" =~ ^[eE]$ ]]; then
        git_commit_and_push "$new_version"
        create_git_tag "$new_version"
    fi
    
    echo
    echo -ne "GitHub release oluştur? (e/h): "
    read -r release_choice
    
    if [[ "$release_choice" =~ ^[eE]$ ]]; then
        create_github_release "$new_version"
    fi
    
    echo
    # Başarı animasyonu
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}✓ Tamamlandı! v${new_version}${NC}             ${GREEN}║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo
    read -p "Devam için Enter'a basın..."
}

# ============================================================================
# ANA PROGRAM
# ============================================================================

main() {
    local new_version=""
    local bump_type=""
    local do_release=false
    local do_commit=true
    local do_push=true
    
    # Argüman parse
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --patch)
                bump_type="patch"
                shift
                ;;
            --minor)
                bump_type="minor"
                shift
                ;;
            --major)
                bump_type="major"
                shift
                ;;
            --release)
                do_release=true
                shift
                ;;
            --no-commit)
                do_commit=false
                shift
                ;;
            --no-push)
                do_push=false
                shift
                ;;
            [0-9]*.*)
                new_version=$1
                shift
                ;;
            *)
                log_error "Bilinmeyen parametre: $1"
                echo "Yardım: $0 --help"
                exit 1
                ;;
        esac
    done
    
    # Hiç argüman yoksa interaktif mod
    if [[ -z "$new_version" && -z "$bump_type" ]]; then
        interactive_mode
        exit 0
    fi
    
    # Versiyon hesapla
    if [[ -n "$bump_type" ]]; then
        local current
        current=$(get_current_version)
        new_version=$(bump_version "$current" "$bump_type")
    fi
    
    # Validate
    if ! validate_version "$new_version"; then
        exit 1
    fi
    
    # Güncelle
    echo
    update_all_versions "$new_version"
    
    # Git
    if [[ "$do_commit" == "true" ]]; then
        echo
        git_commit_and_push "$new_version" "$do_push"
        create_git_tag "$new_version"
    fi
    
    # Release
    if [[ "$do_release" == "true" ]]; then
        echo
        create_github_release "$new_version"
    fi
    
    echo
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ✓ Tamamlandı! v${new_version}${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo
}

main "$@"
