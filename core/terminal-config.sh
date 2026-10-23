#!/bin/bash

# ============================================================================
# Terminal Setup - Konfigürasyon ve Tema Yönetimi
# v5.0.2 - Config Module
# ============================================================================

install_tmux() {
    log_info "Tmux kuruluyor..."
    
    if command -v tmux &> /dev/null; then
        log_warning "Tmux zaten kurulu, atlanıyor..."
        return 0
    fi
    
    if ! sudo -E apt install -y -qq tmux &>/dev/null; then
        log_error "Tmux kurulumu başarısız!"
        return 1
    fi
    
    log_success "Tmux kuruldu"
    return 0
}

configure_tmux_theme() {
    local theme=$1
    log_info "Tmux için $theme teması yapılandırılıyor..."
    
    local tmux_conf="$HOME/.tmux.conf"
    
    if [[ -f "$tmux_conf" ]]; then
        local backup_name="${tmux_conf}.backup_$(date +%Y%m%d_%H%M%S)"
        cp "$tmux_conf" "$backup_name"
        log_debug "Mevcut tmux.conf yedeklendi: $backup_name"
    fi
    
    cat > "$tmux_conf" << 'EOF'
unbind C-b
set -g prefix C-a
bind C-a send-prefix
set -g mouse on
set -g default-terminal "screen-256color"
set -g base-index 1
setw -g pane-base-index 1
set -sg escape-time 0
set -g history-limit 10000
set -g renumber-windows on

EOF
    
    case $theme in
        dracula) get_tmux_theme_dracula >> "$tmux_conf" ;;
        nord) get_tmux_theme_nord >> "$tmux_conf" ;;
        gruvbox) get_tmux_theme_gruvbox >> "$tmux_conf" ;;
        tokyo-night) get_tmux_theme_tokyo_night >> "$tmux_conf" ;;
        catppuccin) get_tmux_theme_catppuccin >> "$tmux_conf" ;;
        one-dark) get_tmux_theme_one_dark >> "$tmux_conf" ;;
        solarized) get_tmux_theme_solarized >> "$tmux_conf" ;;
    esac
    
    cat >> "$tmux_conf" << 'EOF'

set -g status-left-length 40
set -g status-left "#[bold] Session: #S "
set -g status-right "#[bold] %d %b %Y | %H:%M "
set -g status-justify centre
setw -g window-status-format " #I:#W "
setw -g window-status-current-format " #I:#W "
EOF
    
    log_success "Tmux tema konfigürasyonu tamamlandı"
    return 0
}

install_tmux_with_theme() {
    local theme=$1
    install_tmux || return 1
    configure_tmux_theme "$theme" || return 1
    log_info "Tmux'u test etmek için: tmux"
    return 0
}

# ============================================================================
# TEMA KURULUMU
# ============================================================================

install_theme() {
    local theme_name=$1
    log_info "Tema kuruluyor: $theme_name"
    
    local terminal=$(detect_terminal)
    log_debug "Tespit edilen terminal: $terminal"
    
    case $terminal in
        gnome-terminal) install_theme_gnome "$theme_name" ;;
        kitty) install_theme_kitty "$theme_name" ;;
        alacritty) install_theme_alacritty "$theme_name" ;;
        *)
            log_warning "Terminal tipi desteklenmiyor: $terminal"
            return 1
            ;;
    esac
}

install_theme_gnome() {
    local theme=$1
    
    if ! check_gnome_terminal; then
        return 1
    fi
    
    # Tema dosyasını yükle (ÖNCELİKLE!)
    local theme_file="$SCRIPT_DIR/themes/${theme}.sh"
    if [[ -f "$theme_file" ]]; then
        # shellcheck source=/dev/null
        source "$theme_file"
        log_debug "Tema dosyası yüklendi: $theme_file"
    else
        log_error "Tema dosyası bulunamadı: $theme_file"
        return 1
    fi
    
    local PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d \')
    
    if [[ -z "$PROFILE" ]]; then
        log_error "Terminal profili bulunamadı"
        return 1
    fi
    
    local PROFILE_PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/"
    
    case $theme in
        dracula) apply_dracula_gnome "$PROFILE_PATH" ;;
        nord) apply_nord_gnome "$PROFILE_PATH" ;;
        gruvbox) apply_gruvbox_gnome "$PROFILE_PATH" ;;
        tokyo-night) apply_tokyo_night_gnome "$PROFILE_PATH" ;;
        catppuccin) apply_catppuccin_gnome "$PROFILE_PATH" ;;
        one-dark) apply_one_dark_gnome "$PROFILE_PATH" ;;
        solarized) apply_solarized_gnome "$PROFILE_PATH" ;;
        *) log_error "Bilinmeyen tema: $theme"; return 1 ;;
    esac
    
    return 0
}

