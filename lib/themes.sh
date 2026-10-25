#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Tema motoru
# ============================================================================
# Tema = veri (themes/*.theme: 16 renk + ön/arka plan). Terminal = renderer
# (renderers/*.sh). Yeni tema tek dosya, yeni terminal tek renderer'dır.
#
# Renderer sözleşmesi:
#   renderer_register kimlik "Ad"
#   rend_<kimlik>_available   terminal bu sistemde var mı?
#   rend_<kimlik>_apply       THEME[...] dizisindeki renkleri uygula
#   rend_<kimlik>_font        (isteğe bağlı) MesloLGS NF yazı tipini ayarla
# ============================================================================

declare -gA THEME=()
declare -ga RENDERER_IDS=()
declare -gA RENDERER_NAME=()

THEME_REQUIRED_KEYS=(NAME BACKGROUND FOREGROUND CURSOR SELECTION_BG SELECTION_FG ACCENT BORDER)
TS_FONT_NAME="MesloLGS NF"
TS_FONT_SIZE=11

renderer_register() {
    RENDERER_IDS+=("$1")
    RENDERER_NAME[$1]="$2"
}

renderers_available() {
    local id
    for id in "${RENDERER_IDS[@]}"; do
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
    theme_exists "$name" || { log_err "Tema bulunamadı: $name"; return 1; }
    THEME=([ID]="$name")
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^[A-Z0-9_]+$ ]] || continue
        value="${value#\"}"
        value="${value%\"}"
        THEME[$key]="$value"
    done < "$file"
    for key in "${THEME_REQUIRED_KEYS[@]}"; do
        [[ -n "${THEME[$key]:-}" ]] || { log_err "$name: $key eksik"; return 1; }
    done
    for ((i = 0; i < 16; i++)); do
        [[ "${THEME[COLOR$i]:-}" =~ ^#[0-9A-Fa-f]{6}$ ]] || { log_err "$name: COLOR$i geçersiz"; return 1; }
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

# Temanın önizlemesi: temanın renkleriyle çizilmiş küçük bir terminal
# penceresi ve 16 renklik palet. Terminalin kendi renklerinden bağımsızdır
# (24 bit renk kodları kullanılır).
_tp_fg() { printf '\033[38;2;%sm' "$(theme_rgb "${THEME[$1]}")"; }
_tp_bg() { printf '\033[48;2;%sm' "$(theme_rgb "${THEME[$1]}")"; }

# Pencere satırı: arka plan rengiyle genişliğe tamamlanır
_tp_row() {
    local n
    ui_vlen "$1"
    n=$((_TP_W - UI_LEN))
    ((n < 0)) && n=0
    ui_line "  ${_TP_BG}$1${_TP_BG}$(printf '%*s' "$n" '')${U_RST:-$'\033[0m'}"
}

theme_preview() {
    theme_load "$1" || return 1
    local bg fg title dim i line="" bar rst=$'\033[0m' n
    ui_layout
    _TP_W=$((UI_W - 4))
    ((_TP_W > 64)) && _TP_W=64
    _TP_BG=$(_tp_bg BACKGROUND)
    bg="$_TP_BG" fg=$(_tp_fg FOREGROUND) dim=$(_tp_fg COLOR8)
    bar=$(_tp_bg BORDER)

    ui_line "  ${U_BOLD}${THEME[NAME]}${rst}  ${U_MUTED:-}${THEME[DESC]:-}${rst}"
    ui_line ""
    # Başlık çubuğu: üstte yarım blokla yumuşatılmış kenar
    printf -v line '%*s' "$_TP_W" ''
    ui_line "  $(_tp_fg BORDER)${line// /▄}${rst}"
    title="${THEME[NAME]}"
    n=$(((_TP_W - ${#title}) / 2 - 7))
    ((n < 1)) && n=1
    line=" $(_tp_fg COLOR1)●$(_tp_fg COLOR3) ●$(_tp_fg COLOR2) ●$(printf '%*s' "$n" '')${fg}${title}"
    ui_vlen "$line"
    ui_line "  ${bar}${line}${bar}$(printf '%*s' $((_TP_W - UI_LEN)) '')${rst}"

    _tp_row ""
    _tp_row " $(_tp_bg ACCENT)$(_tp_fg BACKGROUND) ~/projeler ${bg}$(_tp_bg COLOR2)$(_tp_fg BACKGROUND) main ✓ ${bg}${fg} ls"
    _tp_row " $(_tp_fg COLOR4)src/  docs/  ${fg}README.md  $(_tp_fg COLOR2)kur.sh  ${dim}.env"
    _tp_row " $(_tp_fg ACCENT)❯ ${fg}git status"
    _tp_row "   $(_tp_fg COLOR1)değiştirildi:  lib/ui.sh"
    _tp_row "   $(_tp_fg COLOR2)yeni dosya:    tema.sh"
    _tp_row " $(_tp_fg ACCENT)❯ ${fg}echo $(_tp_fg COLOR3)\"merhaba dünya\" ${dim}# yorum"
    _tp_row " ${fg}merhaba dünya"
    _tp_row " $(_tp_fg ACCENT)❯ ${fg}$(_tp_bg CURSOR) ${bg}"
    printf -v line '%*s' "$_TP_W" ''
    ui_line "  $(_tp_fg BACKGROUND)${line// /▀}${rst}"
    ui_line ""

    # Palet: üstte normal, altta parlak 8 renk
    line=""
    for ((i = 0; i < 16; i++)); do
        line+="\033[48;2;$(theme_rgb "${THEME[COLOR$i]}")m      ${rst} "
        if ((i == 7)); then
            ui_line "  $(printf '%b' "$line") ${U_MUTED:-}normal${rst}"
            line=""
        fi
    done
    ui_line "  $(printf '%b' "$line") ${U_MUTED:-}parlak${rst}"
}

# Temayı uygun tüm terminallere uygula
theme_apply() {
    local name="$1" id applied=0 owner="$TS_CURRENT_COMPONENT"
    theme_load "$name" || return 1
    TS_CURRENT_COMPONENT="theme"
    for id in $(renderers_available); do
        log_step "${RENDERER_NAME[$id]}: ${THEME[NAME]} uygulanıyor"
        if "rend_${id}_apply"; then
            applied=$((applied + 1))
        else
            log_warn "${RENDERER_NAME[$id]} için tema uygulanamadı"
        fi
    done
    TS_CURRENT_COMPONENT="$owner"
    if ((applied == 0)); then
        log_err "Desteklenen terminal bulunamadı (GNOME Terminal, Ptyxis, Kitty, Alacritty)."
        return 1
    fi
    settings_set theme "$name"
    is_dry_run || log_ok "${THEME[NAME]} teması uygulandı. Yeni açılan pencerelerde görünür."
}

# Yazı tipini uygun terminallere ayarla (fonts bileşeni çağırır)
theme_apply_font() {
    local id
    for id in $(renderers_available); do
        declare -F "rend_${id}_font" >/dev/null || continue
        "rend_${id}_font" || log_warn "${RENDERER_NAME[$id]} için yazı tipi ayarlanamadı"
    done
    return 0
}
