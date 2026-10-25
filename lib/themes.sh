#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Tema motoru
# ============================================================================
# Tema = veri (themes/*.theme: 16 renk + ön/arka plan). Terminal = renderer
# (renderers/*.sh). Yeni tema tek dosya, yeni terminal tek renderer'dır.
#
# Renderer sözleşmesi:
#   renderer_register kimlik "Ad" [terminal|tool]
#   rend_<kimlik>_available   terminal ya da araç bu sistemde var mı?
#   rend_<kimlik>_apply       THEME[...] dizisindeki renkleri uygula
#   rend_<kimlik>_font        (isteğe bağlı) MesloLGS NF yazı tipini ayarla
# ============================================================================

declare -gA THEME=()
declare -ga RENDERER_IDS=()
declare -gA RENDERER_NAME=()
declare -gA RENDERER_KIND=()   # terminal: renkleri terminale; tool: bir araca (bat, btop)

THEME_REQUIRED_KEYS=(NAME BACKGROUND FOREGROUND CURSOR SELECTION_BG SELECTION_FG ACCENT BORDER)
TS_FONT_NAME="MesloLGS NF"
TS_FONT_SIZE=11

renderer_register() {
    RENDERER_IDS+=("$1")
    RENDERER_NAME[$1]="$2"
    RENDERER_KIND[$1]="${3:-terminal}"
}

# Bu sistemde uygulanabilen renderer'lar: renderers_available [terminal|tool]
# shellcheck disable=SC2120  # tür argümanı başka dosyalardan (durum, teşhis) verilir
renderers_available() {
    local id kind="${1:-}"
    for id in "${RENDERER_IDS[@]}"; do
        [[ -n "$kind" && "${RENDERER_KIND[$id]}" != "$kind" ]] && continue
        "rend_${id}_available" 2>/dev/null && echo "$id"
    done
}

