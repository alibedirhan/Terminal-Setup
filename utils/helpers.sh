#!/bin/bash

# ============================================================================
# Terminal Setup - Yardımcı Fonksiyonlar (Helpers)
# v5.0.2 - Helpers Module
# ============================================================================
# Bu modül: Logging, Error Handling, Retry, Timeout, Validation
# ============================================================================

# ============================================================================
# LOGGING SİSTEMİ
# ============================================================================

# Hata kodları varsayılanları. Bazı modüller bu değişkenleri kullanır;
# burada tek kaynaktan tanımlı tutmak runtime sürprizlerini önler.
ERR_SUCCESS=${ERR_SUCCESS:-0}
ERR_COMMAND_FAILED=${ERR_COMMAND_FAILED:-1}
ERR_TIMEOUT=${ERR_TIMEOUT:-124}
ERR_DISK_SPACE=${ERR_DISK_SPACE:-20}

if ! declare -p ERROR_MESSAGES >/dev/null 2>&1; then
    declare -A ERROR_MESSAGES=(
        [$ERR_SUCCESS]="Başarılı"
        [$ERR_COMMAND_FAILED]="Komut başarısız"
        [$ERR_TIMEOUT]="Zaman aşımı"
        [$ERR_DISK_SPACE]="Disk alanı yetersiz"
    )
fi

TRANSACTION_ACTIVE=${TRANSACTION_ACTIVE:-false}
TRANSACTION_SNAPSHOT=${TRANSACTION_SNAPSHOT:-}


# Log dosyasını başlat
init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
    fi
    
    # Eski logları temizle (son 1000 satır)
    if [[ -f "$LOG_FILE" ]]; then
        local temp_log=$(mktemp)
        tail -n 1000 "$LOG_FILE" > "$temp_log"
        mv "$temp_log" "$LOG_FILE"
    fi
}

# Log fonksiyonu
log_message() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log dosyasına yaz
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Verbose modda konsola da yaz
    if [[ "$VERBOSE_MODE" == true ]]; then
        echo "[$level] $message"
    fi
}

log_info() {
    log_message "INFO" "$@"
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    log_message "SUCCESS" "$@"
    echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
    log_message "WARNING" "$@"
    echo -e "${YELLOW}⚠ ${NC} $*"
}

log_error() {
    log_message "ERROR" "$@"
    echo -e "${RED}✗${NC} $*"
}

log_debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        log_message "DEBUG" "$@"
        echo -e "${MAGENTA}[DEBUG]${NC} $*"
    fi
}
show_error() {
    local error_code=$1
    local context="${2:-}"
    
    log_error "Hata [${error_code}]: ${ERROR_MESSAGES[$error_code]}"
    
    if [[ -n "$context" ]]; then
        log_error "Detay: $context"
    fi
    
    log_error "Log dosyası: $LOG_FILE"
    
    return $error_code
}

