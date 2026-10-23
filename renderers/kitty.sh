#!/usr/bin/env bash
# ============================================================================
# Renderer: Kitty
# ============================================================================
# Renkler ayrı bir dosyaya yazılır; kitty.conf'a yalnızca bir "include"
# satırı içeren yönetilen blok eklenir.
# ============================================================================

renderer_register kitty "Kitty"

KITTY_DIR="$HOME/.config/kitty"

rend_kitty_available() { has_cmd kitty; }

rend_kitty_apply() {
    local i content
    content="# Terminal Setup: ${THEME[NAME]}
foreground ${THEME[FOREGROUND]}
background ${THEME[BACKGROUND]}
cursor ${THEME[CURSOR]}
selection_foreground ${THEME[SELECTION_FG]}
selection_background ${THEME[SELECTION_BG]}"
    for ((i = 0; i < 16; i++)); do
        content+=$'\n'"color$i ${THEME[COLOR$i]}"
    done
    act_write_file "$KITTY_DIR/terminal-setup-theme.conf" "$content" &&
    act_rc_block "$KITTY_DIR/kitty.conf" theme "include terminal-setup-theme.conf"
}

rend_kitty_font() {
    act_write_file "$KITTY_DIR/terminal-setup-font.conf" \
        "font_family $TS_FONT_NAME"$'\n'"font_size $TS_FONT_SIZE" &&
    act_rc_block "$KITTY_DIR/kitty.conf" font "include terminal-setup-font.conf"
}
