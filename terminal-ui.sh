#!/bin/bash

# ============================================================================
# Terminal Setup - UI/Görsel Katman
# v5.0.1 - Stable banner, menu polish and backup UX
# ============================================================================

# ============================================================================
# RENKLER
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ============================================================================
# TERMINAL BOYUTU VE BANNER
# ============================================================================

TERMINAL_TARGET_COLS=71
TERMINAL_TARGET_ROWS=45
_TERMINAL_SIZE_REQUESTED=false

request_terminal_size() {
    if [[ "$_TERMINAL_SIZE_REQUESTED" == true ]]; then
        return 0
    fi
    _TERMINAL_SIZE_REQUESTED=true

    # Birçok terminal emülatörü bu kaçış dizisini destekler.
    # Desteklenmeyen terminallerde sessizce yok sayılır.
    printf '\033[8;%s;%st' "$TERMINAL_TARGET_ROWS" "$TERMINAL_TARGET_COLS" 2>/dev/null || true
    sleep 0.12
}

minimum_terminal_size_notice() {
    request_terminal_size

    local min_cols=71
    local min_rows=45
    local cols rows
    cols=$(tput cols 2>/dev/null || echo 0)
    rows=$(tput lines 2>/dev/null || echo 0)

    if [[ "$cols" -lt "$min_cols" || "$rows" -lt "$min_rows" ]]; then
        echo -e "${YELLOW}İpucu:${NC} Bu menü ${min_cols}x${min_rows} terminal boyutuna göre tasarlandı."
        echo -e "${DIM}Mevcut boyut: ${cols}x${rows}. Pencereyi biraz büyütmeniz iyi olur.${NC}"
        sleep 1
    fi
}

print_banner_frame_1() {
    cat <<EOF
+---------------------------------------------------------------+
|                                                               |
|      ██████  █████  ██                                        |
|      ██      ██ ██  ██                                        |
|      ██      █████  ██                                        |
|      ██████  ██ ██  █████     Terminal Setup                  |
|                                                               |
|                         Version ${VERSION}                    |
|                    github.com/alibedirhan                     |
+---------------------------------------------------------------+
EOF
}

print_banner_frame_2() {
    cat <<EOF
+---------------------------------------------------------------+
|                                                               |
|      ██████  █████  ██       Terminal Setup                   |
|      ██      ██ ██  ██       Zsh + Oh My Zsh + P10k           |
|      ██      █████  ██       7 themes + 14 tools + tmux       |
|      ██████  ██ ██  █████    Backup + Restore + Diagnose      |
|                                                               |
|                         Version ${VERSION}                    |
|                    github.com/alibedirhan                     |
+---------------------------------------------------------------+
EOF
}

print_banner_frame_final() {
    cat <<EOF
+---------------------------------------------------------------+
|      ██████  █████  ██       Terminal Setup                   |
|      ██      ██ ██  ██       Zsh + Oh My Zsh + P10k           |
|      ██      █████  ██       7 themes + 14 tools + tmux       |
|      ██████  ██ ██  █████    Backup + Restore + Diagnose      |
|                                                               |
|                         Version ${VERSION}                    |
|                    github.com/alibedirhan                     |
+---------------------------------------------------------------+
EOF
}

show_animated_banner() {
    minimum_terminal_size_notice

    clear
    echo -e "${CYAN}"
    print_banner_frame_1
    echo -e "${NC}"
    sleep 0.22

    clear
    echo -e "${BOLD}${CYAN}"
    print_banner_frame_2
    echo -e "${NC}"
    sleep 0.22

    clear
    echo -e "${BOLD}${CYAN}"
    print_banner_frame_final
    echo -e "${NC}"
    sleep 0.18
}

show_banner() {
    clear
    echo -e "${BOLD}${CYAN}"
    print_banner_frame_final
    echo -e "${NC}"
}

# ============================================================================
# DURUM ÇUBUĞU
# ============================================================================

show_status_bar() {
    local zsh_status="${RED}x${NC}"
    local omz_status="${RED}x${NC}"
    local p10k_status="${RED}x${NC}"
    local internet_status="${RED}x${NC}"

    if command -v zsh &>/dev/null; then
        if [[ "$SHELL" == *"zsh"* ]]; then
            zsh_status="${GREEN}ok${NC}"
        else
            zsh_status="${YELLOW}var${NC}"
        fi
    fi

    [[ -d "$HOME/.oh-my-zsh" ]] && omz_status="${GREEN}ok${NC}"
    [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]] && p10k_status="${GREEN}ok${NC}"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 2 https://github.com >/dev/null 2>&1 && internet_status="${GREEN}ok${NC}"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=2 -O /dev/null https://github.com >/dev/null 2>&1 && internet_status="${GREEN}ok${NC}"
    elif ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
        internet_status="${GREEN}ok${NC}"
    fi

    echo -e "${CYAN}+----------------------- SISTEM DURUMU ----------------------+${NC}"
    echo -e "  Zsh: $zsh_status   Oh My Zsh: $omz_status   P10k: $p10k_status   Internet: $internet_status"
    echo -e "${CYAN}+------------------------------------------------------------+${NC}"
}