install_theme_kitty() {
    local theme=$1
    
    if ! command -v kitty &> /dev/null; then
        log_warning "Kitty terminal bulunamadı"
        return 1
    fi
    
    # Tema dosyasını yükle (ÖNCELİKLE!)
    local theme_file="$SCRIPT_DIR/themes/${theme}.sh"
    if [[ -f "$theme_file" ]]; then
        # shellcheck source=/dev/null
        source "$theme_file"
        log_debug "Tema dosyası yüklendi: $theme_file"
    else
        log_error "Tema dosyası bulunamadı: $theme_file"
        return 1
    fi
    
    local kitty_conf="$HOME/.config/kitty/kitty.conf"
    local theme_dir="$HOME/.config/kitty/themes"
    
    if ! mkdir -p "$theme_dir"; then
        log_error "Tema dizini oluşturulamadı"
        return 1
    fi
    
    # DÜZELTME: macOS uyumluluğu
    if [[ -f "$kitty_conf" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/^include themes\//d' "$kitty_conf"
        else
            sed -i '/^include themes\//d' "$kitty_conf"
        fi
    else
        touch "$kitty_conf"
    fi
    
    case $theme in
        dracula)
            get_kitty_theme_dracula > "$theme_dir/dracula.conf"
            echo "include themes/dracula.conf" >> "$kitty_conf"
            ;;
        nord)
            get_kitty_theme_nord > "$theme_dir/nord.conf"
            echo "include themes/nord.conf" >> "$kitty_conf"
            ;;
        gruvbox)
            get_kitty_theme_gruvbox > "$theme_dir/gruvbox.conf"
            echo "include themes/gruvbox.conf" >> "$kitty_conf"
            ;;
        tokyo-night)
            get_kitty_theme_tokyo_night > "$theme_dir/tokyo-night.conf"
            echo "include themes/tokyo-night.conf" >> "$kitty_conf"
            ;;
        catppuccin)
            get_kitty_theme_catppuccin > "$theme_dir/catppuccin.conf"
            echo "include themes/catppuccin.conf" >> "$kitty_conf"
            ;;
        one-dark)
            get_kitty_theme_one_dark > "$theme_dir/one-dark.conf"
            echo "include themes/one-dark.conf" >> "$kitty_conf"
            ;;
        solarized)
            get_kitty_theme_solarized > "$theme_dir/solarized.conf"
            echo "include themes/solarized.conf" >> "$kitty_conf"
            ;;
    esac
    
    log_success "Kitty için $theme teması kuruldu"
    return 0
}

install_theme_alacritty() {
    local theme=$1
    
    if ! command -v alacritty &> /dev/null; then
        log_warning "Alacritty terminal bulunamadı"
        return 1
    fi
    
    # Tema dosyasını yükle (ÖNCELİKLE!)
    local theme_file="$SCRIPT_DIR/themes/${theme}.sh"
    if [[ -f "$theme_file" ]]; then
        # shellcheck source=/dev/null
        source "$theme_file"
        log_debug "Tema dosyası yüklendi: $theme_file"
    else
        log_error "Tema dosyası bulunamadı: $theme_file"
        return 1
    fi
    
    local alacritty_conf="$HOME/.config/alacritty/alacritty.yml"
    
    if ! mkdir -p "$(dirname "$alacritty_conf")"; then
        log_error "Alacritty config dizini oluşturulamadı"
        return 1
    fi
    
    # DÜZELTME: macOS uyumluluğu
    if [[ -f "$alacritty_conf" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/^colors:/,/^[^ ]/{ /^colors:/d; /^[^ ]/!d }' "$alacritty_conf"
        else
            sed -i '/^colors:/,/^[^ ]/{ /^colors:/d; /^[^ ]/!d }' "$alacritty_conf"
        fi
    fi
    
    case $theme in
        dracula) get_alacritty_theme_dracula >> "$alacritty_conf" ;;
        nord) get_alacritty_theme_nord >> "$alacritty_conf" ;;
        gruvbox) get_alacritty_theme_gruvbox >> "$alacritty_conf" ;;
        tokyo-night) get_alacritty_theme_tokyo_night >> "$alacritty_conf" ;;
        catppuccin) get_alacritty_theme_catppuccin >> "$alacritty_conf" ;;
        one-dark) get_alacritty_theme_one_dark >> "$alacritty_conf" ;;
        solarized) get_alacritty_theme_solarized >> "$alacritty_conf" ;;
    esac
    
    log_success "Alacritty için $theme teması kuruldu"
    return 0
}

