#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Kişilikler (styles/*.style)
# ============================================================================
# Tema = palet (renkler) + kişilik (biçim). Kişilik; prompt simgesini ve
# yerleşimini, segment biçimini, kenar stilini, büyük/küçük harfi, ayırıcıyı,
# liste simgelerini, tarih biçimini, bat çerçevesini ve git simgelerini
# belirler. Bir temanın içinde her şey aynı kişiliği konuşur; temalar
# birbirinden yalnızca renkle değil biçimle de ayrılır.
#
# Hangi kişilik: kullanıcının seçtiği (ayar: style) ya da temanın STYLE'ı.
# Dosyalar kaynak olarak yüklenmez (source edilmez); değerler denetlenir.
# ============================================================================

declare -gA STYLE=()

STYLE_DEFAULT=modern
STYLE_REQUIRED_KEYS=(NAME DESC PROMPT_SYMBOL PROMPT_LAYOUT SEGMENTS BORDER TITLE_CASE TEXT_CASE
    SEPARATOR ICONS DATE_FORMAT BAT_STYLE GIT_SYMBOLS)

# Seçenekli anahtarların izin verilen değerleri
declare -gA STYLE_CHOICES=(
    [PROMPT_LAYOUT]="two-line one-line"
    [SEGMENTS]="plain minimal powerline pills brackets arrows"
    [BORDER]="rounded sharp heavy double none"
    [TITLE_CASE]="normal lower upper"
    [TEXT_CASE]="normal lower upper"
    [ICONS]="on off"
    [GIT_SYMBOLS]="unicode ascii minimal"
)

style_list() {
    local f
    for f in "$TS_ROOT"/styles/*.style; do
        [[ -f "$f" ]] && basename "$f" .style
    done | LC_ALL=C sort
}

style_exists() { [[ "$1" =~ ^[a-z0-9-]+$ && -f "$TS_ROOT/styles/$1.style" ]]; }

# Kişilik dosyasını oku ve denetle -> STYLE
style_load() {
    local name="$1" file key value
    file="$TS_ROOT/styles/$name.style"
    style_exists "$name" || { log_err "Kişilik bulunamadı: %s" "$name"; return 1; }
    STYLE=([ID]="$name")
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^[A-Z_]+$ ]] || continue
        value="${value#\"}"
        value="${value%\"}"
        STYLE[$key]="$value"
    done < "$file"
    for key in "${STYLE_REQUIRED_KEYS[@]}"; do
        [[ -n "${STYLE[$key]+x}" ]] || { log_err "%s: %s eksik" "$name" "$key"; return 1; }
    done
    for key in "${!STYLE_CHOICES[@]}"; do
        in_list "${STYLE[$key]}" ${STYLE_CHOICES[$key]} ||
            { log_err "%s: %s geçersiz (%s)" "$name" "$key" "${STYLE[$key]}"; return 1; }
    done
    [[ -n "${STYLE[PROMPT_SYMBOL]}" && "${STYLE[DATE_FORMAT]}" == +* ]] ||
        { log_err "%s: PROMPT_SYMBOL ya da DATE_FORMAT geçersiz" "$name"; return 1; }
}

# Geçerli kişiliğin adı -> REPLY: kullanıcının seçimi, yoksa temanınki
style_effective() {
    local chosen
    chosen=$(settings_get style auto)
    if [[ "$chosen" != auto ]] && style_exists "$chosen"; then
        REPLY="$chosen"
    elif style_exists "${THEME[STYLE]:-}"; then
        REPLY="${THEME[STYLE]}"
    else
        REPLY="$STYLE_DEFAULT"
    fi
}

# Kenar karakterleri: style_box -> REPLY="sol-üst sağ-üst sol-alt sağ-alt yatay dikey"
style_box() {
    case "${STYLE[BORDER]}" in
        sharp)  REPLY="┌ ┐ └ ┘ ─ │" ;;
        heavy)  REPLY="┏ ┓ ┗ ┛ ━ ┃" ;;
        double) REPLY="╔ ╗ ╚ ╝ ═ ║" ;;
        none)   REPLY="▏ ▏ ▏ ▏ ─ ▏" ;;   # kutu yok: yalnızca ince sol çizgi
        *)      REPLY="╭ ╮ ╰ ╯ ─ │" ;;
    esac
}

# Kişiliğe göre büyük/küçük harf: style_case title|text METİN -> REPLY
style_case() {
    local mode="${STYLE[TITLE_CASE]}"
    [[ "$1" == text ]] && mode="${STYLE[TEXT_CASE]}"
    REPLY="$2"
    # Türkçede i/İ ve ı/I ayrı harflerdir; bash'in dönüşümü bunu bilmez
    case "$mode" in
        upper) [[ "${TS_LANG:-}" == tr ]] && REPLY="${REPLY//i/İ}"; REPLY="${REPLY^^}" ;;
        lower) [[ "${TS_LANG:-}" == tr ]] && { REPLY="${REPLY//I/ı}"; REPLY="${REPLY//İ/i}"; }; REPLY="${REPLY,,}" ;;
    esac
}

# fzf seçenekleri (kenar, imleç, istem) -> REPLY
style_fzf_opts() {
    local border
    case "${STYLE[BORDER]}" in
        heavy) border=bold ;;
        none) border=left ;;
        *) border="${STYLE[BORDER]}" ;;
    esac
    REPLY="--border=$border --pointer='${STYLE[PROMPT_SYMBOL]}' --prompt='${STYLE[PROMPT_SYMBOL]} '"
}