# ============================================================================
# AKILLI ÖNERİLER
# ============================================================================

show_smart_recommendations() {
    echo -e "${YELLOW}+----------------------- AKILLI ONERI -----------------------+${NC}"

    if ! command -v zsh &>/dev/null; then
        echo -e "  ${CYAN}>${NC} İlk kurulum için ${BOLD}1 Tam Kurulum${NC} önerilir."
    elif [[ "$SHELL" != *"zsh"* ]]; then
        echo -e "  ${CYAN}>${NC} Zsh kurulu ama aktif değil. ${BOLD}2 Modüler Kurulum${NC} kontrol edin."
    elif [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo -e "  ${CYAN}>${NC} Oh My Zsh eksik. ${BOLD}1${NC} veya ${BOLD}2${NC} ile kurabilirsiniz."
    elif [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
        echo -e "  ${CYAN}>${NC} Powerlevel10k eksik. ${BOLD}1${NC} veya ${BOLD}2${NC} ile kurabilirsiniz."
    else
        echo -e "  ${GREEN}ok${NC} Sistem hazır. Tema, araçlar veya yedek menüsünü kullanabilirsiniz."
    fi

    if ! ping -c 1 -W 2 1.1.1.1 &>/dev/null && ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        echo -e "  ${RED}!${NC} İnternet görünmüyor; kurulum adımları başarısız olabilir."
    fi

    echo -e "${YELLOW}+------------------------------------------------------------+${NC}"
}

# ============================================================================
# RENK ÖNİZLEMESİ FONKSİYONLARI
# ============================================================================

show_color_box() {
    local r=$1
    local g=$2
    local b=$3
    echo -ne "\033[48;2;${r};${g};${b}m  \033[0m"
}

show_theme_colors() {
    local theme=$1
    echo -n "  "
    case $theme in
        dracula)
            show_color_box 40 42 54; show_color_box 248 248 242; show_color_box 255 85 85; show_color_box 80 250 123
            ;;
        nord)
            show_color_box 46 52 64; show_color_box 216 222 233; show_color_box 191 97 106; show_color_box 163 190 140
            ;;
        gruvbox)
            show_color_box 40 40 40; show_color_box 235 219 178; show_color_box 204 36 29; show_color_box 215 153 33
            ;;
        tokyo-night)
            show_color_box 26 27 38; show_color_box 192 202 245; show_color_box 247 118 142; show_color_box 122 162 247
            ;;
        catppuccin)
            show_color_box 30 30 46; show_color_box 205 214 244; show_color_box 243 139 168; show_color_box 137 180 250
            ;;
        one-dark)
            show_color_box 40 44 52; show_color_box 171 178 191; show_color_box 224 108 117; show_color_box 97 175 239
            ;;
        solarized)
            show_color_box 0 43 54; show_color_box 131 148 150; show_color_box 220 50 47; show_color_box 38 139 210
            ;;
    esac
}

# ============================================================================
# ANA MENÜ
# ============================================================================

