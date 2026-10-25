#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Loglama ve komut çalıştırma
# ============================================================================
# Konsola kısa, log dosyasına ayrıntılı yazar. Komut çıktıları ekranı
# doldurmaz; run_logged ile log dosyasına gider.
# ============================================================================

# Renkler: terminal değilse veya NO_COLOR tanımlıysa kapalı
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_RED=$'\033[0;31m' C_GREEN=$'\033[0;32m' C_YELLOW=$'\033[0;33m'
    C_BLUE=$'\033[0;34m' C_CYAN=$'\033[0;36m' C_MAGENTA=$'\033[0;35m'
    C_BOLD=$'\033[1m' C_DIM=$'\033[2m' C_RESET=$'\033[0m'
else
    C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN="" C_MAGENTA=""
    C_BOLD="" C_DIM="" C_RESET=""
fi
export C_RED C_GREEN C_YELLOW C_BLUE C_CYAN C_MAGENTA C_BOLD C_DIM C_RESET

TS_LOG_FILE="${TS_LOG_FILE:-}"

# Log önce oturumun geçici dizinine yazılır. Sistemde ilk değişiklik
# yapıldığında (ledger_init) kalıcı log dosyasına taşınır; böylece yalnızca
# "status" ya da "--help" çalıştıran biri için hiçbir dosya oluşmaz.
log_init() {
    if [[ -f "$TS_LOG_DIR/terminal-setup.log" ]] && ! is_dry_run; then
        log_persist
    else
        TS_LOG_FILE="$TS_TMP/terminal-setup.log"
        : >> "$TS_LOG_FILE"
    fi
}

log_persist() {
    local target="$TS_LOG_DIR/terminal-setup.log"
    is_dry_run && return 0
    [[ "$TS_LOG_FILE" == "$target" ]] && return 0
    mkdir -p "$TS_LOG_DIR" || return 0
    [[ -f "$TS_LOG_FILE" ]] && cat "$TS_LOG_FILE" >> "$target"
    TS_LOG_FILE="$target"
    # 5000 satırı aşarsa son 2000 satırı tut
    if (( $(wc -l < "$TS_LOG_FILE") > 5000 )); then
        tail -n 2000 "$TS_LOG_FILE" > "$TS_LOG_FILE.tmp" && mv "$TS_LOG_FILE.tmp" "$TS_LOG_FILE"
    fi
}

_log_write() {
    [[ -n "$TS_LOG_FILE" ]] || return 0
    printf '[%s] [%s] %s\n' "$(ts_now)" "$1" "$2" >> "$TS_LOG_FILE" 2>/dev/null || true
}

# Konsol satırları menünün kenar boşluğuna (UI_M) hizalanır; renkler ui.sh
# yüklüyse onun paletinden, değilse temel renklerden gelir. Mesajlar
# çevrilir; değişken içerenler printf biçimindedir (lib/i18n.sh):
#   log_err "Bilinmeyen bileşen: %s" "$id"
log_info()  { _t "$@"; _log_write INFO "$TR";  printf '%s%s\n' "${UI_M:-}" "${U_INFO:-$C_BLUE}•${C_RESET} $TR"; }
log_ok()    { _t "$@"; _log_write OK "$TR";    printf '%s%s\n' "${UI_M:-}" "${U_OK:-$C_GREEN}✓${C_RESET} $TR"; }
log_warn()  { _t "$@"; _log_write WARN "$TR";  printf '%s%s\n' "${UI_M:-}" "${U_WARN:-$C_YELLOW}▲${C_RESET} $TR" >&2; }
log_err()   { _t "$@"; _log_write ERROR "$TR"; printf '%s%s\n' "${UI_M:-}" "${U_ERR:-$C_RED}✗${C_RESET} $TR" >&2; }
log_debug() {
    _log_write DEBUG "$*"
    [[ "$TS_DEBUG" == "1" ]] && printf '%s\n' "${C_DIM}[debug] $*${C_RESET}" >&2
    return 0
}

# Kurulum adımı başlığı: log_step "%s kuruluyor" "Bat"
log_step() { _t "$@"; _log_write STEP "$TR"; printf '%s%s\n' "${UI_M:-}" "${U_ACC:-$C_CYAN}◆${C_RESET} $TR"; }

# Prova modunda yapılacak işlemi yazdır (komutlar çevrilmez; biçim verilirse çevrilir)
log_plan() { _t "$@"; _log_write PLAN "$TR"; printf '%s%s\n' "${UI_M:-}" "  ${U_PINK:-$C_MAGENTA}[plan]${C_RESET} ${U_MUTED:-}$TR${C_RESET}"; }

# Komutu çalıştır; çıktıyı log dosyasına yaz, çıkış kodunu döndür.
run_logged() {
    _log_write CMD "$*"
    "$@" >> "$TS_LOG_FILE" 2>&1
}
