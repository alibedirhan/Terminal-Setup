#!/bin/bash

# ============================================================================
# Terminal Setup - CLI Araçları Kurulumu
# v5.0.2 - Tools Module
# ============================================================================

install_fzf() {
    log_info "FZF kuruluyor..."
    
    # Zaten kurulu mu?
    if command -v fzf &> /dev/null; then
        log_warning "FZF zaten kurulu, atlanıyor..."
        return 0
    fi
    
    # İnternet kontrolü + recovery
    if ! check_internet; then
        if ! handle_network_error "FZF kurulumu"; then
            return 1
        fi
        if ! check_internet; then
            return 1
        fi
    fi
    
    # Clone repository (safe_git_clone ile)
    if [[ ! -d ~/.fzf ]]; then
        if ! safe_git_clone "https://github.com/junegunn/fzf.git" ~/.fzf 1; then
            log_error "FZF klonlama başarısız!"
            return 1
        fi
    fi
    
    # Install (retry ile) - DÜZELTME: --all ve --no-bash çelişkisi giderildi
    log_info "FZF install scripti çalıştırılıyor..."
    
    # Verbose mode ile çalıştır ve log'a kaydet
    local install_output
    install_output=$(~/.fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish 2>&1)
    local install_exit=$?
    
    # Log'a yaz
    echo "$install_output" | tee -a "$LOG_FILE" >/dev/null
    
    if [[ $install_exit -ne 0 ]]; then
        log_error "FZF kurulumu başarısız!"
        log_info "Hata çıktısı: ${install_output:0:200}"
        log_info "Manuel kurulum: cd ~/.fzf && ./install --all"
        return 1
    fi
    
    log_success "FZF install scripti başarılı"
    
    # PATH'e ekle
    export PATH="$HOME/.fzf/bin:$PATH"
    
    # Doğrulama
    if ! verify_command_installed "fzf" "FZF"; then
        log_error "FZF kuruldu ancak doğrulanamadı!"
        log_warning "~/.zshrc dosyasını yeniden yükleyin: source ~/.zshrc"
        return 1
    fi
    
    # Çalışma testi
    if ! fzf --version &>/dev/null; then
        log_error "FZF binary'si çalışmıyor!"
        return 1
    fi
    
    log_success "FZF kuruldu ve doğrulandı ($(fzf --version))"
    return 0
}

install_zoxide() {
    log_info "Zoxide kuruluyor..."

    if command -v zoxide &> /dev/null; then
        log_warning "Zoxide zaten kurulu, atlanıyor..."
        return 0
    fi

    if ! check_internet; then
        if ! handle_network_error "Zoxide kurulumu"; then
            return 1
        fi
        if ! check_internet; then
            return 1
        fi
    fi

    local installer
    installer=$(mktemp -t zoxide-install.XXXXXXXXXX.sh) || {
        log_error "Geçici dosya oluşturulamadı"
        return 1
    }

    log_info "Zoxide install script indiriliyor..."
    if ! safe_download "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh" "$installer" "Zoxide install script indiriliyor"; then
        rm -f -- "$installer"
        log_error "Zoxide install script indirilemedi"
        return 1
    fi

    if ! bash "$installer" >> "$LOG_FILE" 2>&1; then
        rm -f -- "$installer"
        log_error "Zoxide kurulumu başarısız!"
        log_info "Manuel kurulum: https://github.com/ajeetdsouza/zoxide"
        return 1
    fi
    rm -f -- "$installer"

    if [[ -f ~/.zshrc ]]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc; then
            sed -i '/# Enable Powerlevel10k instant prompt/i export PATH="$HOME/.local/bin:$PATH"\n' ~/.zshrc
        fi

        if ! grep -q "zoxide init zsh" ~/.zshrc; then
            {
                echo ''
                echo '# Zoxide initialization'
                echo 'eval "$(zoxide init zsh)"'
            } >> ~/.zshrc
        fi
    fi

    export PATH="$HOME/.local/bin:$PATH"
    hash -r

    if ! verify_command_installed "zoxide" "Zoxide"; then
        log_error "Zoxide kuruldu ancak PATH'te bulunamıyor!"
        log_warning 'Manuel çözüm: export PATH="$HOME/.local/bin:$PATH"'
        return 1
    fi

    if ! zoxide --version &>/dev/null; then
        log_error "Zoxide kuruldu ancak çalıştırılamıyor!"
        return 1
    fi

    log_success "Zoxide kuruldu ve doğrulandı ($(zoxide --version))"
    return 0
}

