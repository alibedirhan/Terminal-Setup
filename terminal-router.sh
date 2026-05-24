#!/bin/bash

# ============================================================================
# Terminal Setup - Router Module
# v5.0.2 - Menu routing, backup restore and action validation
# ============================================================================
# Bu modül:
# - Ana menü yönlendirmesi (route_choice)
# - Tüm menü aksiyonları (do_full_install, do_tools, vb.)
# - Config yönetimi (load_config, save_config, validate_config)
# - Ortak yardımcılar (wait_for_enter, prepare_install, vb.)
# ============================================================================

# ============================================================================
# CONFIG YÖNETİMİ
# ============================================================================

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE" 2>/dev/null || true
        log_debug "Config yüklendi: $CONFIG_FILE"
    else
        # Varsayılanları ata
        DEFAULT_THEME="${DEFAULT_THEME:-dracula}"
        AUTO_UPDATE="${AUTO_UPDATE:-false}"
        BACKUP_COUNT="${BACKUP_COUNT:-5}"
        log_debug "Config dosyası bulunamadı, varsayılanlar kullanılıyor"
    fi
}

save_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# Terminal Setup Config - Otomatik oluşturuldu
DEFAULT_THEME="${DEFAULT_THEME:-dracula}"
AUTO_UPDATE="${AUTO_UPDATE:-false}"
BACKUP_COUNT="${BACKUP_COUNT:-5}"
EOF
    log_debug "Config kaydedildi: $CONFIG_FILE"
}

validate_config() {
    local valid=true

    # Tema doğrula
    case "${DEFAULT_THEME:-dracula}" in
        dracula|nord|gruvbox|tokyo-night|catppuccin|one-dark|solarized) ;;
        *)
            log_debug "Geçersiz tema: $DEFAULT_THEME, dracula'ya sıfırlanıyor"
            DEFAULT_THEME="dracula"
            valid=false
            ;;
    esac

    # Yedek sayısı doğrula
    if ! [[ "${BACKUP_COUNT:-5}" =~ ^[0-9]+$ ]] || \
       [ "${BACKUP_COUNT:-5}" -lt 1 ] || \
       [ "${BACKUP_COUNT:-5}" -gt 20 ]; then
        log_debug "Geçersiz yedek sayısı: $BACKUP_COUNT, 5'e sıfırlanıyor"
        BACKUP_COUNT=5
        valid=false
    fi

    $valid && return 0 || return 1
}

# ============================================================================
# GÜNCELLEME KONTROLÜ
# ============================================================================

check_for_updates() {
    local silent="${1:-}"

    if [[ "$silent" != "--silent" ]]; then
        echo
        log_info "Güncellemeler kontrol ediliyor..."
    fi

    if ! check_internet 2>/dev/null; then
        [[ "$silent" != "--silent" ]] && log_warning "İnternet bağlantısı yok, güncelleme kontrolü atlanıyor"
        return 1
    fi

    local remote_version
    remote_version=$(curl -fsSL --max-time 5 \
        "https://raw.githubusercontent.com/alibedirhan/Terminal-Setup/main/VERSION" 2>/dev/null | tr -d '[:space:]')

    if [[ -z "$remote_version" ]]; then
        [[ "$silent" != "--silent" ]] && log_warning "Versiyon bilgisi alınamadı"
        return 1
    fi

    if [[ "$remote_version" != "$VERSION" ]]; then
        echo
        echo -e "${YELLOW}╔══════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  Yeni sürüm mevcut: ${GREEN}v${remote_version}${NC} ${DIM}(mevcut: v${VERSION})${NC}  ${YELLOW}║${NC}"
        echo -e "${YELLOW}║  ${CYAN}https://github.com/alibedirhan/Terminal-Setup${NC}    ${YELLOW}║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════╝${NC}"
    else
        [[ "$silent" != "--silent" ]] && log_success "Güncel sürümdesiniz (v${VERSION})"
    fi

    return 0
}

# ============================================================================
# YEDEK GÖRÜNTÜLEME
# ============================================================================