# ============================================================================
# BASH ALIASES MİGRASYONU
# ============================================================================

migrate_bash_aliases() {
    log_info "Bash aliases kontrolü yapılıyor..."
    
    local aliases_files=("$HOME/.aliases" "$HOME/.bash_aliases")
    local found_aliases=false
    
    for alias_file in "${aliases_files[@]}"; do
        if [[ -f "$alias_file" ]]; then
            show_step_success "Bulundu: $alias_file"
            found_aliases=true
            
            local alias_basename
            alias_basename=$(basename "$alias_file")
            
            # DÜZELTME: File check eklendi
            if [[ -f ~/.zshrc ]] && grep -q "source.*${alias_basename}" ~/.zshrc 2>/dev/null; then
                show_step_skip "${alias_basename} zaten .zshrc içinde tanımlı"
            else
                show_user_prompt "BASH ALIASES BULUNDU" \
                    "$alias_file dosyanız mevcut." \
                    "Zsh'de de kullanmak ister misiniz?" \
                    ""
                echo -n "Eklemek için (e/h): "
                read -r add_aliases
                
                if [[ "$add_aliases" == "e" ]]; then
                    {
                        echo ""
                        echo "# Bash aliases compatibility"
                        echo "if [[ -f $alias_file ]]; then"
                        echo "    source $alias_file"
                        echo "fi"
                    } >> ~/.zshrc
                    
                    show_step_success "$alias_file .zshrc'ye eklendi"
                else
                    show_step_skip "Atlandı"
                fi
            fi
        fi
    done
    
    if ! $found_aliases; then
        log_debug "Bash aliases dosyası bulunamadı"
    fi
    
    return 0
}

# ============================================================================
# SHELL DEĞİŞTİRME
# ============================================================================

configure_gnome_terminal_login_shell() {
    if ! command -v gsettings &> /dev/null; then
        log_debug "gsettings bulunamadı, GNOME Terminal ayarı atlanıyor"
        return 0
    fi
    
    log_info "GNOME Terminal login shell ayarı yapılıyor..."
    
    local PROFILE_ID
    PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d \')
    
    if [[ -z "$PROFILE_ID" ]]; then
        log_debug "GNOME Terminal profili bulunamadı"
        return 0
    fi
    
    local PROFILE_PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/"
    
    local current_setting
    current_setting=$(gsettings get "$PROFILE_PATH" login-shell 2>/dev/null)
    
    if [[ "$current_setting" == "true" ]]; then
        log_success "GNOME Terminal zaten login shell modunda"
    else
        if gsettings set "$PROFILE_PATH" login-shell true 2>/dev/null; then
            log_success "GNOME Terminal login shell olarak ayarlandı"
        else
            log_warning "GNOME Terminal ayarı yapılamadı"
            return 1
        fi
    fi
    
    return 0
}

