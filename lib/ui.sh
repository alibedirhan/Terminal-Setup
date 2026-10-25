#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Arayüz yapı taşları
# ============================================================================
# Bağımlılıksız terminal arayüzü: renk paleti, genişlik hesabı, kartlar,
# tuş okuma ve onay soruları. Menü ve çoklu seçim listesi ui_widgets.sh'tadır.
#
# Renk: terminal 24 bit renk destekliyorsa (COLORTERM=truecolor) gerçek renk,
# 256 renkte en yakın tonlar, aksi halde 8 temel renk kullanılır. NO_COLOR
# tanımlıysa ya da çıktı terminal değilse hiç renk yoktur.
#
# Genişlik: kaçış dizileri ayıklanıp karakter sayılır; bu yüzden yalnızca
# tek hücre genişliğinde simgeler kullanılır (emoji yok). Böylece kartların
# sağ kenarı Türkçe karakterlerde de kaymaz.
# ============================================================================

UI_CHOICE=""          # ui_menu sonucu (seçilebilir öğeler arasında 0'dan sıra)
UI_SELECTED=()        # ui_checklist sonucu (seçilen sıralar)
UI_HEADER_FN=""       # her çizimde üstte gösterilecek fonksiyon (durum çubuğu)
UI_SUBTITLE=""        # menü başlığının altında gösterilecek açıklama
UI_KEY=""             # ui_read_key sonucu
UI_LEN=0              # ui_vlen sonucu
UI_COLS=80 UI_ROWS=24 # terminal boyutu (ui_layout)
UI_W=80               # içerik genişliği
UI_M=""               # sol boşluk (menülerde içerik ortalanır)
UI_CENTER=0           # 1 ise ui_layout içeriği ortalar
UI_BUF=""             # çerçeve tamponu: tüm ekran tek seferde yazılır
UI_BUFFERING=0
UI_RESIZED=0

# Bash karakter sayarken yerel ayarı kullanır; UTF-8 değilse Türkçe harfler
# iki bayt sayılır ve hizalama kayar.
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *[Uu][Tt][Ff]-8* | *[Uu][Tt][Ff]8*) ;;
    *) [[ -z "${LC_ALL:-}" ]] && LC_CTYPE=C.UTF-8 ;;
esac

# ----------------------------------------------------------------------------
# Renk paleti
# ----------------------------------------------------------------------------

UI_COLOR_DEPTH=0      # 0 renksiz, 8, 256, 24

ui_colors_init() {
    U_RST="" U_BOLD="" U_ACC="" U_ACC2="" U_PINK="" U_MUTED="" U_FAINT=""
    U_OK="" U_WARN="" U_ERR="" U_INFO="" U_SEL="" U_CAP="" U_SURF=""
    UI_COLOR_DEPTH=0
    [[ -n "$C_RESET" ]] || return 0
    U_RST=$'\033[0m' U_BOLD=$'\033[1m'
    if [[ "${COLORTERM:-}" == truecolor || "${COLORTERM:-}" == 24bit ]]; then
        UI_COLOR_DEPTH=24
        U_ACC=$'\033[38;2;167;139;250m'    # menekşe
        U_ACC2=$'\033[38;2;103;232;249m'   # camgöbeği
        U_PINK=$'\033[38;2;244;114;182m'
        U_MUTED=$'\033[38;2;128;134;155m'
        U_FAINT=$'\033[38;2;76;80;99m'
        U_OK=$'\033[38;2;74;222;128m'
        U_WARN=$'\033[38;2;251;191;36m'
        U_ERR=$'\033[38;2;248;113;113m'
        U_INFO=$'\033[38;2;96;165;250m'
        U_SEL=$'\033[48;2;46;43;72m\033[38;2;237;235;255m'
        U_CAP=$'\033[48;2;55;58;78m\033[38;2;220;222;235m'
        U_SURF=$'\033[48;2;36;38;52m'
    elif [[ "${TERM:-}" == *256color* ]]; then
        UI_COLOR_DEPTH=256
        U_ACC=$'\033[38;5;141m' U_ACC2=$'\033[38;5;117m' U_PINK=$'\033[38;5;211m'
        U_MUTED=$'\033[38;5;245m' U_FAINT=$'\033[38;5;239m'
        U_OK=$'\033[38;5;78m' U_WARN=$'\033[38;5;214m' U_ERR=$'\033[38;5;203m' U_INFO=$'\033[38;5;75m'
        U_SEL=$'\033[48;5;237m\033[38;5;255m'
        U_CAP=$'\033[48;5;238m\033[38;5;253m'
        U_SURF=$'\033[48;5;235m'
    else
        UI_COLOR_DEPTH=8
        U_ACC=$'\033[35m' U_ACC2=$'\033[36m' U_PINK=$'\033[35m'
        U_MUTED=$'\033[2m' U_FAINT=$'\033[2m'
        U_OK=$'\033[32m' U_WARN=$'\033[33m' U_ERR=$'\033[31m' U_INFO=$'\033[34m'
        U_SEL=$'\033[7m' U_CAP=$'\033[7m' U_SURF=""
    fi
}
ui_colors_init