# Komut çalıştır ve hata kodu döndür
run_with_error_handling() {
    local description="$1"
    shift
    local command=("$@")
    
    log_debug "Çalıştırılıyor: ${command[*]}"
    echo -n "  → $description... "
    
    local output
    local exit_code
    
    # Komutu çalıştır ve çıktıyı yakala
    output=$("${command[@]}" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓${NC}"
        log_debug "Başarılı: $description"
        return $ERR_SUCCESS
    else
        echo -e "${RED}✗${NC}"
        log_error "Başarısız: $description (Exit Code: $exit_code)"
        log_error "Çıktı: $output"
        return $exit_code
    fi
}

# ============================================================================
# TIMEOUT İŞLEMLERİ
# ============================================================================

# Timeout ile komut çalıştır
run_with_timeout() {
    local timeout_seconds=$1
    local description=$2
    shift 2
    local command=("$@")
    
    log_info "Çalıştırılıyor: $description (Timeout: ${timeout_seconds}s)"
    
    # Spinner başlat (eğer fonksiyon varsa)
    if type start_spinner &>/dev/null; then
        start_spinner "$description"
    fi
    
    # timeout komutu varsa kullan
    if command -v timeout &> /dev/null; then
        timeout "$timeout_seconds" "${command[@]}" &> /dev/null
        local exit_code=$?
        
        # Spinner durdur
        if type stop_spinner &>/dev/null; then
            stop_spinner
        fi
        
        if [ $exit_code -eq 124 ]; then
            log_error "Zaman aşımı: $description"
            return $ERR_TIMEOUT
        elif [ $exit_code -ne 0 ]; then
            log_error "Komut başarısız: $description (Exit: $exit_code)"
            return $ERR_COMMAND_FAILED
        else
            log_success "$description tamamlandı"
            return $ERR_SUCCESS
        fi
    else
        # timeout komutu yoksa normal çalıştır
        "${command[@]}" &> /dev/null
        local exit_code=$?
        
        if type stop_spinner &>/dev/null; then
            stop_spinner
        fi
        
        if [ $exit_code -ne 0 ]; then
            log_error "Komut başarısız: $description"
            return $ERR_COMMAND_FAILED
        else
            log_success "$description tamamlandı"
            return $ERR_SUCCESS
        fi
    fi
}

# ============================================================================
# İNTERAKTİF INPUT (TIMEOUT İLE)
# ============================================================================

# Timeout ile input al
read_with_timeout() {
    local prompt="$1"
    local timeout_seconds="${2:-30}"
    local default_value="${3:-h}"
    local response
    
    echo -n "$prompt "
    
    if read -r -t "$timeout_seconds" response; then
        echo "$response"
    else
        echo
        log_warning "Zaman aşımı - Varsayılan değer kullanılıyor: $default_value"
        echo "$default_value"
    fi
}

# ============================================================================
# SİSTEM KAYNAK KONTROLÜ (İYİLEŞTİRİLMİŞ)
# ============================================================================

retry_command() {
    local max_attempts="${1:-3}"
    local timeout_seconds="${2:-60}"
    shift 2
    local command=("$@")

    if [[ ${#command[@]} -eq 0 ]]; then
        log_error "retry_command: Komut belirtilmedi"
        return 1
    fi

    local attempt=1
    local delay=2
    local exit_code=1

    log_debug "Retry: ${command[*]} (Max: $max_attempts, Timeout: ${timeout_seconds}s)"

    while [[ $attempt -le $max_attempts ]]; do
        log_debug "Deneme $attempt/$max_attempts: ${command[*]}"

        if command -v timeout &>/dev/null; then
            timeout "$timeout_seconds" "${command[@]}" >> "$LOG_FILE" 2>&1
            exit_code=$?
        else
            "${command[@]}" >> "$LOG_FILE" 2>&1
            exit_code=$?
        fi

        if [[ $exit_code -eq 0 ]]; then
            log_debug "Başarılı (Deneme: $attempt)"
            return 0
        fi

        if [[ $exit_code -eq 124 ]]; then
            log_warning "Deneme $attempt zaman aşımına uğradı (${timeout_seconds}s)"
        else
            log_warning "Deneme $attempt başarısız oldu (Exit: $exit_code)"
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            log_warning "$delay saniye sonra tekrar denenecek..."
            sleep "$delay"
            delay=$((delay * 2))
        fi

        attempt=$((attempt + 1))
    done

    log_error "Tüm denemeler başarısız oldu: ${command[*]}"
    return "$exit_code"
}

# Güvenli download fonksiyonu (retry ile)
safe_download() {
    local url="$1"
    local output="$2"
    local description="${3:-Dosya indiriliyor}"
    
    log_info "$description"
    log_debug "URL: $url"
    log_debug "Output: $output"
    
    # wget öncelikli (daha güvenilir)
    if command -v wget &>/dev/null; then
        if retry_command 3 60 wget -q --show-progress -O "$output" "$url"; then
            log_success "İndirme başarılı: $output"
            return 0
        fi
    fi
    
    # curl fallback
    if command -v curl &>/dev/null; then
        if retry_command 3 60 curl -fsSL -o "$output" "$url"; then
            log_success "İndirme başarılı: $output"
            return 0
        fi
    fi
    
    log_error "İndirme başarısız: $url"
    return 1
}

# Git clone retry ile
safe_git_clone() {
    local repo_url="$1"
    local target_dir="$2"
    local depth="${3:-1}"

    log_info "Git repository klonlanıyor..."
    log_debug "Repo: $repo_url"
    log_debug "Target: $target_dir"

    if [[ -z "$target_dir" || "$target_dir" == "/" || "$target_dir" == "$HOME" || "$target_dir" == "$HOME/" || "$target_dir" == "." ]]; then
        log_error "Güvensiz hedef dizin: $target_dir"
        return 1
    fi

    if [[ -d "$target_dir" ]]; then
        log_debug "Mevcut hedef dizin temizleniyor: $target_dir"
        rm -rf -- "$target_dir"
    fi

    if retry_command 3 120 git clone --depth "$depth" "$repo_url" "$target_dir"; then
        log_success "Repository klonlandı: $target_dir"
        return 0
    fi

    log_error "Git clone başarısız: $repo_url"
    return 1
}

# ============================================================================
# ERROR RECOVERY SİSTEMİ
# ============================================================================

# Network hatası recovery
handle_network_error() {
    local context="${1:-Bilinmeyen işlem}"
    
    log_error "Network hatası: $context"
    echo
    echo -e "${YELLOW}═══ BAĞLANTI SORUNU ═══${NC}"
    echo
    echo "Olası nedenler:"
    echo "  1. İnternet bağlantınız kesildi"
    echo "  2. DNS sorunu"
    echo "  3. Güvenlik duvarı/proxy engelliyor"
    echo "  4. Uzak sunucu yanıt vermiyor"
    echo
    echo "Öneriler:"
    echo "  → İnternet bağlantınızı kontrol edin"
    echo "  → VPN kullanıyorsanız kapatıp deneyin"
    echo "  → Birkaç dakika bekleyip tekrar deneyin"
    echo
    
    # Otomatik internet kontrolü
    if check_internet; then
        log_info "İnternet bağlantısı aktif, tekrar deneniyor..."
        return 0  # Retry yap
    else
        log_error "İnternet bağlantısı yok!"
        return 1  # Fatal error
    fi
}

# Disk alanı hatası recovery
handle_disk_space_error() {
    local context="${1:-Bilinmeyen işlem}"
    local required_mb="${2:-500}"
    
    log_error "Disk alanı yetersiz: $context"
    echo
    echo -e "${YELLOW}═══ DİSK ALANI YETERSİZ ═══${NC}"
    echo
    echo "Gerekli alan: ${required_mb}MB"
    echo
    echo "Öneriler:"
    echo "  1. Gereksiz dosyaları silin"
    echo "  2. Paket önbelleğini temizleyin: sudo apt clean"
    echo "  3. Kullanılmayan paketleri kaldırın: sudo apt autoremove"
    echo
    
    if ask_yes_no "Otomatik temizlik yapalım mı? (apt clean + autoremove)"; then
        log_info "Otomatik temizlik başlatılıyor..."
        
        sudo apt clean &>/dev/null
        sudo apt autoremove -y &>/dev/null
        
        log_success "Temizlik tamamlandı"
        return 0  # Retry yap
    fi
    
    return 1  # Kullanıcı redetti
}

# Permission hatası recovery
handle_permission_error() {
    local context="${1:-Bilinmeyen işlem}"
    
    log_error "Yetki hatası: $context"
    echo
    echo -e "${YELLOW}═══ YETKİ SORUNU ═══${NC}"
    echo
    echo "Bu işlem için sudo yetkisi gerekiyor."
    echo
    
    if ask_yes_no "Sudo yetkisi almak ister misiniz?"; then
        if setup_sudo 2>/dev/null || sudo -v 2>/dev/null; then
            log_success "Sudo yetkisi alındı"
            return 0  # Retry yap
        else
            log_error "Sudo yetkisi alınamadı"
            return 1
        fi
    fi
    
    return 1  # Kullanıcı redetti
}

# ============================================================================
# TRANSACTION SİSTEMİ (Snapshot Tabanlı)
# ============================================================================

# Transaction başlat (snapshot al)
transaction_begin() {
    local operation_name="${1:-İşlem}"
    
    if [[ "$TRANSACTION_ACTIVE" == true ]]; then
        log_warning "Zaten aktif bir transaction var, yeni snapshot alınmıyor"
        return 0
    fi
    
    log_info "Transaction başlatılıyor: $operation_name"
    
    # Snapshot oluştur (terminal-utils.sh'taki mevcut fonksiyon)
    if type create_snapshot &>/dev/null; then
        # DÜZELTME: create_snapshot hem log hem path yazıyor, sadece son satırı (path) al
        TRANSACTION_SNAPSHOT=$(create_snapshot 2>&1 | tail -1 | xargs)
        
        # Debug: snapshot path'ini logla
        log_debug "Snapshot path: '$TRANSACTION_SNAPSHOT'"
        
        if [[ -n "$TRANSACTION_SNAPSHOT" ]] && [[ -d "$TRANSACTION_SNAPSHOT" ]]; then
            TRANSACTION_ACTIVE=true
            log_success "Transaction başlatıldı (Snapshot: $(basename "$TRANSACTION_SNAPSHOT"))"
            return 0
        else
            log_error "Snapshot oluşturulamadı (Path: '$TRANSACTION_SNAPSHOT')"
            return 1
        fi
    else
        log_warning "create_snapshot fonksiyonu bulunamadı, transaction devre dışı"
        return 1
    fi
}

# Transaction başarılı (commit)
transaction_commit() {
    local operation_name="${1:-İşlem}"
    
    if [[ "$TRANSACTION_ACTIVE" != true ]]; then
        log_debug "Aktif transaction yok, commit atlanıyor"
        return 0
    fi
    
    log_success "Transaction başarılı: $operation_name"
    log_debug "Snapshot korunuyor: $TRANSACTION_SNAPSHOT"
    
    TRANSACTION_ACTIVE=false
    # Snapshot'ı silmiyoruz, backup olarak kalıyor
    
    return 0
}

# Transaction başarısız (rollback)
transaction_rollback() {
    local operation_name="${1:-İşlem}"
    local error_msg="${2:-Bilinmeyen hata}"
    
    if [[ "$TRANSACTION_ACTIVE" != true ]]; then
        log_debug "Aktif transaction yok, rollback atlanıyor"
        return 0
    fi
    
    log_error "Transaction başarısız: $operation_name"
    log_error "Hata: $error_msg"
    
    if [[ -n "$TRANSACTION_SNAPSHOT" ]] && [[ -d "$TRANSACTION_SNAPSHOT" ]]; then
        log_warning "Önceki duruma geri dönülüyor..."
        
        # Snapshot'tan geri yükle (mevcut fonksiyon)
        if type restore_snapshot &>/dev/null; then
            if restore_snapshot "$TRANSACTION_SNAPSHOT"; then
                log_success "Geri yükleme başarılı"
                TRANSACTION_ACTIVE=false
                return 0
            else
                log_error "Geri yükleme başarısız!"
                return 1
            fi
        else
            log_error "restore_snapshot fonksiyonu bulunamadı"
            return 1
        fi
    else
        log_warning "Snapshot bulunamadı, geri yükleme yapılamıyor"
        TRANSACTION_ACTIVE=false
        return 1
    fi
}

# Transaction wrapper - İşlemi transaction içinde çalıştır
with_transaction() {
    local operation_name="$1"
    shift
    local command=("$@")
    
    # Transaction başlat
    if ! transaction_begin "$operation_name"; then
        log_warning "Transaction başlatılamadı, normal çalıştırılıyor"
        "${command[@]}"
        return $?
    fi
    
    # Komutu çalıştır
    if "${command[@]}"; then
        transaction_commit "$operation_name"
        return 0
    else
        local exit_code=$?
        transaction_rollback "$operation_name" "Exit code: $exit_code"
        return $exit_code
    fi
}

# ============================================================================
# DOĞRULAMA FONKSİYONLARI
# ============================================================================

# İşlem sonrası doğrulama
verify_operation() {
    local operation="$1"
    local check_command="$2"
    
    log_debug "Doğrulanıyor: $operation"
    
    if eval "$check_command" &>/dev/null; then
        log_debug "Doğrulama başarılı: $operation"
        return 0
    else
        log_error "Doğrulama başarısız: $operation"
        return 1
    fi
}

# Komut varlığını doğrula
verify_command_installed() {
    local cmd="$1"
    local package_name="${2:-$cmd}"
    
    if command -v "$cmd" &>/dev/null; then
        local version=$($cmd --version 2>/dev/null | head -1 || echo "version unknown")
        log_success "$package_name kurulu: $version"
        return 0
    else
        log_error "$package_name bulunamadı"
        return 1
    fi
}

# Dosya varlığını doğrula
verify_file_exists() {
    local file="$1"
    local description="${2:-Dosya}"
    
    if [[ -f "$file" ]]; then
        log_debug "$description mevcut: $file"
        return 0
    else
        log_error "$description bulunamadı: $file"
        return 1
    fi
}

# ============================================================================
# YARDIMCI FONKSİYONLAR
# ============================================================================

# Evet/Hayır sorusu (güvenli)
ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    while true; do
        if [[ "$default" == "y" ]]; then
            echo -n "$prompt [E/h]: "
        else
            echo -n "$prompt [e/H]: "
        fi
        
        read -r response
        response=${response:-$default}
        
        case "$response" in
            [eEyY]|[eEyY][eEsS][sS])
                return 0
                ;;
            [hHnN]|[hHnN][oOaAıİ]|[hHnN][oOaAıİ][yYıİrR])
                return 1
                ;;
            *)
                echo "Geçersiz cevap. Lütfen 'e' veya 'h' girin."
                ;;
        esac
    done
}