show_backups() {
    echo
    echo -e "${CYAN}┌──────────────────── YEDEKLER ────────────────────┐${NC}"
    echo

    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 2>/dev/null | head -1)" ]]; then
        echo -e "  ${YELLOW}Henüz yedek bulunmuyor.${NC}"
        echo -e "  ${DIM}Kurulum veya geri yükleme öncesinde otomatik yedek alınır.${NC}"
    else
        local i=0
        while IFS= read -r backup; do
            i=$((i + 1))
            local name size date_str
            name=$(basename "$backup")
            size=$(du -sh "$backup" 2>/dev/null | cut -f1)
            date_str=$(stat -c '%y' "$backup" 2>/dev/null | cut -d'.' -f1)
            echo -e "  ${BOLD}${i})${NC} ${name}  ${DIM}(${size:-?}, ${date_str:-?})${NC}"
        done < <(list_backup_snapshots | head -20)

        if [[ $i -eq 0 ]]; then
            echo -e "  ${YELLOW}Eski düzende alınmış düz dosya yedekleri olabilir.${NC}"
            echo -e "  ${DIM}Yeni geri yükleme sistemi backup_* klasörlerini kullanır.${NC}"
        fi

        echo
        echo -e "  ${DIM}Konum: ${BACKUP_DIR}${NC}"
    fi

    echo
    echo -e "${CYAN}└──────────────────────────────────────────────────┘${NC}"
}

select_backup_snapshot() {
    local selected_index="$1"
    local i=0
    local backup
    while IFS= read -r backup; do
        i=$((i + 1))
        if [[ "$i" == "$selected_index" ]]; then
            printf '%s\n' "$backup"
            return 0
        fi
    done < <(list_backup_snapshots | head -20)
    return 1
}

open_backup_folder() {
    mkdir -p "$BACKUP_DIR"
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$BACKUP_DIR" >/dev/null 2>&1 &
        log_success "Yedek klasörü açılıyor: $BACKUP_DIR"
    else
        log_info "Yedek klasörü: $BACKUP_DIR"
    fi
}

# ============================================================================
# ORTAK YARDIMCILAR
# ============================================================================

wait_for_enter() {
    echo
    read -p "Devam etmek için Enter'a basın..."
}

# Kurulum öncesi kontroller (bağımlılık + sudo + yedek)
prepare_install() {
    if ! check_dependencies; then
        wait_for_enter
        return 1
    fi

    if ! setup_sudo; then
        wait_for_enter
        return 1
    fi

    if ! create_backup "pre_install"; then
        log_error "Yedekleme başarısız"
        wait_for_enter
        return 1
    fi
    return 0
}

# P10k yapılandırma yardımcısı
handle_p10k_configure() {
    if [[ ! -f ~/.p10k.zsh ]]; then
        echo
        echo -e "${CYAN}Powerlevel10k yapılandırması başlatılıyor...${NC}"
        echo -e "${DIM}Görsel tercihlerinizi seçin, sonra menüye döneceksiniz.${NC}"
        sleep 2
        zsh -c "source ~/.zshrc && p10k configure"
        echo
        echo -e "${GREEN}✓ Yapılandırma tamamlandı${NC}"
    else
        echo
        echo -e "${GREEN}✓ Powerlevel10k zaten yapılandırılmış${NC}"
        echo -e "${YELLOW}Tekrar yapılandırmak için Zsh'te: ${CYAN}p10k configure${NC}"
    fi
    echo
    sleep 1
}

# source ~/.zshrc uyarısı
show_source_hint() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        echo
        echo -e "${YELLOW}Değişiklikleri uygulamak için:${NC} ${CYAN}source ~/.zshrc${NC}"
    fi
}

# Kurulum tamamlandı mesajı
show_install_complete() {
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   ${GREEN}✓ KURULUM BAŞARIYLA TAMAMLANDI${NC}       ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo
    echo -e "${DIM}Yedekler: $BACKUP_DIR${NC}"
    echo -e "${DIM}Log dosyası: $LOG_FILE${NC}"
}

# ============================================================================
# 1 - TAM KURULUM
# ============================================================================