install_exa() {
    log_info "Exa/Eza kuruluyor..."
    
    # Zaten kurulu mu?
    if command -v eza &> /dev/null; then
        log_warning "Eza zaten kurulu, atlanıyor..."
        return 0
    fi
    
    if command -v exa &> /dev/null; then
        log_warning "Exa zaten kurulu, atlanıyor..."
        return 0
    fi
    
    local cmd=""
    
    # Önce eza paketini dene (Ubuntu 24.04+)
    if retry_command 3 0 sudo -E apt install -y -qq eza; then
        cmd="eza"
    else
        # Apt'den kurulamadı, GitHub'dan indir
        log_info "Apt'den kurulamadı, GitHub'dan indiriliyor..."
        
        # İnternet kontrolü
        if ! check_internet; then
            if ! handle_network_error "Eza kurulumu"; then
                return 1
            fi
        fi
        
        # Latest release version al (retry ile)
        local EZA_VERSION=$(retry_command 3 30 bash -c 'curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep -Po "\"tag_name\": \"v\K[^\"]*"')
        
        if [[ -z "$EZA_VERSION" ]]; then
            log_error "Eza versiyonu alınamadı!"
            return 1
        fi
        
        # Binary indir (safe_download ile)
        if ! safe_download "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" "eza.tar.gz" "Eza binary indiriliyor"; then
            log_error "Eza indirilemedi!"
            return 1
        fi
        
        # Extract ve kur
        tar xf eza.tar.gz &>/dev/null
        sudo install -m 755 eza /usr/local/bin/ &>/dev/null
        rm -f eza eza.tar.gz &>/dev/null
        
        cmd="eza"
    fi
    
    # Alias'ları ekle
    if [[ -f ~/.zshrc ]] && ! grep -q "alias ls=" ~/.zshrc; then
        {
            echo ''
            echo '# Eza/Exa aliases'
            echo "alias ls=\"$cmd --icons\""
            echo "alias ll=\"$cmd -l --icons\""
            echo "alias la=\"$cmd -la --icons\""
            echo "alias lt=\"$cmd --tree --icons\""
        } >> ~/.zshrc
    fi
    
    # Doğrulama
    if ! verify_command_installed "$cmd" "Eza"; then
        log_error "Eza kuruldu ancak doğrulanamadı!"
        return 1
    fi
    
    log_success "Eza kuruldu ve doğrulandı"
    return 0
}

install_bat() {
    log_info "Bat kuruluyor..."
    
    # Zaten kurulu mu?
    if command -v batcat &> /dev/null || command -v bat &> /dev/null; then
        log_warning "Bat zaten kurulu, atlanıyor..."
        return 0
    fi
    
    # Kurulum (retry ile)
    if ! retry_command 3 0 sudo -E apt install -y -qq bat; then
        log_error "Bat kurulumu başarısız!"
        return 1
    fi
    
    # Alias ekle
    if [[ -f ~/.zshrc ]] && ! grep -q "alias cat=" ~/.zshrc; then
        {
            echo ''
            echo '# Bat alias'
            echo 'alias cat="batcat"'
        } >> ~/.zshrc
    fi
    
    # Doğrulama
    if ! verify_command_installed "batcat" "Bat"; then
        log_error "Bat kuruldu ancak doğrulanamadı!"
        return 1
    fi
    
    log_success "Bat kuruldu ve doğrulandı"
    return 0
}

# ============================================================================
# GELİŞMİŞ ARAMA ARAÇLARI
# ============================================================================

