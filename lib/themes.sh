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

# Temanın önizlemesi: renk blokları ve örnek bir prompt
theme_preview() {
    theme_load "$1" || return 1
    local bg fg acc i line="" sw
    bg=$(theme_rgb "${THEME[BACKGROUND]}")
    fg=$(theme_rgb "${THEME[FOREGROUND]}")
    acc=$(theme_rgb "${THEME[ACCENT]}")
    printf '\n  %s%s%s  %s\n\n' "$C_BOLD" "${THEME[NAME]}" "$C_RESET" "${C_DIM}${THEME[DESC]:-}${C_RESET}"
    for ((i = 0; i < 16; i++)); do
        sw=$(theme_rgb "${THEME[COLOR$i]}")
        line+=$'\033[48;2;'"${sw}m    "$'\033[0m'
        ((i == 7)) && { printf '  %s\n' "$line"; line=""; }
    done
    printf '  %s\n\n' "$line"
    printf '  \033[48;2;%sm\033[38;2;%sm  ~/projeler \033[48;2;%sm\033[38;2;%sm  main ✓ \033[48;2;%sm\033[38;2;%sm  ls -la                         \033[0m\n' \
        "$acc" "$bg" "$(theme_rgb "${THEME[COLOR2]}")" "$bg" "$bg" "$fg"
    printf '  \033[48;2;%sm\033[38;2;%sm  echo "merhaba" \033[38;2;%sm# yorum \033[38;2;%smhata!            \033[0m\n\n' \
        "$bg" "$fg" "$(theme_rgb "${THEME[COLOR8]}")" "$(theme_rgb "${THEME[COLOR1]}")"
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
