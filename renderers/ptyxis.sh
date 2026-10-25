#!/usr/bin/env bash
# ============================================================================
# Renderer: Ptyxis (Ubuntu 25.10 ve sonrasının varsayılan terminali)
# ============================================================================
# Ptyxis özel paletleri ~/.local/share/org.gnome.Ptyxis/palettes/ altındaki
# .palette dosyalarından okur. Tek bir "terminal-setup" paleti yazılır
# (tema değişince üzerine yazılır) ve varsayılan profile seçilir.
# Paletin açık ve koyu bölümleri vardır; Ptyxis sistemin tonunu izler. Tema
# açık/koyu bir eşe sahipse (PAIR) iki bölüm farklı yazılır, böylece terminal
# sistem açık temaya geçince kendiliğinden açık renklere döner.
# ============================================================================

renderer_register ptyxis "Ptyxis"

PTYXIS_PALETTE_ID="terminal-setup"

rend_ptyxis_available() {
    has_cmd ptyxis && has_cmd dconf
}

_ptyxis_palette_section() {
    local i
    echo "Foreground=${THEME[FOREGROUND]}"
    echo "Background=${THEME[BACKGROUND]}"
    for ((i = 0; i < 16; i++)); do
        echo "Color$i=${THEME[COLOR$i]}"
    done
}

# Açık ve koyu bölümlerin içeriği -> PTYXIS_LIGHT, PTYXIS_DARK
_ptyxis_sections() {
    local own pair="${THEME[PAIR]:-}" key
    local -A saved=()
    own=$(_ptyxis_palette_section)
    PTYXIS_LIGHT="$own" PTYXIS_DARK="$own"
    [[ -n "$pair" ]] && theme_exists "$pair" || return 0
    for key in "${!THEME[@]}"; do saved[$key]="${THEME[$key]}"; done
    theme_load "$pair" > /dev/null || return 0
    if [[ "${saved[VARIANT]:-dark}" == light ]]; then
        PTYXIS_DARK=$(_ptyxis_palette_section)
    else
        PTYXIS_LIGHT=$(_ptyxis_palette_section)
    fi
    THEME=()
    for key in "${!saved[@]}"; do THEME[$key]="${saved[$key]}"; done
}

rend_ptyxis_apply() {
    local dir="$HOME/.local/share/org.gnome.Ptyxis/palettes" uuid content
    _ptyxis_sections
    content="[Palette]
Name=Terminal Setup (${THEME[NAME]})

[Light]
$PTYXIS_LIGHT

[Dark]
$PTYXIS_DARK"
    act_write_file "$dir/$PTYXIS_PALETTE_ID.palette" "$content" || return 1

    uuid=$(dconf read /org/gnome/Ptyxis/default-profile-uuid 2>/dev/null | tr -d "'")
    if [[ -z "$uuid" ]]; then
        log_warn "Ptyxis profili henüz yok. Ptyxis'i bir kez açın, sonra temayı yeniden uygulayın;"
        log_warn "ya da Tercihler > Profil > Renkler bölümünden 'Terminal Setup' paletini seçin."
        return 0
    fi
    act_dconf_key "/org/gnome/Ptyxis/Profiles/$uuid/palette" "'$PTYXIS_PALETTE_ID'"
}

rend_ptyxis_font() {
    act_dconf_key /org/gnome/Ptyxis/use-system-font "false" &&
    act_dconf_key /org/gnome/Ptyxis/font-name "'$TS_FONT_NAME $TS_FONT_SIZE'"
}