# Shell değiştirme implementation (reliability wrapper ile)
_change_default_shell_impl() {
    log_info "Varsayılan shell Zsh olarak ayarlanıyor..."
    
    # Zsh yolunu bul
    local ZSH_PATH
    ZSH_PATH=$(which zsh 2>/dev/null)
    
    if [[ -z "$ZSH_PATH" ]]; then
        log_error "Zsh bulunamadı!"
        return 1
    fi
    
    # Doğrula: Zsh gerçekten kurulu mu?
    if ! verify_command_installed "zsh" "Zsh"; then
        log_error "Zsh kurulu değil!"
        return 1
    fi
    
    # Mevcut shell'i kontrol et
    local CURRENT_SHELL
    CURRENT_SHELL=$(grep "^$USER:" /etc/passwd | cut -d: -f7)
    
    if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
        show_step_skip "Zaten Zsh aktif"
        configure_gnome_terminal_login_shell
        return 0
    fi
    
    show_step_info "Shell değiştiriliyor: $CURRENT_SHELL → $ZSH_PATH"
    
    # Şifre uyarısı
    echo
    echo -e "${YELLOW}┌───────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${BOLD}Shell değiştirmek için şifre gerekli${NC}"
    echo -e "${YELLOW}│${NC} Lütfen kullanıcı şifrenizi girin:"
    echo -e "${YELLOW}└───────────────────────────────────────────┘${NC}"
    echo
    
    # chsh komutu ile shell değiştir
    if chsh -s "$ZSH_PATH" 2>&1 | tee -a "$LOG_FILE"; then
        show_step_success "Sistem shell'i Zsh olarak ayarlandı"
        
        # Doğrulama: Gerçekten değişti mi?
        local NEW_SHELL
        NEW_SHELL=$(grep "^$USER:" /etc/passwd | cut -d: -f7)
        
        if [[ "$NEW_SHELL" != "$ZSH_PATH" ]]; then
            # Başarısız, sudo ile dene
            show_step_info "sudo ile deneniyor..."
            
            if ! sudo chsh -s "$ZSH_PATH" "$USER" 2>&1 | tee -a "$LOG_FILE"; then
                log_error "Shell değiştirilemedi"
                
                # Permission hatası olabilir
                if ! sudo -n true 2>/dev/null; then
                    handle_permission_error "Shell değiştirme"
                fi
                
                return 1
            fi
            
            # Tekrar doğrula
            NEW_SHELL=$(grep "^$USER:" /etc/passwd | cut -d: -f7)
            if [[ "$NEW_SHELL" != "$ZSH_PATH" ]]; then
                log_error "Shell değiştirilemedi (doğrulama başarısız)"
                return 1
            fi
        fi
    else
        log_error "Shell değiştirilemedi"
        
        # Permission hatası olabilir
        if ! sudo -n true 2>/dev/null; then
            handle_permission_error "Shell değiştirme"
        fi
        
        return 1
    fi
    
    # GNOME Terminal ayarlarını yapılandır
    configure_gnome_terminal_login_shell
    
    log_success "Shell başarıyla Zsh olarak ayarlandı ve doğrulandı"
    return 0
}

# Shell değiştirme wrapper (transaction ile)
change_default_shell() {
    with_transaction "Shell Değiştirme" _change_default_shell_impl
}

# ============================================================================
# KALDIRMA
# ============================================================================

reset_terminal_profile() {
    log_info "Terminal profil ayarları sıfırlanıyor..."
    
    if ! command -v gsettings &> /dev/null; then
        log_warning "gsettings bulunamadı, terminal ayarları sıfırlanamadı"
        return 1
    fi
    
    local PROFILE
    PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d \')
    
    if [[ -z "$PROFILE" ]]; then
        log_warning "Terminal profili bulunamadı"
        return 1
    fi
    
    local PROFILE_PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/"
    
    show_step_info "Renk teması varsayılana döndürülüyor..."
    
    gsettings set "$PROFILE_PATH" use-theme-colors true 2>/dev/null
    gsettings reset "$PROFILE_PATH" background-color 2>/dev/null
    gsettings reset "$PROFILE_PATH" foreground-color 2>/dev/null
    gsettings reset "$PROFILE_PATH" palette 2>/dev/null
    gsettings reset "$PROFILE_PATH" visible-name 2>/dev/null
    
    show_step_success "Terminal ayarları sıfırlandı"
    return 0
}

save_original_state() {
    local state_file="$BACKUP_DIR/original_state.txt"
    
    log_info "Orijinal sistem durumu kaydediliyor..."
    
    cat > "$state_file" << EOF
# Kurulum öncesi sistem durumu
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
ORIGINAL_SHELL=$SHELL
USER=$USER

# Terminal profili
EOF
    
    if command -v gsettings &> /dev/null; then
        local PROFILE
        PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d \')
        if [[ -n "$PROFILE" ]]; then
            local PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/"
            {
                echo "PROFILE=$PROFILE"
                echo "USE_THEME_COLORS=$(gsettings get "$PATH" use-theme-colors 2>/dev/null)"
                echo "BG_COLOR=$(gsettings get "$PATH" background-color 2>/dev/null)"
                echo "FG_COLOR=$(gsettings get "$PATH" foreground-color 2>/dev/null)"
            } >> "$state_file"
        fi
    fi
    
    log_success "Orijinal durum kaydedildi: $state_file"
    return 0
}