install_ripgrep() {
    log_info "Ripgrep kuruluyor..."
    
    # Zaten kurulu mu?
    if command -v rg &> /dev/null; then
        log_warning "Ripgrep zaten kurulu, atlanıyor..."
        return 0
    fi
    
    # Kurulum (retry ile)
    if ! retry_command 3 0 sudo -E apt install -y -qq ripgrep; then
        log_error "Ripgrep kurulumu başarısız!"
        return 1
    fi
    
    # Config ekle
    if [[ -f ~/.zshrc ]] && ! grep -q "RIPGREP_CONFIG_PATH" ~/.zshrc; then
        {
            echo ''
            echo '# Ripgrep configuration'
            echo 'export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"'
        } >> ~/.zshrc
        
        cat > ~/.ripgreprc << 'EOF'
--max-columns=150
--max-columns-preview
--smart-case
--colors=line:none
--colors=line:style:bold
EOF
    fi
    
    # Doğrulama
    if ! verify_command_installed "rg" "Ripgrep"; then
        log_error "Ripgrep kuruldu ancak doğrulanamadı!"
        return 1
    fi
    
    log_success "Ripgrep kuruldu ve doğrulandı"
    return 0
}

install_fd() {
    log_info "Fd kuruluyor..."
    
    # Zaten kurulu mu?
    if command -v fd &> /dev/null || command -v fdfind &> /dev/null; then
        log_warning "Fd zaten kurulu, atlanıyor..."
        return 0
    fi
    
    # Kurulum (retry ile)
    if ! retry_command 3 0 sudo -E apt install -y -qq fd-find; then
        log_error "Fd kurulumu başarısız!"
        return 1
    fi
    
    # Ubuntu alias
    if [[ -f ~/.zshrc ]] && ! grep -q "alias fd=" ~/.zshrc; then
        {
            echo ''
            echo '# Fd alias (Ubuntu compatibility)'
            echo 'alias fd="fdfind"'
        } >> ~/.zshrc
    fi
    
    # FZF integration
    if [[ -f ~/.zshrc ]] && ! grep -q "FZF_DEFAULT_COMMAND.*fd" ~/.zshrc; then
        {
            echo ''
            echo '# FZF + fd integration'
            echo 'export FZF_DEFAULT_COMMAND="fdfind --type f --hidden --follow --exclude .git"'
            echo 'export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"'
        } >> ~/.zshrc
    fi
    
    # Doğrulama
    if ! verify_command_installed "fdfind" "Fd"; then
        log_error "Fd kuruldu ancak doğrulanamadı!"
        return 1
    fi
    
    log_success "Fd kuruldu ve doğrulandı"
    return 0
}

# ============================================================================
# GIT ARAÇLARI
# ============================================================================