show_menu() {
    show_status_bar
    echo
    show_smart_recommendations
    echo

    echo -e "  ${CYAN}------------------------- KURULUM -------------------------${NC}"
    echo -e "  ${BOLD}1${NC}  ${GREEN}Tam Kurulum${NC}        ${DIM}Zsh + OMZ + P10k + tema + plugin${NC}"
    echo -e "  ${BOLD}2${NC}  ${GREEN}Modüler Kurulum${NC}    ${DIM}Bileşenleri ayrı ayrı kur${NC}"
    echo -e "  ${BOLD}3${NC}  ${YELLOW}Tema Değiştir${NC}      ${DIM}7 renk teması arasında geçiş${NC}"
    echo -e "  ${BOLD}4${NC}  ${CYAN}Terminal Araçları${NC}  ${DIM}14 modern CLI aracı${NC}"
    echo -e "  ${BOLD}5${NC}  ${CYAN}Tmux Kurulumu${NC}      ${DIM}Tmux + tema entegrasyonu${NC}"
    echo
    echo -e "  ${CYAN}------------------------- YONETIM -------------------------${NC}"
    echo -e "  ${BOLD}6${NC}  ${CYAN}Sağlık & Teşhis${NC}    ${DIM}Sistem durumu ve sorun çözümü${NC}"
    echo -e "  ${BOLD}7${NC}  ${CYAN}Yedekler${NC}           ${DIM}Göster / geri yükle / klasörü aç${NC}"
    echo -e "  ${BOLD}8${NC}  ${CYAN}Ayarlar${NC}            ${DIM}Tema, güncelleme, yedek sayısı${NC}"
    echo
    echo -e "  ${RED}---------------------- TEHLIKELI ALAN ---------------------${NC}"
    echo -e "  ${BOLD}9${NC}  ${RED}Kaldır${NC}             ${DIM}Terminal Setup değişikliklerini temizle${NC}"
    echo -e "  ${BOLD}0${NC}  ${WHITE}Çıkış${NC}"
    echo
    echo -ne "  ${BOLD}${CYAN}Seçiminiz (0-9): ${NC}"
}

# ============================================================================
# MODÜLER KURULUM MENÜSÜ
# ============================================================================

show_modular_menu() {
    clear
    show_banner
    echo
    echo -e "  ${CYAN}---------------------- MODULER KURULUM ---------------------${NC}"
    echo -e "  ${BOLD}1${NC}  ${GREEN}Zsh + Oh My Zsh${NC}    ${DIM}Shell + framework + pluginler${NC}"
    echo -e "  ${BOLD}2${NC}  ${GREEN}Powerlevel10k${NC}      ${DIM}Tema motoru + fontlar${NC}"
    echo -e "  ${BOLD}3${NC}  ${GREEN}Pluginler${NC}          ${DIM}autosuggestions + syntax highlight${NC}"
    echo -e "  ${BOLD}0${NC}  ${DIM}Geri${NC}"
    echo
    echo -ne "  ${CYAN}Seçiminiz (0-3): ${NC}"
}

# ============================================================================
# TEMA SEÇİM MENÜSÜ
# ============================================================================

show_theme_menu() {
    clear
    show_banner
    echo
    echo -e "  ${CYAN}------------------------- TEMA SECIMI ----------------------${NC}"
    local terminal_type
    terminal_type=$(detect_terminal)
    echo -e "  ${DIM}Tespit edilen terminal: ${terminal_type}${NC}"
    echo

    echo -ne "  ${BOLD}1${NC}  ${MAGENTA}Dracula${NC}        ${DIM}Mor/pembe, yüksek kontrast${NC}"; show_theme_colors "dracula"; echo
    echo -ne "  ${BOLD}2${NC}  ${BLUE}Nord${NC}           ${DIM}Mavi/gri, yumuşak görünüm${NC}"; show_theme_colors "nord"; echo
    echo -ne "  ${BOLD}3${NC}  ${YELLOW}Gruvbox${NC}        ${DIM}Retro sıcak tonlar${NC}"; show_theme_colors "gruvbox"; echo
    echo -ne "  ${BOLD}4${NC}  ${BLUE}Tokyo Night${NC}    ${DIM}Modern mavi/mor${NC}"; show_theme_colors "tokyo-night"; echo
    echo -ne "  ${BOLD}5${NC}  ${MAGENTA}Catppuccin${NC}     ${DIM}Pastel mocha paleti${NC}"; show_theme_colors "catppuccin"; echo
    echo -ne "  ${BOLD}6${NC}  ${CYAN}One Dark${NC}       ${DIM}Atom benzeri koyu tema${NC}"; show_theme_colors "one-dark"; echo
    echo -ne "  ${BOLD}7${NC}  ${CYAN}Solarized${NC}      ${DIM}Klasik düşük kontrast${NC}"; show_theme_colors "solarized"; echo
    echo -e "  ${BOLD}0${NC}  ${DIM}Geri${NC}"
    echo
    echo -ne "  ${CYAN}Seçiminiz (0-7): ${NC}"
}

# ============================================================================
# AYARLAR MENÜSÜ
# ============================================================================

