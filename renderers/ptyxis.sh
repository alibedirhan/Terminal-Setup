#!/usr/bin/env bash
# ============================================================================
# Renderer: Ptyxis (Ubuntu 25.10 ve sonrasının varsayılan terminali)
# ============================================================================
# Ptyxis özel paletleri ~/.local/share/org.gnome.Ptyxis/palettes/ altındaki
# .palette dosyalarından okur. Tek bir "terminal-setup" paleti yazılır
# (tema değişince üzerine yazılır) ve varsayılan profile seçilir.
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

rend_ptyxis_apply() {
    local dir="$HOME/.local/share/org.gnome.Ptyxis/palettes" uuid content
    content="[Palette]
Name=Terminal Setup (${THEME[NAME]})

[Light]
$(_ptyxis_palette_section)

[Dark]
$(_ptyxis_palette_section)"
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