theme_list() {
    local f
    for f in "$TS_ROOT"/themes/*.theme; do
        [[ -f "$f" ]] && basename "$f" .theme
    done
}

theme_exists() { [[ -f "$TS_ROOT/themes/$1.theme" ]]; }

# Tema dosyasını güvenli biçimde oku (source edilmez). THEME dizisini doldurur.
theme_load() {
    local name="$1" file="$TS_ROOT/themes/$1.theme" key value i
    theme_exists "$name" || { log_err "Tema bulunamadı: %s" "$name"; return 1; }
    THEME=([ID]="$name")
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^[A-Z0-9_]+$ ]] || continue
        value="${value#\"}"
        value="${value%\"}"
        THEME[$key]="$value"
    done < "$file"
    for key in "${THEME_REQUIRED_KEYS[@]}"; do
        [[ -n "${THEME[$key]:-}" ]] || { log_err "%s: %s eksik" "$name" "$key"; return 1; }
    done
    for ((i = 0; i < 16; i++)); do
        [[ "${THEME[COLOR$i]:-}" =~ ^#[0-9A-Fa-f]{6}$ ]] || { log_err "%s: %s geçersiz" "$name" "COLOR$i"; return 1; }
    done
}

# "#RRGGBB" -> "R;G;B" (true-color kaçış kodları için)
theme_rgb() {
    local h="${1#\#}"
    printf '%d;%d;%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

# GNOME/dconf palet dizisi: ['#..', ...]
theme_palette_gvariant() {
    local i out="["
    for ((i = 0; i < 16; i++)); do
        out+="'${THEME[COLOR$i]}'"
        ((i < 15)) && out+=", "
    done
    echo "$out]"
}

# ----------------------------------------------------------------------------
# Önizleme: temanın kendi renkleriyle çizilmiş küçük bir terminal penceresi
# ve 16 renklik palet. Terminalin renklerinden bağımsızdır (24 bit kodlar).
# Parçalar ayrı çağrılabilir; menü ekran yüksekliğine göre seçer.
# ----------------------------------------------------------------------------

THEME_PREVIEW_WINDOW_ROWS=12
THEME_PREVIEW_PALETTE_ROWS=2

# Yüklü temanın renk kodları: TPF[ANAHTAR] ön plan, TPB[ANAHTAR] arka plan
declare -gA TPF=() TPB=()
_tp_load_colors() {
    local key h
    TPF=() TPB=()
    for key in BACKGROUND FOREGROUND CURSOR ACCENT BORDER COLOR{0..15}; do
        h="${THEME[$key]#\#}"
        printf -v "TPF[$key]" '\033[38;2;%d;%d;%dm' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
        printf -v "TPB[$key]" '\033[48;2;%d;%d;%dm' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
    done
}

# Pencere içi satır: zemin rengiyle pencere genişliğine tamamlanır
_tp_row() {
    ui_padr "${TPB[BACKGROUND]}$1${TPB[BACKGROUND]}" "$2"
    ui_line "  $REPLY"$'\033[0m'
}

theme_preview_title() {
    _t "${THEME[DESC]:-}"
    ui_line "  ${U_BOLD}${THEME[NAME]}${U_RST}  ${U_MUTED}${TR}${U_RST}"
}

# theme_preview_window [GENİŞLİK] — tema yüklü olmalı
theme_preview_window() {
    local w="${1:-64}" bg fg dim acc edge title n rst=$'\033[0m'
    _tp_load_colors
    bg="${TPB[BACKGROUND]}" fg="${TPF[FOREGROUND]}" dim="${TPF[COLOR8]}" acc="${TPF[ACCENT]}"
    # Başlık çubuğu; üst kenar yarım blokla yumuşatılır
    ui_repeat "▄" "$w"
    ui_line "  ${TPF[BORDER]}$REPLY$rst"
    title="${THEME[NAME]}"
    n=$(((w - ${#title}) / 2 - 7))
    ((n < 1)) && n=1
    printf -v edge '%*s' "$n" ''
    ui_padr "${TPB[BORDER]} ${TPF[COLOR1]}●${TPF[COLOR3]} ●${TPF[COLOR2]} ●${edge}${fg}${title}" "$w"
    ui_line "  $REPLY$rst"
    _tp_row "" "$w"
    local -a s
    # shellcheck disable=SC2088  # yol değil, önizlemede görünen metin
    _t "~/projeler"; s[0]="$TR"
    _t "kur.sh"; s[1]="$TR"
    _t "değiştirildi:"; s[2]="$TR"
    _t "yeni dosya:"; s[3]="$TR"
    _t "tema.sh"; s[4]="$TR"
    _t "merhaba dünya"; s[5]="$TR"
    _t "# yorum"; s[6]="$TR"
    _tp_row " ${TPB[ACCENT]}${TPF[BACKGROUND]} ${s[0]} ${TPB[COLOR2]} main ✓ ${bg}${fg} ls" "$w"
    _tp_row " ${TPF[COLOR4]}src/  docs/  ${fg}README.md  ${TPF[COLOR2]}${s[1]}  ${dim}.env" "$w"
    _tp_row " ${acc}❯ ${fg}git status" "$w"
    printf -v REPLY '%-14s' "${s[2]}"
    _tp_row "   ${TPF[COLOR1]}${REPLY} lib/ui.sh" "$w"
    printf -v REPLY '%-14s' "${s[3]}"
    _tp_row "   ${TPF[COLOR2]}${REPLY} ${s[4]}" "$w"
    _tp_row " ${acc}❯ ${fg}echo ${TPF[COLOR3]}\"${s[5]}\" ${dim}${s[6]}" "$w"
    _tp_row " ${fg}${s[5]}" "$w"
    _tp_row " ${acc}❯ ${TPB[CURSOR]} ${bg}" "$w"
    ui_repeat "▀" "$w"
    ui_line "  ${TPF[BACKGROUND]}$REPLY$rst"
}

# theme_preview_palette [KUTU-GENİŞLİĞİ] — üstte normal, altta parlak 8 renk
theme_preview_palette() {
    local sw="${1:-6}" i row line="" box
    _tp_load_colors
    printf -v box '%*s' "$sw" ''
    for row in 0 8; do
        line=""
        for ((i = row; i < row + 8; i++)); do line+="${TPB[COLOR$i]}$box"$'\033[0m '; done
        if ((row == 0)); then _t "normal"; else _t "parlak"; fi
        ui_line "  $line ${U_MUTED}${TR}"
    done
}

# Komut satırı önizlemesi: başlık, pencere ve palet
theme_preview() {
    theme_load "$1" || return 1
    local w
    ui_layout
    w=$((UI_W - 4))
    ((w > 64)) && w=64
    theme_preview_title
    ui_line ""
    theme_preview_window "$w"
    ui_line ""
    theme_preview_palette 6
}

# Temayı uygun tüm terminallere uygula
theme_apply() {
    local name="$1" id applied=0 owner="$TS_CURRENT_COMPONENT"
    theme_load "$name" || return 1
    TS_CURRENT_COMPONENT="theme"
    for id in $(renderers_available); do
        log_step "%s: %s uygulanıyor" "${RENDERER_NAME[$id]}" "${THEME[NAME]}"
        if "rend_${id}_apply"; then
            applied=$((applied + 1))
        else
            log_warn "%s için tema uygulanamadı" "${RENDERER_NAME[$id]}"
        fi
    done
    TS_CURRENT_COMPONENT="$owner"
    if ((applied == 0)); then
        log_err "Desteklenen terminal bulunamadı (GNOME Terminal, Ptyxis, Kitty, Alacritty)."
        return 1
    fi
    settings_set theme "$name"
    is_dry_run || log_ok "%s teması uygulandı. Yeni açılan pencerelerde görünür." "${THEME[NAME]}"
}

# Yazı tipini uygun terminallere ayarla (fonts bileşeni çağırır)
theme_apply_font() {
    local id
    for id in $(renderers_available); do
        declare -F "rend_${id}_font" >/dev/null || continue
        "rend_${id}_font" || log_warn "%s için yazı tipi ayarlanamadı" "${RENDERER_NAME[$id]}"
    done
    return 0
}