install_delta() {
    log_info "Delta (git diff) kuruluyor..."
    
    # Zaten kurulu mu?
    if command -v delta &> /dev/null; then
        log_warning "Delta zaten kurulu, atlanıyor..."
        return 0
    fi
    
    # Önce apt'den dene (retry ile)
    if retry_command 3 0 sudo -E apt install -y -qq git-delta; then
        log_success "Delta apt'den kuruldu"
    else
        # Apt başarısız, cargo ile dene
        log_info "Apt'den kurulamadı, Cargo ile deneniyor..."
        
        # Internet kontrolü
        if ! check_internet; then
            if ! handle_network_error "Delta kurulumu"; then
                return 1
            fi
        fi
        
        # Cargo kontrolü
        if ! command -v cargo &> /dev/null; then
            log_info "Cargo (Rust) kuruluyor (Delta için gerekli)..."
            echo -e "${YELLOW}Bu işlem 2-3 dakika sürebilir, lütfen bekleyin...${NC}"
            
            # Rustup kurulum (geçici dosya ile)
            local rustup_installer
            rustup_installer=$(mktemp -t rustup-init.XXXXXXXXXX.sh) || {
                log_error "Geçici rustup dosyası oluşturulamadı"
                return 1
            }
            if ! safe_download "https://sh.rustup.rs" "$rustup_installer" "Rustup install script indiriliyor"; then
                rm -f -- "$rustup_installer"
                log_error "Cargo kurulumu için rustup indirilemedi!"
                return 1
            fi
            if ! retry_command 2 180 sh "$rustup_installer" -y; then
                rm -f -- "$rustup_installer"
                log_error "Cargo kurulumu başarısız!"
                return 1
            fi
            rm -f -- "$rustup_installer"
            
            # Cargo env yükle
            if [[ -f "$HOME/.cargo/env" ]]; then
                source "$HOME/.cargo/env"
            else
                log_error "Cargo env dosyası bulunamadı!"
                return 1
            fi
        fi
        
        # Delta kurulum
        log_info "Delta cargo ile kuruluyor (2-3 dakika sürebilir)..."
        echo -e "${YELLOW}Lütfen bekleyin, derleme yapılıyor...${NC}"
        
        if ! retry_command 2 300 cargo install git-delta; then
            log_error "Delta kurulumu başarısız!"
            log_warning "Alternatif: 'cargo install git-delta' manuel çalıştırın"
            return 1
        fi
    fi
    
    # Doğrulama
    if ! verify_command_installed "delta" "Delta"; then
        log_error "Delta kuruldu ama doğrulanamadı!"
        return 1
    fi
    
    # Git config
    git config --global core.pager "delta" 2>/dev/null
    git config --global interactive.diffFilter "delta --color-only" 2>/dev/null
    git config --global delta.navigate true 2>/dev/null
    git config --global delta.side-by-side true 2>/dev/null
    git config --global merge.conflictstyle "diff3" 2>/dev/null
    git config --global diff.colorMoved "default" 2>/dev/null
    
    log_success "Delta kuruldu ve git ile entegre edildi"
    return 0
}

