#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Çekirdek: yollar, ortam algılama, modül yükleme
# ============================================================================
# Bu dosya tüm diğer modüllerden önce yüklenir. Yan etkisi yoktur; sadece
# değişkenleri tanımlar ve yardımcı fonksiyonlar sağlar.
# ============================================================================

# Yeniden yüklemeye karşı koruma
[[ -n "${TS_CORE_LOADED:-}" ]] && return 0
TS_CORE_LOADED=1

# ----------------------------------------------------------------------------
# Yollar (hepsi ortam değişkeniyle değiştirilebilir; testler bunu kullanır)
# ----------------------------------------------------------------------------
: "${TS_ROOT:?TS_ROOT tanımlı olmalı}"
TS_VERSION="$(tr -d '[:space:]' < "$TS_ROOT/VERSION" 2>/dev/null || echo dev)"

TS_STATE_DIR="${TS_STATE_DIR:-$HOME/.terminal-setup}"        # defter, fotoğraf, log
TS_CONFIG_DIR="${TS_CONFIG_DIR:-$HOME/.config/terminal-setup}" # zsh/tmux parçaları
TS_BIN_DIR="${TS_BIN_DIR:-$HOME/.local/bin}"                   # indirilen araçlar
TS_FONT_DIR="${TS_FONT_DIR:-$HOME/.local/share/fonts}"

TS_LEDGER="$TS_STATE_DIR/ledger"
TS_BASELINE_DIR="$TS_STATE_DIR/baseline"
TS_FILES_DIR="$TS_STATE_DIR/files"   # değiştirilen dosyaların orijinal kopyaları
TS_LOG_DIR="$TS_STATE_DIR/logs"
TS_SETTINGS_FILE="$TS_STATE_DIR/settings"

# Kaldırmada kullanıcı verisinin taşınacağı arşiv (kaldırma anında belirlenir)
TS_ARCHIVE_DIR="${TS_ARCHIVE_DIR:-}"

# Çalışma bayrakları
TS_DRY_RUN="${TS_DRY_RUN:-0}"       # 1: hiçbir şey değiştirilmez, plan yazdırılır
TS_ASSUME_YES="${TS_ASSUME_YES:-0}" # 1: onay soruları otomatik "evet"
TS_DEBUG="${TS_DEBUG:-0}"
TS_TMP=""                           # oturum geçici dizini (ts_init oluşturur)

# Kurulum sırasında deftere yazılan kayıtların sahibi olan bileşen
TS_CURRENT_COMPONENT="core"

# ----------------------------------------------------------------------------
# Küçük yardımcılar
# ----------------------------------------------------------------------------
has_cmd() { command -v "$1" >/dev/null 2>&1; }

is_dry_run() { [[ "$TS_DRY_RUN" == "1" ]]; }

ts_now() { date '+%Y-%m-%d %H:%M:%S'; }

ts_stamp() { date '+%Y%m%d-%H%M%S'; }

# Dizi içinde eleman ara: in_list "x" "${dizi[@]}"
in_list() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# Bir yolu $HOME ile kısaltarak göster: /home/ali/.zshrc -> ~/.zshrc
ts_pretty_path() {
    local p="$1"
    [[ "$p" == "$HOME"* ]] && p="~${p#"$HOME"}"
    printf '%s\n' "$p"
}

# ----------------------------------------------------------------------------
# Ortam algılama
# ----------------------------------------------------------------------------

# İşlemci mimarisi, release dosya adlarında kullanılan iki biçimde.
# Çıktı: "x86_64" veya "aarch64"; desteklenmiyorsa boş ve 1 döner.
sys_arch() {
    local m="${TS_FAKE_ARCH:-$(uname -m)}"
    case "$m" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        *) return 1 ;;
    esac
}

# /etc/os-release'den dağıtım ID ve sürüm. Çıktı: "ubuntu 24.04"
sys_os() {
    local file="${TS_OS_RELEASE:-/etc/os-release}" id="" ver=""
    if [[ -r "$file" ]]; then
        id=$(sed -n 's/^ID=//p' "$file" | tr -d '"')
        ver=$(sed -n 's/^VERSION_ID=//p' "$file" | tr -d '"')
    fi
    echo "${id:-unknown} ${ver:-unknown}"
}

# Desteklenen sürümler: Ubuntu 22.04, 24.04, 26.04 (ve aradaki ara sürümler).
sys_is_supported() {
    local id ver
    read -r id ver <<< "$(sys_os)"
    [[ "$id" == "ubuntu" ]] || return 1
    case "$ver" in
        22.04|22.10|23.04|23.10|24.04|24.10|25.04|25.10|26.04) return 0 ;;
    esac
    return 1
}

# Kullanıcının /etc/passwd'deki giriş kabuğu
sys_login_shell() {
    getent passwd "$USER" 2>/dev/null | cut -d: -f7
}

# ----------------------------------------------------------------------------
# Başlatma ve kapanış
# ----------------------------------------------------------------------------

TS_EXIT_HOOKS=()

# Kapanışta çalışacak fonksiyon ekle (sudo yenileme döngüsünü durdurmak gibi)
ts_on_exit() { TS_EXIT_HOOKS+=("$1"); }

_ts_run_exit_hooks() {
    local hook
    for hook in "${TS_EXIT_HOOKS[@]}"; do
        "$hook" 2>/dev/null || true
    done
    [[ -n "$TS_TMP" && -d "$TS_TMP" ]] && rm -rf -- "$TS_TMP"
}

_ts_on_interrupt() {
    # Menü açıksa önce terminal normale dönsün; mesaj alternatif ekranda kaybolmasın
    declare -F ui_term_leave >/dev/null && ui_term_leave
    printf '\n'
    log_warn "İptal edildi."
    exit 130
}

ts_init() {
    TS_TMP=$(mktemp -d "${TMPDIR:-/tmp}/terminal-setup.XXXXXXXX") || {
        echo "Geçici dizin oluşturulamadı" >&2
        return 1
    }
    trap _ts_run_exit_hooks EXIT
    trap _ts_on_interrupt INT TERM
    # İndirilen araçlar bu oturumda da bulunabilsin
    case ":$PATH:" in *":$TS_BIN_DIR:"*) ;; *) PATH="$TS_BIN_DIR:$PATH" ;; esac
    log_init
}

# lib/ altındaki tüm modülleri, sonra bileşen/tema/renderer/teşhis
# tanımlarını yükle. Sıra önemlidir: önce motor, sonra veriler.
ts_load() {
    local f
    local engine=(
        log.sh
        ui/style.sh ui/text.sh ui/term.sh ui/draw.sh ui/prompt.sh ui/widgets.sh
        net.sh sudo.sh settings.sh ledger.sh baseline.sh
        actions/pkg.sh actions/fs.sh actions/rc.sh actions/config.sh actions/legacy.sh
        undo.sh runner.sh themes.sh verify.sh uninstall.sh doctor.sh
    )
    for f in "${engine[@]}"; do
        # shellcheck source=/dev/null
        source "$TS_ROOT/lib/$f" || { echo "Modül yüklenemedi: lib/$f" >&2; return 1; }
    done
    for f in "$TS_ROOT"/renderers/*.sh "$TS_ROOT"/components/*/*.sh "$TS_ROOT"/diagnostics/*.sh \
        "$TS_ROOT"/frontends/*.sh "$TS_ROOT"/frontends/tui/*.sh; do
        [[ -f "$f" ]] || continue
        # shellcheck source=/dev/null
        source "$f" || { echo "Tanım yüklenemedi: $f" >&2; return 1; }
    done
    component_sort
}