show_settings_menu() {
    clear
    show_banner
    echo
    echo -e "  ${CYAN}-------------------------- AYARLAR -------------------------${NC}"

    load_config

    echo -e "  ${DIM}Varsayılan tema:${NC}      ${DEFAULT_THEME:-Yok}"
    echo -e "  ${DIM}Otomatik güncelleme:${NC}  ${AUTO_UPDATE:-false}"
    echo -e "  ${DIM}Yedek sayısı:${NC}         ${BACKUP_COUNT:-5}"
    echo
    echo -e "  ${BOLD}1${NC}  Varsayılan tema değiştir"
    echo -e "  ${BOLD}2${NC}  Otomatik güncelleme ($([ "$AUTO_UPDATE" = "true" ] && echo "Kapat" || echo "Aç"))"
    echo -e "  ${BOLD}3${NC}  Yedek sayısını ayarla"
    echo -e "  ${BOLD}4${NC}  Güncellemeleri kontrol et"
    echo -e "  ${BOLD}5${NC}  Ayarları sıfırla"
    echo -e "  ${BOLD}0${NC}  ${DIM}Geri${NC}"
    echo
    echo -ne "  ${CYAN}Seçiminiz (0-5): ${NC}"
}

# ============================================================================
# TERMİNAL ARAÇLARI ALT MENÜSÜ
# ============================================================================

show_tools_submenu() {
    clear
    show_banner
    echo
    echo -e "  ${CYAN}--------------------- TERMINAL ARACLARI --------------------${NC}"
    echo -e "  ${BOLD}1${NC}   ${GREEN}Hepsini kur${NC}        ${DIM}14 araç - tam paket${NC}"
    echo -e "  ${BOLD}2${NC}   ${CYAN}Temel araçlar${NC}      ${DIM}FZF, Zoxide, Eza, Bat${NC}"
    echo -e "  ${BOLD}3${NC}   ${CYAN}Arama araçları${NC}     ${DIM}Ripgrep, Fd${NC}"
    echo -e "  ${BOLD}4${NC}   ${CYAN}Git araçları${NC}       ${DIM}Delta, Lazygit${NC}"
    echo -e "  ${BOLD}5${NC}   ${CYAN}Sistem araçları${NC}    ${DIM}Btop, Dust, Duf, Procs${NC}"
    echo -e "  ${BOLD}6${NC}   ${CYAN}Ekstra araçlar${NC}     ${DIM}Atuin, TLDR${NC}"
    echo
    echo -e "  ${DIM}Tekil kurulum:${NC}"
    echo -e "  ${BOLD}7${NC} Ripgrep   ${BOLD}8${NC} Fd       ${BOLD}9${NC} Delta    ${BOLD}10${NC} Lazygit"
    echo -e "  ${BOLD}11${NC} TLDR     ${BOLD}12${NC} Btop    ${BOLD}13${NC} Dust     ${BOLD}14${NC} Duf"
    echo -e "  ${BOLD}15${NC} Procs    ${BOLD}16${NC} Atuin   ${BOLD}0${NC} Geri"
    echo
    echo -ne "  ${BOLD}${CYAN}Seçiminiz (0-16): ${NC}"
}

# ============================================================================
# PROGRESS BAR
# ============================================================================

show_progress() {
    local current=$1
    local total=$2
    local task=$3
    local width=40
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    
    printf "\r\033[K"
    printf "${CYAN}%s${NC} [" "$task"
    printf "%${completed}s" | tr ' ' '█'
    printf "%$((width - completed))s" | tr ' ' '░'
    printf "] %3d%%" "$percentage"
    
    if [ "$current" -eq "$total" ]; then
        printf " ${GREEN}✓${NC}\n"
    fi
}

show_advanced_progress() {
    local current=$1
    local total=$2
    local task=$3
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    
    local bar_color
    if [ $percentage -lt 33 ]; then
        bar_color=$RED
    elif [ $percentage -lt 66 ]; then
        bar_color=$YELLOW
    else
        bar_color=$GREEN
    fi
    
    printf "\r\033[K"
    printf "${CYAN}[%2d/%2d]${NC} " "$current" "$total"
    printf "["
    printf "${bar_color}%${completed}s${NC}" | tr ' ' '█'
    printf "%$((width - completed))s" | tr ' ' '░'
    printf "] ${bar_color}%3d%%${NC} - %s" "$percentage" "$task"
    
    if [ "$current" -eq "$total" ]; then
        printf " ${GREEN}✓${NC}\n"
    fi
}

# ============================================================================
# SPINNER
# ============================================================================

SPINNER_CHARS=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
SPINNER_PID=""