do_full_install() {
    # Tema seçimi
    show_theme_menu
    read -r theme_choice

    [[ "$theme_choice" == "0" ]] && return 0

    if ! [[ "$theme_choice" =~ ^[1-7]$ ]]; then
        log_error "Geçersiz tema seçimi: $theme_choice (1-7 arası olmalı)"
        sleep 2
        return 1
    fi

    # Tema eşlemesi
    local theme theme_display
    case $theme_choice in
        1) theme="dracula";     theme_display="Dracula" ;;
        2) theme="nord";        theme_display="Nord" ;;
        3) theme="gruvbox";     theme_display="Gruvbox" ;;
        4) theme="tokyo-night"; theme_display="Tokyo Night" ;;
        5) theme="catppuccin";  theme_display="Catppuccin" ;;
        6) theme="one-dark";    theme_display="One Dark" ;;
        7) theme="solarized";   theme_display="Solarized" ;;
    esac

    clear
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   ${BOLD}${theme_display^^} TAM KURULUM BAŞLIYOR${NC}      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"

    # Ön kontroller
    echo
    echo -e "${CYAN}┌──── HAZIRLIK ────┐${NC}"

    if ! check_dependencies; then
        log_error "Bağımlılık kontrolü başarısız"
        wait_for_enter
        return 1
    fi
    show_step_success "Bağımlılıklar kontrol edildi"

    if ! setup_sudo; then
        log_error "Sudo yetkisi alınamadı"
        wait_for_enter
        return 1
    fi
    show_step_success "Sudo yetkisi alındı"

    if ! create_backup "pre_install"; then
        log_error "Yedekleme başarısız"
        wait_for_enter
        return 1
    fi
    show_step_success "Yedek oluşturuldu"

    # Kurulum adımları
    show_section 1 7 "Zsh kuruluyor"
    install_zsh || { wait_for_enter; return 1; }

    show_section 2 7 "Oh My Zsh kuruluyor"
    install_oh_my_zsh || { wait_for_enter; return 1; }

    show_section 3 7 "Fontlar kuruluyor"
    install_fonts

    show_section 4 7 "Powerlevel10k kuruluyor"
    install_powerlevel10k || { wait_for_enter; return 1; }

    show_section 5 7 "Pluginler kuruluyor"
    install_plugins

    show_section 6 7 "$theme_display teması uygulanıyor"
    install_theme "$theme"

    show_section 7 7 "Shell değiştiriliyor"
    change_default_shell

    # Bash aliases
    echo
    echo -e "${CYAN}┌──── BASH ALIASES KONTROLÜ ────┐${NC}"
    migrate_bash_aliases

    show_install_complete

    # Zsh'e geçiş
    if show_switch_shell_prompt; then
        handle_p10k_configure
    fi

    wait_for_enter
}

# ============================================================================
# 2 - MODÜLER KURULUM
# ============================================================================

do_modular_install() {
    while true; do
        show_modular_menu
        read -r mod_choice

        case $mod_choice in
            0)
                return 0
                ;;
            1)
                # Zsh + Oh My Zsh + Pluginler
                prepare_install || continue

                clear
                echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║   ${BOLD}ZSH + OH MY ZSH KURULUMU${NC}             ${CYAN}║${NC}"
                echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"

                show_section 1 5 "Zsh kuruluyor"
                install_zsh

                show_section 2 5 "Oh My Zsh kuruluyor"
                install_oh_my_zsh

                show_section 3 5 "Fontlar kuruluyor"
                install_fonts

                show_section 4 5 "Pluginler kuruluyor"
                install_plugins

                show_section 5 5 "Shell değiştiriliyor"
                change_default_shell

                echo
                echo -e "${CYAN}┌──── ALIASES KONTROLÜ ────┐${NC}"
                migrate_bash_aliases

                echo
                log_success "Zsh + Oh My Zsh kurulumu tamamlandı"

                if show_switch_shell_prompt; then
                    handle_p10k_configure
                fi

                wait_for_enter
                ;;
            2)
                # Powerlevel10k
                prepare_install || continue

                clear
                echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║   ${BOLD}POWERLEVEL10K KURULUMU${NC}               ${CYAN}║${NC}"
                echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"

                show_section 1 2 "Fontlar kuruluyor"
                install_fonts

                show_section 2 2 "Powerlevel10k kuruluyor"
                install_powerlevel10k

                echo
                log_success "Powerlevel10k kurulumu tamamlandı"
                show_source_hint
                wait_for_enter
                ;;
            3)
                # Pluginler
                prepare_install || continue

                clear
                echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║   ${BOLD}PLUGİN KURULUMU${NC}                      ${CYAN}║${NC}"
                echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
                echo

                install_plugins

                echo
                log_success "Plugin kurulumu tamamlandı"
                show_source_hint
                wait_for_enter
                ;;
            *)
                log_error "Geçersiz seçim"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# 3 - TEMA DEĞİŞTİR
# ============================================================================

