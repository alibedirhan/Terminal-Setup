#!/bin/bash

# ============================================================================
# Terminal Setup - Sistem Fonksiyonları
# v5.0.2 - System Module  
# ============================================================================
# Bu modül: Terminal Detection, Internet Check, System Resources
# ============================================================================

# ============================================================================
# TERMİNAL DETECTION
# ============================================================================

detect_terminal() {
    # GNOME Terminal
    if [ -n "$GNOME_TERMINAL_SERVICE" ]; then
        echo "gnome-terminal"
        return
    fi
    
    # Kitty
    if [ -n "$KITTY_WINDOW_ID" ]; then
        echo "kitty"
        return
    fi
    
    # Alacritty
    if [ -n "$ALACRITTY_SOCKET" ]; then
        echo "alacritty"
        return
    fi
    
    # Tilix
    if [ "$TILIX_ID" ]; then
        echo "tilix"
        return
    fi
    
    # Konsole
    if [ "$KONSOLE_VERSION" ]; then
        echo "konsole"
        return
    fi
    
    # iTerm2 (macOS)
    if [ "$TERM_PROGRAM" = "iTerm.app" ]; then
        echo "iterm2"
        return
    fi
    
    # Terminal.app (macOS)
    if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
        echo "terminal-app"
        return
    fi
    
    # Hyper
    if [ "$TERM_PROGRAM" = "Hyper" ]; then
        echo "hyper"
        return
    fi
    
    # Generic check
    if [ "$COLORTERM" = "truecolor" ]; then
        echo "generic-truecolor"
        return
    fi
    
    echo "unknown"
}

check_gnome_terminal() {
    if ! command -v gsettings &> /dev/null; then
        log_warning "GNOME Terminal bulunamadı"
        log_info "Renk teması sadece GNOME Terminal'de çalışır"
        return 1
    fi
    return 0
}

# Terminal bilgilerini göster
show_terminal_info() {
    local terminal=$(detect_terminal)
    echo -e "${CYAN}Terminal Bilgileri:${NC}"
    echo "  Tip: $terminal"
    echo "  TERM: $TERM"
    echo "  COLORTERM: ${COLORTERM:-Yok}"
    echo "  Shell: $SHELL"
    echo "  OS: $OSTYPE"
}

# ============================================================================
# İNTERNET KONTROLÜ (İYİLEŞTİRİLMİŞ)
# ============================================================================

check_internet() {
    log_debug "İnternet bağlantısı kontrol ediliyor..."
    
    # DÜZELTME: Birden fazla host dene (8.8.8.8 bloklanabilir)
    local hosts=("8.8.8.8" "1.1.1.1" "google.com")
    
    for host in "${hosts[@]}"; do
        if ping -c 1 -W 2 "$host" &> /dev/null; then
            log_debug "İnternet bağlantısı OK (via $host)"
            return 0
        fi
    done
    
    log_error "İnternet bağlantısı yok!"
    echo "Kurulum için internet gerekli."
    return 1
}

# İnternet hızı testi (opsiyonel)
test_internet_speed() {
    log_info "İnternet hızı test ediliyor..."
    
    local start_time=$(date +%s%N)
    if wget --timeout=5 -q -O /dev/null http://speedtest.tele2.net/1MB.zip 2>/dev/null; then
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))
        
        if [ $duration -lt 2000 ]; then
            log_success "İnternet hızı: İyi (${duration}ms)"
        elif [ $duration -lt 5000 ]; then
            log_warning "İnternet hızı: Orta (${duration}ms)"
        else
            log_warning "İnternet hızı: Yavaş (${duration}ms)"
        fi
    else
        log_warning "İnternet hızı ölçülemedi"
    fi
}
check_system_resources() {
    log_info "Sistem kaynakları kontrol ediliyor..."
    
    # DÜZELTME: macOS uyumlu disk space check
    local available_mb
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_mb=$(df -m "$HOME" | awk 'NR==2 {print $4}')
    else
        available_mb=$(df -BM "$HOME" | awk 'NR==2 {print $4}' | sed 's/M//')
    fi
    
    log_debug "Kullanılabilir disk alanı: ${available_mb}MB"
    
    if [ "$available_mb" -lt 500 ]; then
        show_error $ERR_DISK_SPACE "Yetersiz disk alanı: ${available_mb}MB (Min: 500MB)"
        return $ERR_DISK_SPACE
    fi
    
    # Bellek kontrolü
    if command -v free &> /dev/null; then
        local available_mem=$(free -m | awk 'NR==2 {print $7}')
        log_debug "Kullanılabilir bellek: ${available_mem}MB"
        
        if [ "$available_mem" -lt 100 ]; then
            log_warning "Düşük bellek: ${available_mem}MB"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS için memory check
        local free_mem=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        local page_size=4096
        local available_mem=$((free_mem * page_size / 1024 / 1024))
        log_debug "Kullanılabilir bellek: ${available_mem}MB (macOS)"
    fi
    
    return $ERR_SUCCESS
}

# ============================================================================
# ROLLBACK MEKANİZMASI (İYİLEŞTİRİLMİŞ)
# ============================================================================

# Rollback için snapshot oluştur