start_spinner() {
    local message="${1:-İşlem devam ediyor}"
    
    (
        local i=0
        while true; do
            printf "\r${CYAN}${SPINNER_CHARS[$i]}${NC} $message"
            i=$(( (i + 1) % ${#SPINNER_CHARS[@]} ))
            sleep 0.1
        done
    ) &
    
    SPINNER_PID=$!
    log_debug "Spinner başlatıldı (PID: $SPINNER_PID)"
}

stop_spinner() {
    local status="${1:-}"
    
    if [[ -n "$SPINNER_PID" ]] && kill -0 "$SPINNER_PID" 2>/dev/null; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null || true
        
        printf "\r\033[K"
        
        case "$status" in
            success) echo -e "${GREEN}✓${NC} Tamamlandı" ;;
            error)   echo -e "${RED}✗${NC} Başarısız" ;;
            warning) echo -e "${YELLOW}⚠${NC} Uyarı" ;;
        esac
        
        SPINNER_PID=""
        log_debug "Spinner durduruldu"
    fi
}

# ============================================================================
# TAMAMLANMA MESAJI VE SHELL GEÇİŞ PROMPTU
# ============================================================================

show_completion_message() {
    echo
    echo -e "${GREEN}══════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Kurulum tamamlandı!${NC}"
    echo -e "${GREEN}══════════════════════════════════${NC}"
    echo
    echo -e "${CYAN}Yedekler: $BACKUP_DIR${NC}"
    echo -e "${CYAN}Log dosyası: $LOG_FILE${NC}"
}

show_switch_shell_prompt() {
    echo
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}DEĞİŞİKLİKLERİ GÖRMEK İÇİN ZSH'E GEÇİN${NC}"
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    echo
    echo -e "${GREEN}✓ Zsh sistem shell'i olarak ayarlandı${NC}"
    echo -e "${GREEN}✓ GNOME Terminal login shell moduna geçirildi${NC}"
    echo
    echo "Seçenekler:"
    echo -e "  ${CYAN}1)${NC} Şimdi Zsh'e geç (Powerlevel10k wizard başlar)"
    echo -e "  ${CYAN}2)${NC} Ana menüye dön (yeni terminaller otomatik Zsh açacak)"
    echo
    echo -e "${YELLOW}Not:${NC} Yeni terminal pencerelerinde Zsh otomatik başlayacak"
    echo
    echo -ne "${CYAN}Seçiminiz (1/2) [1]: ${NC}"
    read -r switch_choice
    
    if [[ -z "$switch_choice" ]] || [[ "$switch_choice" == "1" ]]; then
        echo
        echo -e "${GREEN}Zsh'e geçiliyor...${NC}"
        sleep 1
        return 0
    else
        echo
        echo -e "${GREEN}Ana menüye dönülüyor...${NC}"
        echo -e "${YELLOW}İpucu:${NC} Yeni terminal penceresi açın veya 'exec zsh' yazın"
        echo
        sleep 2
        return 1
    fi
}

# ============================================================================
# TERMİNAL ARAÇLARI BİLGİ
# ============================================================================

show_terminal_tools_info() {
    clear
    show_banner
    echo
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}           ${BOLD}MODERN TERMİNAL ARAÇLARI${NC}                   ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    echo
    
    echo -e "${YELLOW}1) FZF - Fuzzy Finder${NC}"
    echo "   Dosya, komut, history'de hızlı arama"
    echo
    echo -e "${YELLOW}2) Zoxide - Akıllı cd${NC}"
    echo "   En çok kullandığınız dizinlere hızlıca atlama"
    echo
    echo -e "${YELLOW}3) Exa - Modern ls${NC}"
    echo "   Renkli ve icon'lu dosya listeleme"
    echo
    echo -e "${YELLOW}4) Bat - cat with syntax${NC}"
    echo "   Syntax highlighting ile dosya görüntüleme"
    echo
    
    echo -ne "${CYAN}Tümünü kurmak ister misiniz? (e/h): ${NC}"
    read -r install_all
    
    [[ "$install_all" == "e" ]]
}

# ============================================================================
# YARDIM MESAJI
# ============================================================================

show_help() {
    echo "Terminal Özelleştirme Kurulum Aracı v$VERSION"
    echo
    echo "Kullanım: $0 [SEÇENEKLER]"
    echo
    echo "Seçenekler:"
    echo "  --health          Sistem sağlık kontrolü"
    echo "  --update          Güncellemeleri kontrol et"
    echo "  --debug           Debug modu"
    echo "  --verbose         Detaylı çıktı"
    echo "  --version         Versiyon bilgisi"
    echo "  --help, -h        Bu yardım mesajı"
    echo
    echo "Örnekler:"
    echo "  $0                # Normal mod"
    echo "  $0 --health       # Sadece sağlık kontrolü"
    echo "  $0 --debug        # Debug modu ile çalıştır"
}