do_change_theme() {
    show_theme_menu
    read -r theme_choice

    [[ "$theme_choice" == "0" ]] && return 0

    if ! [[ "$theme_choice" =~ ^[1-7]$ ]]; then
        log_error "Geçersiz seçim: $theme_choice (1-7 arası olmalı)"
        sleep 2
        return 1
    fi

    echo
    log_info "Tema değiştiriliyor..."

    local theme
    case $theme_choice in
        1) theme="dracula" ;;
        2) theme="nord" ;;
        3) theme="gruvbox" ;;
        4) theme="tokyo-night" ;;
        5) theme="catppuccin" ;;
        6) theme="one-dark" ;;
        7) theme="solarized" ;;
    esac

    if install_theme "$theme"; then
        log_success "Tema başarıyla değiştirildi!"
        show_source_hint
    else
        log_error "Tema değiştirme başarısız"
    fi

    wait_for_enter
}

# ============================================================================
# 4 - TERMİNAL ARAÇLARI
# ============================================================================

do_tools() {
    while true; do
        show_tools_submenu
        read -r tools_choice

        # Input validation
        if ! [[ "$tools_choice" =~ ^[0-9]+$ ]]; then
            log_error "Geçersiz girdi: sadece sayı girebilirsiniz"
            sleep 2
            continue
        fi

        [[ "$tools_choice" == "0" ]] && return 0

        # Bağımlılık ve sudo kontrolü
        if ! check_dependencies; then
            wait_for_enter
            continue
        fi

        if ! setup_sudo; then
            wait_for_enter
            continue
        fi

        clear
        echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║   ${BOLD}TERMİNAL ARAÇLARI KURULUMU${NC}          ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
        echo

        case $tools_choice in
            1)
                echo -e "${YELLOW}${BOLD}14 araç kuruluyor... Bu biraz zaman alabilir.${NC}"
                echo
                install_all_tools_complete
                echo
                log_success "Tam paket kurulumu tamamlandı!"
                ;;
            2)
                show_section 1 4 "FZF kuruluyor"
                install_fzf
                show_section 2 4 "Zoxide kuruluyor"
                install_zoxide
                show_section 3 4 "Exa kuruluyor"
                install_exa
                show_section 4 4 "Bat kuruluyor"
                install_bat
                echo
                log_success "Temel araçlar kuruldu"
                ;;
            3)  install_search_tools;  log_success "Arama araçları kuruldu" ;;
            4)  install_git_tools;     log_success "Git araçları kuruldu" ;;
            5)  install_system_tools;  log_success "Sistem araçları kuruldu" ;;
            6)  install_extra_tools;   log_success "Ekstra araçlar kuruldu" ;;
            7)  install_ripgrep;       log_success "Ripgrep kuruldu" ;;
            8)  install_fd;            log_success "Fd kuruldu" ;;
            9)  install_delta;         log_success "Delta kuruldu" ;;
            10) install_lazygit;       log_success "Lazygit kuruldu" ;;
            11) install_tldr;          log_success "TLDR kuruldu" ;;
            12) install_btop;          log_success "Btop kuruldu" ;;
            13) install_dust;          log_success "Dust kuruldu" ;;
            14) install_duf;           log_success "Duf kuruldu" ;;
            15) install_procs;         log_success "Procs kuruldu" ;;
            16) install_atuin;         log_success "Atuin kuruldu" ;;
            *)
                log_error "Geçersiz seçim: $tools_choice"
                sleep 2
                continue
                ;;
        esac

        show_source_hint
        wait_for_enter
    done
}

# ============================================================================
# 5 - TMUX KURULUMU
# ============================================================================

do_tmux() {
    echo
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}           ${BOLD}TMUX TEMA SEÇİMİ${NC}                            ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    echo
    echo -e "  ${BOLD}1${NC}   ${MAGENTA}Dracula${NC}"
    echo -e "  ${BOLD}2${NC}   ${BLUE}Nord${NC}"
    echo -e "  ${BOLD}3${NC}   ${YELLOW}Gruvbox${NC}"
    echo -e "  ${BOLD}4${NC}   ${BLUE}Tokyo Night${NC}"
    echo -e "  ${BOLD}5${NC}   ${MAGENTA}Catppuccin${NC}"
    echo -e "  ${BOLD}6${NC}   ${CYAN}One Dark${NC}"
    echo -e "  ${BOLD}7${NC}   ${CYAN}Solarized${NC}"
    echo -e "  ${BOLD}0${NC}   ${DIM}Geri${NC}"
    echo
    echo -ne "  ${CYAN}Seçiminiz (0-7): ${NC}"
    read -r tmux_theme_choice

    [[ "$tmux_theme_choice" == "0" ]] && return 0

    local tmux_theme="dracula"
    if [[ "$tmux_theme_choice" =~ ^[1-7]$ ]]; then
        case $tmux_theme_choice in
            1) tmux_theme="dracula" ;;
            2) tmux_theme="nord" ;;
            3) tmux_theme="gruvbox" ;;
            4) tmux_theme="tokyo-night" ;;
            5) tmux_theme="catppuccin" ;;
            6) tmux_theme="one-dark" ;;
            7) tmux_theme="solarized" ;;
        esac
    else
        log_warning "Geçersiz seçim, Dracula kullanılıyor"
    fi

    prepare_install || return 1

    install_tmux_with_theme "$tmux_theme"
    log_success "Tmux kurulumu tamamlandı"
    wait_for_enter
}