install_lazygit() {
    log_info "Lazygit kuruluyor..."
    
    if command -v lazygit &> /dev/null; then
        log_warning "Lazygit zaten kurulu, atlanıyor..."
        return 0
    fi
    
    if ! check_internet; then
        log_error "İnternet bağlantısı gerekli!"
        return 1
    fi
    
    log_info "Lazygit latest version indiriliyor..."
    
    # GitHub API ile son versiyonu al
    local version=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        log_warning "GitHub API başarısız, v0.43.1 kullanılıyor..."
        version="0.43.1"
    fi
    
    log_debug "Lazygit version: v$version"
    
    # URL oluştur
    local url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_x86_64.tar.gz"
    
    # İndir
    log_info "İndiriliyor: lazygit v$version"
    
    if command -v wget &>/dev/null; then
        if ! wget -q --show-progress -O /tmp/lazygit.tar.gz "$url" 2>&1; then
            log_warning "wget başarısız, curl deneniyor..."
            if ! curl -fsSL -o /tmp/lazygit.tar.gz "$url" 2>&1; then
                log_error "İndirme başarısız!"
                return 1
            fi
        fi
    else
        if ! curl -fsSL -o /tmp/lazygit.tar.gz "$url" 2>&1; then
            log_error "İndirme başarısız!"
            return 1
        fi
    fi
    
    # Dosya kontrolü
    if [[ ! -f /tmp/lazygit.tar.gz ]]; then
        log_error "İndirilen dosya bulunamadı!"
        return 1
    fi
    
    # Dosya boyutu kontrolü
    local size=$(stat -f%z /tmp/lazygit.tar.gz 2>/dev/null || stat -c%s /tmp/lazygit.tar.gz 2>/dev/null)
    if [[ "$size" -lt 1000 ]]; then
        log_error "İndirilen dosya çok küçük (hatalı): ${size} bytes"
        rm -f /tmp/lazygit.tar.gz
        return 1
    fi
    
    log_debug "İndirildi: ${size} bytes"
    
    # Extract
    log_info "Arşiv açılıyor..."
    if ! tar -xzf /tmp/lazygit.tar.gz -C /tmp/ 2>&1; then
        log_error "Arşiv açılamadı! Dosya bozuk olabilir."
        rm -f /tmp/lazygit.tar.gz
        return 1
    fi
    
    # Binary kontrolü
    if [[ ! -f /tmp/lazygit ]]; then
        log_error "Lazygit binary'si arşivde bulunamadı!"
        rm -f /tmp/lazygit.tar.gz
        return 1
    fi
    
    # Kurulum
    log_info "Kuruluyor..."
    if ! sudo install -m 755 /tmp/lazygit /usr/local/bin/lazygit 2>&1; then
        log_error "Kurulum başarısız (izin hatası?)!"
        rm -f /tmp/lazygit.tar.gz /tmp/lazygit
        return 1
    fi
    
    # Temizlik
    rm -f /tmp/lazygit.tar.gz /tmp/lazygit
    
    # Doğrulama
    if command -v lazygit &>/dev/null; then
        local installed_version=$(lazygit --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        log_success "Lazygit kuruldu: v${installed_version:-$version}"
        return 0
    else
        log_error "Lazygit kuruldu ama çalıştırılamıyor!"
        return 1
    fi
}

# ============================================================================
# DÖKÜMANTASYON VE YARDIM ARAÇLARI
# ============================================================================

install_tldr() {
    log_info "TLDR kuruluyor..."
    
    # Zaten kurulu mu?
    if command -v tldr &> /dev/null; then
        log_warning "TLDR zaten kurulu, atlanıyor..."
        return 0
    fi
    
    # Kurulum (retry ile)
    export DEBIAN_FRONTEND=noninteractive
    
    if ! retry_command 3 0 sudo -E apt install -y -qq tldr; then
        log_error "TLDR kurulumu başarısız!"
        unset DEBIAN_FRONTEND
        return 1
    fi
    
    # İlk cache update (retry ile)
    retry_command 2 30 tldr --update || true
    
    # Doğrulama
    if ! verify_command_installed "tldr" "TLDR"; then
        log_error "TLDR kuruldu ancak doğrulanamadı!"
        unset DEBIAN_FRONTEND
        return 1
    fi
    
    log_success "TLDR kuruldu ve doğrulandı"
    unset DEBIAN_FRONTEND
    
    return 0
}

# ============================================================================
# SİSTEM İZLEME ARAÇLARI  
# ============================================================================

install_btop() {
    log_info "Btop++ kuruluyor..."
    
    # Zaten kurulu mu?
    if command -v btop &> /dev/null; then
        log_warning "Btop zaten kurulu, atlanıyor..."
        return 0
    fi
    
    # ← EKLE BURAYA
    export DEBIAN_FRONTEND=noninteractive
    
    # Kurulum (retry ile) - sudo'ya -E ekle, -qq ekle
    if ! retry_command 3 0 sudo -E apt install -y -qq btop; then
        log_error "Btop kurulumu başarısız!"
        unset DEBIAN_FRONTEND  # ← EKLE BURAYA
        return 1
    fi
    
    unset DEBIAN_FRONTEND  # ← EKLE BURAYA
    
    # Doğrulama
    if ! verify_command_installed "btop" "Btop"; then
        log_error "Btop kuruldu ancak doğrulanamadı!"
        return 1
    fi
    
    log_success "Btop kuruldu ve doğrulandı"
    return 0
}

install_dust() {
    log_info "Dust kuruluyor..."
    
    # Zaten kurulu mu?
    if command -v dust &> /dev/null; then
        log_warning "Dust zaten kurulu, atlanıyor..."
        return 0
    fi
    
    # Önce apt'den dene (retry ile)
    export DEBIAN_FRONTEND=noninteractive
    
    if retry_command 3 0 sudo -E apt install -y -qq du-dust; then
        unset DEBIAN_FRONTEND
        if verify_command_installed "dust" "Dust"; then
            log_success "Dust apt'den kuruldu ve doğrulandı"
            return 0
        fi
    fi
    
    unset DEBIAN_FRONTEND
    
    # Apt başarısız, GitHub'dan indir
    log_info "Apt'den kurulamadı, GitHub'dan indiriliyor..."
    
    # Internet kontrolü
    if ! check_internet; then
        if ! handle_network_error "Dust kurulumu"; then
            return 1
        fi
    fi
    
    # Version al (retry ile) - DÜZELTİLMİŞ REGEX
    local DUST_VERSION=$(curl -s "https://api.github.com/repos/bootandy/dust/releases/latest" 2>/dev/null | grep -Po '"tag_name":\s*"v\K[0-9.]+' | head -1)
    
    if [[ -z "$DUST_VERSION" ]]; then
        log_error "Dust versiyonu alınamadı!"
        return 1
    fi
    
    log_debug "Dust versiyonu: v${DUST_VERSION}"
    
    # Binary indir (safe_download ile)
    local download_url="https://github.com/bootandy/dust/releases/download/v${DUST_VERSION}/dust-v${DUST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
    
    if ! safe_download "$download_url" "dust.tar.gz" "Dust v${DUST_VERSION} indiriliyor"; then
        log_error "Dust indirilemedi!"
        return 1
    fi
    
    # Extract ve kur
    if ! tar xf dust.tar.gz &>/dev/null; then
        log_error "Dust arşivi açılamadı!"
        rm -f dust.tar.gz
        return 1
    fi
    
    local dust_bin=$(find . -name "dust" -type f 2>/dev/null | head -1)
    
    if [[ -n "$dust_bin" ]]; then
        if sudo install -m 755 "$dust_bin" /usr/local/bin/dust &>/dev/null; then
            rm -rf dust.tar.gz dust-v* &>/dev/null
            
            # Doğrulama
            if verify_command_installed "dust" "Dust"; then
                log_success "Dust GitHub'dan kuruldu ve doğrulandı"
                return 0
            else
                log_error "Dust kuruldu ancak doğrulanamadı!"
                return 1
            fi
        else
            log_error "Dust kurulamadı (izin hatası)"
            rm -rf dust.tar.gz dust-v* &>/dev/null
            return 1
        fi
    else
        log_error "Dust binary'si arşivde bulunamadı!"
        rm -rf dust.tar.gz dust-v* &>/dev/null
        return 1
    fi
}

install_duf() {
    log_info "Duf kuruluyor..."
    
    # Zaten kurulu mu?
    if command -v duf &> /dev/null; then
        log_warning "Duf zaten kurulu, atlanıyor..."
        return 0
    fi
    
    # Kurulum (retry ile)
    export DEBIAN_FRONTEND=noninteractive
    
    if ! retry_command 3 0 sudo -E apt install -y -qq duf; then
        log_error "Duf kurulumu başarısız!"
        unset DEBIAN_FRONTEND
        return 1
    fi
    
    # Doğrulama
    if ! verify_command_installed "duf" "Duf"; then
        log_error "Duf kuruldu ancak doğrulanamadı!"
        unset DEBIAN_FRONTEND
        return 1
    fi
    
    log_success "Duf kuruldu ve doğrulandı"
    unset DEBIAN_FRONTEND
    
    return 0
}

install_procs() {
    log_info "Procs kuruluyor..."
    
    # Zaten kurulu mu?
    if command -v procs &> /dev/null; then
        log_warning "Procs zaten kurulu, atlanıyor..."
        return 0
    fi
    
    # Snap kontrolü
    if ! command -v snap &> /dev/null; then
        log_error "Snap bulunamadı, Procs kurulamadı"
        return 1
    fi
    
    # Kurulum (retry ile)
    if ! retry_command 3 0 sudo snap install procs; then
        log_error "Procs kurulumu başarısız!"
        return 1
    fi
    
    # Doğrulama
    if ! verify_command_installed "procs" "Procs"; then
        log_error "Procs kuruldu ancak doğrulanamadı!"
        return 1
    fi
    
    log_success "Procs kuruldu ve doğrulandı"
    return 0
}

# ============================================================================
# HISTORY VE KOMUT ARAMA
# ============================================================================

install_atuin() {
    log_info "Atuin kuruluyor..."
    
    if command -v atuin &> /dev/null; then
        log_warning "Atuin zaten kurulu, atlanıyor..."
        return 0
    fi
    
    if ! check_internet; then
        log_error "İnternet bağlantısı gerekli!"
        return 1
    fi
    
    log_info "Atuin install script indiriliyor..."
    
    local atuin_installer
    atuin_installer=$(mktemp -t atuin-install.XXXXXXXXXX.sh) || {
        log_error "Geçici Atuin dosyası oluşturulamadı"
        return 1
    }

    if ! safe_download "https://raw.githubusercontent.com/atuinsh/atuin/main/install.sh" "$atuin_installer" "Atuin install script indiriliyor"; then
        rm -f -- "$atuin_installer"
        log_error "Atuin install script indirilemedi!"
        return 1
    fi

    if ! bash "$atuin_installer" >> "$LOG_FILE" 2>&1; then
        log_error "Atuin kurulumu başarısız!"
        rm -f -- "$atuin_installer"
        return 1
    fi

    rm -f -- "$atuin_installer"
    

# PATH'e ekle (kurulum sonrası doğrulama için)
if [[ -f "$HOME/.atuin/bin/env" ]]; then
    # shellcheck disable=SC1090
    source "$HOME/.atuin/bin/env"
elif [[ -x "$HOME/.atuin/bin/atuin" ]]; then
    export PATH="$HOME/.atuin/bin:$PATH"
fi
hash -r

        # Doğrulama
    if command -v atuin &>/dev/null; then
        local version=$(atuin --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        log_success "Atuin kuruldu: v${version:-unknown}"
        
        # Zsh entegrasyonu
        if [[ -f "$HOME/.zshrc" ]] && ! grep -q "atuin init zsh" "$HOME/.zshrc"; then
            echo '' >> "$HOME/.zshrc"
            echo '# Atuin' >> "$HOME/.zshrc"
            echo 'if [ -f "$HOME/.atuin/bin/env" ]; then' >> "$HOME/.zshrc"
            echo '  source "$HOME/.atuin/bin/env"' >> "$HOME/.zshrc"
            echo 'else' >> "$HOME/.zshrc"
            echo '  export PATH="$HOME/.atuin/bin:$PATH"' >> "$HOME/.zshrc"
            echo 'fi' >> "$HOME/.zshrc"
            echo 'eval "$(atuin init zsh)"' >> "$HOME/.zshrc"
            log_info "Atuin .zshrc'ye eklendi"
        fi
        
        return 0
    else
        log_error "Atuin kuruldu ama doğrulanamadı!"
        return 1
    fi
}

# ============================================================================
# TOPLU KURULUM FONKSİYONLARI
# ============================================================================

install_all_tools() {
    log_info "Terminal araçları kuruluyor..."
    
    local total_tools=4
    local current_tool=0
    local errors=0
    
    show_progress $((++current_tool)) $total_tools "FZF kuruluyor"
    install_fzf || ((errors++))
    
    show_progress $((++current_tool)) $total_tools "Zoxide kuruluyor"
    install_zoxide || ((errors++))
    
    show_progress $((++current_tool)) $total_tools "Exa kuruluyor"
    install_exa || ((errors++))
    
    show_progress $((++current_tool)) $total_tools "Bat kuruluyor"
    install_bat || ((errors++))
    
    if [ $errors -eq 0 ]; then
        log_success "Tüm araçlar kuruldu"
        return 0
    else
        log_warning "$errors araç kurulamadı"
        return 1
    fi
}

install_all_tools_complete() {
    log_info "TÜM terminal araçları kuruluyor (14 araç)..."
    echo
    
    local total_tools=14
    local current_tool=0
    local errors=0
    
    # Temel Araçlar (4)
    show_section $((++current_tool)) $total_tools "FZF kuruluyor"
    install_fzf || ((errors++))
    
    show_section $((++current_tool)) $total_tools "Zoxide kuruluyor"
    install_zoxide || ((errors++))
    
    show_section $((++current_tool)) $total_tools "Exa kuruluyor"
    install_exa || ((errors++))
    
    show_section $((++current_tool)) $total_tools "Bat kuruluyor"
    install_bat || ((errors++))
    
    # Arama Araçları (2)
    show_section $((++current_tool)) $total_tools "Ripgrep kuruluyor"
    install_ripgrep || ((errors++))
    
    show_section $((++current_tool)) $total_tools "Fd kuruluyor"
    install_fd || ((errors++))
    
    # Git Araçları (2)
    show_section $((++current_tool)) $total_tools "Delta kuruluyor"
    install_delta || ((errors++))
    
    show_section $((++current_tool)) $total_tools "Lazygit kuruluyor"
    install_lazygit || ((errors++))
    
    # Sistem Araçları (4)
    show_section $((++current_tool)) $total_tools "Btop kuruluyor"
    install_btop || ((errors++))
    
    show_section $((++current_tool)) $total_tools "Dust kuruluyor"
    install_dust || ((errors++))
    
    show_section $((++current_tool)) $total_tools "Duf kuruluyor"
    install_duf || ((errors++))
    
    show_section $((++current_tool)) $total_tools "Procs kuruluyor"
    install_procs || ((errors++))
    
    # Ekstra Araçlar (2)
    show_section $((++current_tool)) $total_tools "Atuin kuruluyor"
    install_atuin || ((errors++))
    
    show_section $((++current_tool)) $total_tools "TLDR kuruluyor"
    install_tldr || ((errors++))
    
    echo
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    
    if [ $errors -eq 0 ]; then
        log_success "Tüm 14 araç başarıyla kuruldu! 🎉"
        echo
        echo -e "${GREEN}Kurulu Araçlar:${NC}"
        echo -e "  ${CYAN}Temel:${NC} fzf, zoxide, exa, bat"
        echo -e "  ${CYAN}Arama:${NC} ripgrep, fd"
        echo -e "  ${CYAN}Git:${NC} delta, lazygit"
        echo -e "  ${CYAN}Sistem:${NC} btop, dust, duf, procs"
        echo -e "  ${CYAN}Ekstra:${NC} atuin, tldr"
        return 0
    else
        log_warning "$errors araç kurulamadı, geri kalan $((14 - errors)) araç başarılı"
        return 1
    fi
}

install_search_tools() {
    log_info "Arama araçları kuruluyor..."
    
    local errors=0
    
    show_step_info "Ripgrep kuruluyor..."
    install_ripgrep || ((errors++))
    
    show_step_info "Fd kuruluyor..."
    install_fd || ((errors++))
    
    if [ $errors -eq 0 ]; then
        log_success "Arama araçları kuruldu"
        return 0
    else
        log_warning "$errors araç kurulamadı"
        return 1
    fi
}

install_git_tools() {
    log_info "Git araçları kuruluyor..."
    
    local errors=0
    
    show_step_info "Delta kuruluyor..."
    install_delta || ((errors++))
    
    show_step_info "Lazygit kuruluyor..."
    install_lazygit || ((errors++))
    
    if [ $errors -eq 0 ]; then
        log_success "Git araçları kuruldu"
        return 0
    else
        log_warning "$errors araç kurulamadı"
        return 1
    fi
}

install_system_tools() {
    log_info "Sistem araçları kuruluyor..."
    
    local errors=0
    
    show_step_info "Btop kuruluyor..."
    install_btop || ((errors++))
    
    show_step_info "Dust kuruluyor..."
    install_dust || ((errors++))
    
    show_step_info "Duf kuruluyor..."
    install_duf || ((errors++))
    
    show_step_info "Procs kuruluyor..."
    install_procs || ((errors++))
    
    if [ $errors -eq 0 ]; then
        log_success "Sistem araçları kuruldu"
        return 0
    else
        log_warning "$errors araç kurulamadı"
        return 1
    fi
}

install_extra_tools() {
    log_info "Ekstra araçlar kuruluyor..."
    
    local errors=0
    
    show_step_info "Atuin kuruluyor..."
    install_atuin || ((errors++))
    
    show_step_info "TLDR kuruluyor..."
    install_tldr || ((errors++))
    
    if [ $errors -eq 0 ]; then
        log_success "Ekstra araçlar kuruldu"
        return 0
    else
        log_warning "$errors araç kurulamadı"
        return 1
    fi
}

# ============================================================================
# TMUX
# ============================================================================