restore_original_state() {
    local state_file="$BACKUP_DIR/original_state.txt"
    
    if [[ ! -f "$state_file" ]]; then
        log_warning "Orijinal durum dosyası bulunamadı"
        return 1
    fi
    
    log_info "Orijinal duruma geri dönülüyor..."
    
    # shellcheck source=/dev/null
    source "$state_file"
    
    if [[ -n "$ORIGINAL_SHELL" ]] && command -v "$ORIGINAL_SHELL" &> /dev/null; then
        show_step_info "Shell geri yükleniyor: $ORIGINAL_SHELL"
        sudo chsh -s "$ORIGINAL_SHELL" "$USER" 2>&1 | tee -a "$LOG_FILE" >/dev/null
    fi
    
    if [[ -n "$PROFILE" ]] && command -v gsettings &> /dev/null; then
        local PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/"
        
        show_step_info "Terminal renkleri geri yükleniyor..."
        
        if [[ "$USE_THEME_COLORS" == "true" ]]; then
            gsettings set "$PATH" use-theme-colors true 2>/dev/null
        else
            [[ -n "$BG_COLOR" ]] && gsettings set "$PATH" background-color "$BG_COLOR" 2>/dev/null
            [[ -n "$FG_COLOR" ]] && gsettings set "$PATH" foreground-color "$FG_COLOR" 2>/dev/null
        fi
    fi
    
    log_success "Orijinal durum geri yüklendi"
    return 0
}