# Renk geçişi: ui_gradient_fg KONUM TOPLAM -> ön plan kaçış dizisi
# Camgöbeği -> menekşe -> pembe. 256 renkte kademeli tonlar kullanılır.
_UI_GRAD_256=(117 117 111 147 141 141 177 213 211 211)
ui_gradient_fg() {
    local pos="$1" total="$2" t r g b
    case "$UI_COLOR_DEPTH" in
        24)
            ((total < 2)) && total=2
            t=$((pos * 1000 / (total - 1)))
            if ((t < 500)); then
                r=$((103 + (167 - 103) * t / 500)); g=$((232 + (139 - 232) * t / 500)); b=$((249 + (250 - 249) * t / 500))
            else
                t=$((t - 500))
                r=$((167 + (244 - 167) * t / 500)); g=$((139 + (114 - 139) * t / 500)); b=$((250 + (182 - 250) * t / 500))
            fi
            printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b" ;;
        256) printf '\033[38;5;%dm' "${_UI_GRAD_256[pos * 10 / (total > 0 ? total : 1)]:-211}" ;;
        8) printf '%s' "$U_ACC2" ;;
    esac
}

# Metni harf harf renk geçişiyle boya (boşluklar renk almaz)
ui_gradient_text() {
    local s="$1" total="${2:-${#1}}" offset="${3:-0}" i out="" ch
    if ((UI_COLOR_DEPTH == 0)); then printf '%s' "$s"; return; fi
    for ((i = 0; i < ${#s}; i++)); do
        ch="${s:i:1}"
        if [[ "$ch" == " " ]]; then out+=" "; else out+="$(ui_gradient_fg $((i + offset)) "$total")$ch"; fi
    done
    printf '%s%s' "$out" "$U_RST"
}

# ----------------------------------------------------------------------------
# Ölçü ve yerleşim
# ----------------------------------------------------------------------------

ui_is_tty() { [[ -t 0 && -t 1 ]]; }

# Görünen uzunluk (renk kodları sayılmaz) -> UI_LEN
ui_vlen() {
    local s="$1" out=""
    while [[ "$s" == *$'\033['* ]]; do
        out+="${s%%$'\033['*}"
        s="${s#*$'\033['}"
        s="${s#*m}"
    done
    out+="$s"
    UI_LEN=${#out}
}

# Düz metni en fazla N karaktere kısalt: ui_trunc "metin" N
ui_trunc() {
    local s="$1" n="$2"
    ((n < 1)) && { printf ''; return; }
    if ((${#s} > n)); then printf '%s…' "${s:0:n-1}"; else printf '%s' "$s"; fi
}

# Karakter sayarak sağa boşluk doldur (printf %-Ns baytı sayar; Türkçe
# karakterlerde hizalama kayar). Renk kodları sayılmaz. ui_pad "metin" genişlik
ui_pad() {
    local n
    ui_vlen "$1"
    n=$(($2 - UI_LEN))
    ((n < 1)) && n=1
    printf '%s%*s' "$1" "$n" ''
}

ui_layout() {
    local size cols="" rows=""
    if ui_is_tty && size=$(stty size 2>/dev/null); then
        rows=${size% *} cols=${size#* }
    fi
    [[ "$cols" =~ ^[0-9]+$ ]] || cols=${COLUMNS:-80}
    [[ "$rows" =~ ^[0-9]+$ ]] || rows=${LINES:-24}
    [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
    [[ "$rows" =~ ^[0-9]+$ ]] || rows=24
    UI_COLS=$cols UI_ROWS=$rows
    UI_W=$((cols - 4))
    ((UI_W > 84)) && UI_W=84
    ((UI_W < 40)) && UI_W=40
    if ((UI_CENTER && cols > UI_W)); then
        printf -v UI_M '%*s' $(((cols - UI_W) / 2)) ''
    else
        UI_M=""
    fi
}

ui_width() { ui_layout; echo "$UI_W"; }

# ----------------------------------------------------------------------------
# Çıktı: satırlar ya tampona (menü çizimi) ya doğrudan ekrana gider
# ----------------------------------------------------------------------------

ui_line() {
    if ((UI_BUFFERING)); then
        UI_BUF+="${UI_M}$1${U_RST}"$'\033[K\n'
    else
        printf '%s%s%s\n' "$UI_M" "$1" "$U_RST"
    fi
}

ui_frame_begin() {
    ui_layout
    UI_BUF="" UI_BUFFERING=1
}

# Tamponu tek seferde yaz: imleç başa, satır sonları ve ekranın kalanı temizlenir.
# Böylece her tuşta ekran silinip yeniden çizilmez, titreme olmaz.
ui_frame_end() {
    UI_BUFFERING=0
    if ((UI_RESIZED)); then UI_RESIZED=0; printf '\033[H\033[2J'; fi
    printf '\033[H%s\033[J' "$UI_BUF"
    UI_BUF=""
}

# Tamponda şu ana kadar kaç satır var
ui_frame_lines() {
    local nl="${UI_BUF//[!$'\n']/}"
    echo "${#nl}"
}

ui_rule() {
    local line
    ui_layout
    printf -v line '%*s' "$UI_W" ''
    ui_line "${U_FAINT}${line// /─}"
}

# Bölüm başlığı: "◆ Başlık" ve altında ince çizgi
ui_title() {
    ((UI_BUFFERING)) || printf '\n'
    ui_layout
    ui_line "${U_ACC}◆${U_RST} ${U_BOLD}$*${U_RST}"
    ui_rule
}

# Küçük bölüm etiketi: "KABUK ───────"
ui_section() {
    ui_layout
    ui_line "$(_ui_section_str "$1")"
}

# Yuvarlak köşeli kart: ui_card_top "Başlık" ; ui_card_row "içerik" ; ui_card_bottom
ui_card_top() {
    local title="$1" line n
    ui_layout
    if [[ -n "$title" ]]; then
        ui_vlen "$title"
        n=$((UI_W - UI_LEN - 5))
        ((n < 1)) && n=1
        printf -v line '%*s' "$n" ''
        ui_line "${U_FAINT}╭─${U_RST} ${U_BOLD}${title}${U_RST} ${U_FAINT}${line// /─}╮"
    else
        printf -v line '%*s' $((UI_W - 2)) ''
        ui_line "${U_FAINT}╭${line// /─}╮"
    fi
}

ui_card_row() {
    local n
    ui_vlen "$1"
    n=$((UI_W - 4 - UI_LEN))
    ((n < 0)) && n=0
    ui_line "${U_FAINT}│${U_RST} $1${U_RST}$(printf '%*s' "$n" '') ${U_FAINT}│"
}

ui_card_bottom() {
    local line
    printf -v line '%*s' $((UI_W - 2)) ''
    ui_line "${U_FAINT}╰${line// /─}╯"
}

# Tuş ipuçları: ui_keys "↑↓" "gez" "enter" "seç" ...
ui_keys() {
    local out=""
    while (($# >= 2)); do
        out+="${U_CAP} $1 ${U_RST} ${U_MUTED}$2${U_RST}   "
        shift 2
    done
    ui_line "$out"
}

# Durum rozeti: ui_badge ok|warn|err|info|off "metin"
ui_badge() {
    local color
    case "$1" in
        ok) color="$U_OK" ;; warn) color="$U_WARN" ;; err) color="$U_ERR" ;;
        info) color="$U_INFO" ;; acc) color="$U_ACC" ;; *) color="$U_MUTED" ;;
    esac
    printf '%s●%s %s' "$color" "$U_RST" "$2"
}

ui_clear() { ui_is_tty && printf '\033[H\033[2J'; return 0; }

ui_pause() {
    [[ "$TS_ASSUME_YES" == "1" ]] && return 0
    ui_is_tty || return 0
    printf '\n%s%s enter %s %sdevam etmek için basın%s ' "$UI_M" "$U_CAP" "$U_RST" "$U_MUTED" "$U_RST"
    read -r _ || true
}

# Evet/hayır sorusu. ui_confirm "Soru" [e|h varsayılan]
ui_confirm() {
    local question="$1" default="${2:-h}" answer hint
    [[ "$TS_ASSUME_YES" == "1" ]] && return 0
    [[ "$default" == "e" ]] && hint="E/h" || hint="e/H"
    _ui_cursor_show
    while true; do
        printf '%s%s?%s %s%s%s %s(%s)%s %s›%s ' "$UI_M" "$U_ACC" "$U_RST" "$U_BOLD" "$question" "$U_RST" \
            "$U_MUTED" "$hint" "$U_RST" "$U_ACC" "$U_RST"
        IFS= read -r answer || return 1
        answer="${answer:-$default}"
        case "${answer,,}" in
            e|evet|y|yes) return 0 ;;
            h|hayır|hayir|n|no) return 1 ;;
        esac
        printf '%s%s\n' "$UI_M" "${U_MUTED}Lütfen 'e' veya 'h' girin.${U_RST}"
    done
}

# Tehlikeli işlem için kelime yazdırarak onay: ui_type_confirm "kaldır"
ui_type_confirm() {
    local word="$1" answer
    [[ "$TS_ASSUME_YES" == "1" ]] && return 0
    _ui_cursor_show
    printf '%s%s!%s Onaylamak için %s%s%s yazın %s›%s ' "$UI_M" "$U_ERR" "$U_RST" "$U_BOLD" "$word" "$U_RST" "$U_ERR" "$U_RST"
    IFS= read -r answer || return 1
    [[ "$answer" == "$word" ]]
}

# ----------------------------------------------------------------------------
# Tuş okuma
# ----------------------------------------------------------------------------

# Tek tuş oku -> UI_KEY: up down left right home end pgup pgdn enter space
# esc eof resize ya da basılan karakter. Alt kabukta çalışmaz (pencere
# boyutu sinyali yakalanabilsin diye sonuç değişkene yazılır).
ui_read_key() {
    local k="" c1="" c2="" c3="" rc
    IFS= read -rsn1 k
    rc=$?
    if ((rc > 128)); then UI_KEY=resize; return 0; fi
    if ((rc != 0)); then UI_KEY=eof; return 0; fi
    case "$k" in
        $'\033')
            IFS= read -rsn1 -t 0.05 c1 || true
            if [[ "$c1" == "[" || "$c1" == "O" ]]; then
                IFS= read -rsn1 -t 0.05 c2 || true
                if [[ "$c2" == [0-9] ]]; then
                    IFS= read -rsn1 -t 0.05 c3 || true
                    [[ "$c3" == "~" ]] || c2=""
                fi
            fi
            case "$c2" in
                A) UI_KEY=up ;; B) UI_KEY=down ;; C) UI_KEY=right ;; D) UI_KEY=left ;;
                H|1|7) UI_KEY=home ;; F|4|8) UI_KEY=end ;; 5) UI_KEY=pgup ;; 6) UI_KEY=pgdn ;;
                *) UI_KEY=esc ;;
            esac ;;
        "") UI_KEY=enter ;;
        " ") UI_KEY=space ;;
        *) UI_KEY="$k" ;;
    esac
}

_ui_cursor_hide() { ui_is_tty && printf '\033[?25l'; return 0; }
_ui_cursor_show() { ui_is_tty && printf '\033[?25h'; return 0; }

# Menü oturumu: içerik ortalanır, pencere boyutu değişince yeniden çizilir
ui_session_begin() {
    UI_CENTER=1
    ui_is_tty || return 0
    trap 'UI_RESIZED=1' WINCH
    ts_on_exit _ui_cursor_show
}

ui_session_end() {
    UI_CENTER=0
    ui_is_tty || return 0
    trap - WINCH
    _ui_cursor_show
}