# ============================================================================
# 6 - SAĞLIK & TEŞHİS
# ============================================================================

do_health_and_diagnostics() {
    while true; do
        clear
        show_banner
        echo
        echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│${NC}           ${BOLD}SAĞLIK & TEŞHİS MENÜSÜ${NC}                    ${CYAN}│${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
        echo
        echo -e "  ${BOLD}1${NC}   ${GREEN}Tam Sağlık Kontrolü${NC}        ${DIM}Tüm bileşenleri tara${NC}"
        echo
        echo -e "  ${CYAN}──── Sorun Teşhisi ────${NC}"
        echo -e "  ${BOLD}2${NC}   Shell sorunları            ${DIM}Bash yerine Zsh gelmiyorsa${NC}"
        echo -e "  ${BOLD}3${NC}   İnternet bağlantısı        ${DIM}Bağlantı kontrolü${NC}"
        echo -e "  ${BOLD}4${NC}   Yetki sorunları            ${DIM}Sudo problemleri${NC}"
        echo -e "  ${BOLD}5${NC}   Font sorunları             ${DIM}Karakter/ikon görünmüyor${NC}"
        echo -e "  ${BOLD}6${NC}   Tema sorunları             ${DIM}Renkler uygulanmıyor${NC}"
        echo -e "  ${BOLD}7${NC}   Paket eksiklikleri         ${DIM}git/curl/wget/zsh${NC}"
        echo -e "  ${BOLD}8${NC}   Instant Prompt             ${DIM}Terminal açılış uyarıları${NC}"
        echo
        echo -e "  ${BOLD}0${NC}   ${DIM}Geri${NC}"
        echo
        echo -ne "  ${CYAN}Seçiminiz (0-8): ${NC}"
        read -r diag_choice

        case $diag_choice in
            0) return 0 ;;
            1) show_banner; system_health_check; wait_for_enter ;;
            2) diagnose_and_fix "zsh_not_default"; wait_for_enter ;;
            3) diagnose_and_fix "internet_connection"; wait_for_enter ;;
            4) diagnose_and_fix "permission_denied"; wait_for_enter ;;
            5) diagnose_and_fix "font_not_visible"; wait_for_enter ;;
            6) diagnose_and_fix "theme_not_applied"; wait_for_enter ;;
            7)
                echo
                echo "Hangi paket eksik? (git/curl/wget/zsh):"
                read -r missing_pkg
                diagnose_and_fix "package_missing" "$missing_pkg"
                wait_for_enter
                ;;
            8)
                clear
                diagnose_instant_prompt_issues
                wait_for_enter
                ;;
            *)
                log_error "Geçersiz seçim"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# 7 - YEDEKLER
# ============================================================================