uninstall_all() {
    local force_mode=false
    
    if [[ "$1" == "--force" ]]; then
        force_mode=true
        log_warning "ZORLAMALI KALDIRMA MODU - Otomatik onay aktif!"
        echo
        echo -e "${RED}UYARI: Kurduğunuz HER ŞEY silinecek!${NC}"
        echo "5 saniye içinde iptal etmek için CTRL+C basın..."
        sleep 5
    fi
    
    if [[ "$force_mode" == false ]]; then
        echo
        echo -e "${RED}╔═══════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}  ${BOLD}TÜM ÖZELLEŞTİRMELER KALDIRILACAK${NC}      ${RED}║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════╝${NC}"
        echo
        echo -e "${YELLOW}Bu işlem şunları kaldıracak:${NC}"
        echo "  • Zsh paketi (--purge ile)"
        echo "  • Oh My Zsh ve Powerlevel10k"
        echo "  • Tüm Zsh config dosyaları"
        echo "  • FZF, Zoxide, Exa, Bat"
        echo "  • Ripgrep, fd, delta, lazygit"
        echo "  • TLDR, btop, dust, duf, procs, atuin"
        echo "  • MesloLGS fontları"
        echo "  • Tmux ve yapılandırmaları"
        echo "  • Terminal renk ayarları"
        echo
        echo -e "${RED}${BOLD}Bu işlem GERİ ALINMAZ!${NC}"
        echo
        echo -n "Emin misiniz? (e/h): "
        read -r confirm
        
        if [[ "$confirm" != "e" ]]; then
            log_info "İptal edildi"
            return 0
        fi
    fi
    
    echo
    echo -e "${CYAN}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}   TAM KALDIRMA İŞLEMİ BAŞLIYOR           ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════╝${NC}"
    
    local total_steps=19
    local current_step=0
    local errors=0
    
    # 1. Terminal profil ayarları
    echo
    show_section $((++current_step)) $total_steps "Terminal profil ayarları sıfırlanıyor"
    if reset_terminal_profile; then
        show_step_success "Terminal varsayılan renklerine döndü"
    else
        show_step_skip "Terminal ayarları sıfırlanamadı"
        ((errors++))
    fi
    
    # 2. Shell'i bash'e döndür
    show_section $((++current_step)) $total_steps "Shell Bash'e döndürülüyor"
    if command -v bash &> /dev/null; then
        local bash_path
        bash_path=$(which bash)
        
        if [[ "$SHELL" == "$bash_path" ]]; then
            show_step_skip "Zaten Bash kullanılıyor"
        else
            show_step_info "Bash'e geçiliyor..."
            if sudo chsh -s "$bash_path" "$USER" 2>&1 | tee -a "$LOG_FILE" >/dev/null; then
                show_step_success "Shell başarıyla Bash olarak ayarlandı"
            else
                log_error "Shell değiştirilemedi"
                ((errors++))
            fi
        fi
    fi
    
    # 3. Oh My Zsh ve Powerlevel10k
    show_section $((++current_step)) $total_steps "Oh My Zsh ve Powerlevel10k kaldırılıyor"
    if [[ -d ~/.oh-my-zsh ]]; then
        rm -rf ~/.oh-my-zsh 2>&1 | tee -a "$LOG_FILE" >/dev/null && show_step_success "Oh My Zsh kaldırıldı"
    else
        show_step_skip "Oh My Zsh zaten yok"
    fi
    
    # 4. Zsh config dosyaları
    show_section $((++current_step)) $total_steps "Zsh konfigürasyon dosyaları siliniyor"
    local zsh_files=("~/.zshrc" "~/.zsh_history" "~/.p10k.zsh" "~/.zshenv" "~/.zprofile" "~/.zlogin" "~/.zcompdump"*)
    local removed_count=0
    for file in "${zsh_files[@]}"; do
        local expanded_file="${file/#\~/$HOME}"
        if [[ -f "$expanded_file" ]] || [[ "$expanded_file" == *"*"* ]]; then
            rm -f $expanded_file 2>/dev/null && ((removed_count++))
        fi
    done
    [[ $removed_count -gt 0 ]] && show_step_success "$removed_count dosya silindi" || show_step_skip "Silinecek dosya yok"
    
    # 5. Tmux kaldır
    show_section $((++current_step)) $total_steps "Tmux kaldırılıyor"
    if command -v tmux &> /dev/null; then
        sudo apt remove --purge -y tmux 2>&1 | tee -a "$LOG_FILE" >/dev/null && show_step_success "Tmux kaldırıldı"
    else
        show_step_skip "Tmux zaten yok"
    fi
    [[ -f ~/.tmux.conf ]] && rm -f ~/.tmux.conf && show_step_success ".tmux.conf silindi"
    
    # 6. FZF
    show_section $((++current_step)) $total_steps "FZF kaldırılıyor"
    if [[ -d ~/.fzf ]]; then
        rm -rf ~/.fzf && show_step_success "FZF kaldırıldı"
    else
        show_step_skip "FZF zaten yok"
    fi
    
    # 7. Zoxide
    show_section $((++current_step)) $total_steps "Zoxide kaldırılıyor"
    if command -v zoxide &> /dev/null; then
        local zoxide_bin
        zoxide_bin=$(which zoxide)
        sudo rm -f "$zoxide_bin" 2>/dev/null && show_step_success "Zoxide kaldırıldı"
    else
        show_step_skip "Zoxide zaten yok"
    fi
    
    # 8. Exa ve Bat
    show_section $((++current_step)) $total_steps "Exa ve Bat kaldırılıyor"
    sudo apt remove --purge -y exa bat 2>&1 | tee -a "$LOG_FILE" >/dev/null && show_step_success "Exa ve Bat kaldırıldı"
    
    # 9. Ripgrep
    show_section $((++current_step)) $total_steps "Ripgrep kaldırılıyor"
    if command -v rg &> /dev/null; then
        sudo apt remove --purge -y ripgrep 2>&1 | tee -a "$LOG_FILE" >/dev/null && show_step_success "Ripgrep kaldırıldı"
    else
        show_step_skip "Ripgrep zaten yok"
    fi
    
    # 10. fd-find
    show_section $((++current_step)) $total_steps "fd-find kaldırılıyor"
    if command -v fd &> /dev/null || command -v fdfind &> /dev/null; then
        sudo apt remove --purge -y fd-find 2>&1 | tee -a "$LOG_FILE" >/dev/null && show_step_success "fd-find kaldırıldı"
    else
        show_step_skip "fd-find zaten yok"
    fi
    
    # 11. Git-delta, Lazygit
    show_section $((++current_step)) $total_steps "Git araçları kaldırılıyor"
    [[ -f /usr/local/bin/delta ]] && sudo rm -f /usr/local/bin/delta && show_step_success "Delta kaldırıldı"
    [[ -f /usr/local/bin/lazygit ]] && sudo rm -f /usr/local/bin/lazygit && show_step_success "Lazygit kaldırıldı"
    
    # 12. Sistem araçları (btop, dust, duf, procs)
    show_section $((++current_step)) $total_steps "Sistem araçları kaldırılıyor"
    sudo apt remove --purge -y btop dust duf 2>&1 | tee -a "$LOG_FILE" >/dev/null
    [[ -f /usr/local/bin/procs ]] && sudo rm -f /usr/local/bin/procs
    show_step_success "Sistem araçları kaldırıldı"
    
    # 13. TLDR ve Atuin
    show_section $((++current_step)) $total_steps "TLDR ve Atuin kaldırılıyor"
    sudo apt remove --purge -y tldr 2>&1 | tee -a "$LOG_FILE" >/dev/null
    [[ -f /usr/local/bin/atuin ]] && sudo rm -f /usr/local/bin/atuin
    [[ -d ~/.local/share/atuin ]] && rm -rf ~/.local/share/atuin
    show_step_success "TLDR ve Atuin kaldırıldı"
    
    # 14. Fontlar
    show_section $((++current_step)) $total_steps "Fontlar kaldırılıyor"
    local FONT_DIR=~/.local/share/fonts
    if [[ -d "$FONT_DIR" ]]; then
        rm -f "$FONT_DIR"/MesloLGS*.ttf 2>/dev/null
        command -v fc-cache &> /dev/null && fc-cache -f "$FONT_DIR" > /dev/null 2>&1
        show_step_success "MesloLGS fontları kaldırıldı"
    else
        show_step_skip "Font klasörü yok"
    fi
    
    # 15. Zsh paketi (--purge ile)
    show_section $((++current_step)) $total_steps "Zsh paketi kaldırılıyor"
    sudo apt remove --purge -y zsh 2>&1 | tee -a "$LOG_FILE" >/dev/null && show_step_success "Zsh paketi tamamen kaldırıldı"
    
    # 16. Plugin config dosyaları
    show_section $((++current_step)) $total_steps "Plugin config dosyaları siliniyor"
    local plugin_files=("~/.fzf.zsh" "~/.config/atuin" "~/.local/share/atuin")
    local plugin_removed=0
    for pfile in "${plugin_files[@]}"; do
        local expanded="${pfile/#\~/$HOME}"
        if [[ -e "$expanded" ]]; then
            rm -rf "$expanded" 2>/dev/null && ((plugin_removed++))
        fi
    done
    [[ $plugin_removed -gt 0 ]] && show_step_success "$plugin_removed config silindi" || show_step_skip "Config yok"
    
    # 17. Zsh plugin dizinleri
    show_section $((++current_step)) $total_steps "Zsh plugin dizinleri siliniyor"
    local plugin_dirs=(
        "~/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
        "~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
        "~/.oh-my-zsh/custom/plugins/fast-syntax-highlighting"
    )
    for pdir in "${plugin_dirs[@]}"; do
        local expanded="${pdir/#\~/$HOME}"
        [[ -d "$expanded" ]] && rm -rf "$expanded" 2>/dev/null
    done
    show_step_success "Plugin dizinleri temizlendi"
    
    # 18. Script'in kendi dizinleri
    show_section $((++current_step)) $total_steps "Script dizinleri siliniyor"
    if [[ -d "$BASE_DIR" ]]; then
        rm -rf "$BASE_DIR" 2>/dev/null && show_step_success "~/.terminal-setup silindi"
    else
        show_step_skip "Script dizini yok"
    fi
    
    # 19. Autoremove
    show_section $((++current_step)) $total_steps "Gereksiz paketler temizleniyor"
    sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE" >/dev/null && show_step_success "Sistem temizlendi"
    
    echo
    echo -e "${CYAN}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}   KALDIRMA ÖZETİ                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════╝${NC}"
    echo -e "  Tamamlanan adımlar: ${current_step}/${total_steps}"
    echo -e "  Hatalar: ${errors}"
    
    if [ $errors -eq 0 ]; then
        echo
        echo -e "${GREEN}✓ Kaldırma başarıyla tamamlandı!${NC}"
        echo
        echo -e "${YELLOW}ÖNEMLİ:${NC}"
        echo "  1. Terminal'i KAPAT ve TEKRAR AÇ"
        echo "  2. Renklerin normal göründüğünü kontrol et"
        echo "  3. 'echo \$SHELL' ile shell'in bash olduğunu kontrol et"
    else
        echo
        echo -e "${YELLOW}Kaldırma tamamlandı ama $errors hata oluştu${NC}"
        echo "  Detaylar için: cat $LOG_FILE"
    fi
    
    return 0
}