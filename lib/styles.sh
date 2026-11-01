#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Kişilikler (styles/*.style)
# ============================================================================
# Tema = palet (renkler) + kişilik (biçim). Kişilik; prompt simgesini ve
# yerleşimini, segment biçimini, kenar stilini, büyük/küçük harfi, ayırıcıyı,
# liste simgelerini, tarih biçimini, bat çerçevesini, git simgelerini ve
# karşılama kartının işaretlerini (CARD_MARKS: uyarı, hata, kaldığınız yer)
# belirler. Bir temanın içinde her şey aynı kişiliği konuşur; temalar
# birbirinden yalnızca renkle değil biçimle de ayrılır. Araçlar (fzf, eza,
# bat, tmux, lazygit, btop) kişiliği kendi renderer'larında okur; kenar
# stilinin araçlardaki karşılığı style_border_for'dadır.
#
# Hangi kişilik: kullanıcının seçtiği (ayar: style) ya da temanın STYLE'ı.
# Dosyalar kaynak olarak yüklenmez (source edilmez); değerler denetlenir.
# ============================================================================

declare -gA STYLE=()

STYLE_DEFAULT=modern
STYLE_REQUIRED_KEYS=(NAME DESC PROMPT_SYMBOL PROMPT_LAYOUT SEGMENTS BORDER TITLE_CASE TEXT_CASE
    SEPARATOR ICONS DATE_FORMAT BAT_STYLE GIT_SYMBOLS CARD_MARKS)

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
# bat --style parçaları (Ubuntu 22.04'teki bat 0.19'un da bildikleri)
STYLE_BAT_PARTS="auto full plain changes header grid rule numbers snip"

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
    [[ -n "${STYLE[PROMPT_SYMBOL]}" ]] || { log_err "%s: %s eksik" "$name" PROMPT_SYMBOL; return 1; }
    # Tarih biçimi zsh, tmux ve eza'ya tırnak içinde yazılır: yalnızca güvenli karakterler
    local date_re='^[+][%A-Za-z0-9 .:/-]+$' part parts
    [[ "${STYLE[DATE_FORMAT]}" =~ $date_re ]] ||
        { log_err "%s: %s geçersiz (%s)" "$name" DATE_FORMAT "${STYLE[DATE_FORMAT]}"; return 1; }
    # Kart işaretleri: uyarı hata kaldığınız-yer; zsh dizgesine yazılır
    local unsafe='[\\"$`'"'"']'
    read -ra parts <<< "${STYLE[CARD_MARKS]}"
    if ((${#parts[@]} != 3)) || [[ "${STYLE[CARD_MARKS]}" =~ $unsafe ]]; then
        log_err "%s: %s geçersiz (%s)" "$name" CARD_MARKS "${STYLE[CARD_MARKS]}"
        return 1
    fi
    IFS=, read -ra parts <<< "${STYLE[BAT_STYLE]}"
    ((${#parts[@]})) || { log_err "%s: %s eksik" "$name" BAT_STYLE; return 1; }
    for part in "${parts[@]}"; do
        in_list "$part" $STYLE_BAT_PARTS ||
            { log_err "%s: %s geçersiz (%s)" "$name" BAT_STYLE "${STYLE[BAT_STYLE]}"; return 1; }
    done
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

# Kişiliğin kenar stili bir aracın dilinde: style_border_for ARAÇ -> REPLY
# Bir aracın karşılığı yoksa en yakını seçilir (tmux'ta yuvarlak bölme
# çizgisi, lazygit'te kalın çizgi yok). btop: rounded_corners değeri.
#
#            fzf      tmux    lazygit  btop
#   rounded  rounded  single  rounded  True
#   sharp    sharp    single  single   False
#   heavy    bold     heavy   single   False
#   double   double   double  double   False
#   none     left     single  hidden   False
style_border_for() {
    local b="${STYLE[BORDER]}"
    case "$1" in
        fzf)
            case "$b" in heavy) REPLY=bold ;; none) REPLY=left ;; *) REPLY="$b" ;; esac ;;
        tmux)
            case "$b" in heavy | double) REPLY="$b" ;; *) REPLY=single ;; esac ;;
        lazygit)
            case "$b" in rounded | double) REPLY="$b" ;; none) REPLY=hidden ;; *) REPLY=single ;; esac ;;
        btop)
            if [[ "$b" == rounded ]]; then REPLY=True; else REPLY=False; fi ;;
        *) return 1 ;;
    esac
}

# fzf seçenekleri (kenar, imleç, istem) -> REPLY
style_fzf_opts() {
    style_border_for fzf
    REPLY="--border=$REPLY --pointer='${STYLE[PROMPT_SYMBOL]}' --prompt='${STYLE[PROMPT_SYMBOL]} '"
}

# Temadan ve kişilikten üretilen ayar dosyalarının başlığı -> REPLY
# (tema ve kişilik yüklü olmalı; açıklama satırları act_write_file'da çevrilir)
style_file_header() {
    _t "Kişilik: %s  Tema: %s" "${STYLE[ID]:-?}" "${THEME[NAME]:-?}"
    REPLY="# Terminal Setup tarafından temadan ve kişilikten üretilir; elle düzenlemeyin."$'\n'"# $TR"
}