do_backups() {
    while true; do
        clear
        show_banner
        show_backups
        echo
        echo -e "  ${BOLD}1${NC}   ${CYAN}En son yedeği geri yükle${NC}"
        echo -e "  ${BOLD}2${NC}   ${CYAN}Numara seçerek geri yükle${NC}"
        echo -e "  ${BOLD}3${NC}   ${CYAN}Yedek klasörünü aç / göster${NC}"
        echo -e "  ${BOLD}0${NC}   ${DIM}Geri${NC}"
        echo
        echo -ne "  ${CYAN}Seçiminiz (0-3): ${NC}"
        read -r backup_choice

        case "$backup_choice" in
            0) return 0 ;;
            1)
                local latest
                latest=$(get_latest_backup_snapshot)
                if [[ -z "$latest" ]]; then
                    log_error "Geri yüklenecek yedek bulunamadı"
                    wait_for_enter
                    continue
                fi
                echo
                echo -e "${YELLOW}Geri yüklenecek yedek:${NC} $(basename "$latest")"
                if ask_yes_no "Bu yedeği geri yüklemek istiyor musunuz?" "n"; then
                    restore_backup_snapshot "$latest"
                else
                    log_info "Geri yükleme iptal edildi"
                fi
                wait_for_enter
                ;;
            2)
                echo
                echo -ne "Yedek numarası: "
                read -r selected
                if ! [[ "$selected" =~ ^[0-9]+$ ]]; then
                    log_error "Geçersiz numara"
                    wait_for_enter
                    continue
                fi
                local selected_backup
                selected_backup=$(select_backup_snapshot "$selected") || selected_backup=""
                if [[ -z "$selected_backup" ]]; then
                    log_error "Bu numarada yedek bulunamadı"
                    wait_for_enter
                    continue
                fi
                echo
                echo -e "${YELLOW}Geri yüklenecek yedek:${NC} $(basename "$selected_backup")"
                if ask_yes_no "Bu yedeği geri yüklemek istiyor musunuz?" "n"; then
                    restore_backup_snapshot "$selected_backup"
                else
                    log_info "Geri yükleme iptal edildi"
                fi
                wait_for_enter
                ;;
            3)
                open_backup_folder
                wait_for_enter
                ;;
            *)
                log_error "Geçersiz seçim"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# 8 - AYARLAR
# ============================================================================

do_settings() {
    while true; do
        show_settings_menu
        read -r settings_choice

        case $settings_choice in
            0)
                return 0
                ;;
            1)
                echo
                echo "Yeni varsayılan tema (dracula/nord/gruvbox/tokyo-night/catppuccin/one-dark/solarized):"
                read -r new_theme
                if [[ " dracula nord gruvbox tokyo-night catppuccin one-dark solarized " =~ " $new_theme " ]]; then
                    DEFAULT_THEME="$new_theme"
                    save_config
                    log_success "Varsayılan tema değiştirildi: $new_theme"
                else
                    log_error "Geçersiz tema!"
                fi
                wait_for_enter
                ;;
            2)
                if [[ "$AUTO_UPDATE" == "true" ]]; then
                    AUTO_UPDATE="false"
                    log_info "Otomatik güncelleme kapatıldı"
                else
                    AUTO_UPDATE="true"
                    log_info "Otomatik güncelleme açıldı"
                fi
                save_config
                wait_for_enter
                ;;
            3)
                echo
                echo "Yeni yedek sayısı (1-20):"
                read -r new_count
                if [[ "$new_count" =~ ^[0-9]+$ ]] && [ "$new_count" -ge 1 ] && [ "$new_count" -le 20 ]; then
                    BACKUP_COUNT="$new_count"
                    save_config
                    log_success "Yedek sayısı değiştirildi: $new_count"
                else
                    log_error "Geçersiz sayı! (1-20 arası olmalı)"
                fi
                wait_for_enter
                ;;
            4)
                check_for_updates
                wait_for_enter
                ;;
            5)
                echo
                echo -e "${YELLOW}Ayarları sıfırlamak istediğinize emin misiniz? (e/h):${NC}"
                read -r reset_confirm
                if [[ "$reset_confirm" == "e" ]]; then
                    DEFAULT_THEME="dracula"
                    AUTO_UPDATE="false"
                    BACKUP_COUNT="5"
                    save_config
                    log_success "Ayarlar sıfırlandı"
                fi
                wait_for_enter
                ;;
            *)
                log_error "Geçersiz seçim"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# 9 - KALDIRMA
# ============================================================================

do_uninstall() {
    uninstall_all
    wait_for_enter
}

# ============================================================================
# ANA ROUTER
# ============================================================================

route_choice() {
    local choice=$1

    # Input validation
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        log_error "Geçersiz girdi: sadece sayı girebilirsiniz"
        sleep 2
        return 1
    fi

    case $choice in
        1) do_full_install ;;
        2) do_modular_install ;;
        3) do_change_theme ;;
        4) do_tools ;;
        5) do_tmux ;;
        6) do_health_and_diagnostics ;;
        7) do_backups ;;
        8) do_settings ;;
        9) do_uninstall ;;
        0)
            log_info "Çıkılıyor..."
            exit 0
            ;;
        *)
            log_error "Geçersiz seçim: $choice"
            sleep 2
            ;;
    esac
}
