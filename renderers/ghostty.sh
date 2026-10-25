#!/usr/bin/env bash
# ============================================================================
# Renderer: Ghostty
# ============================================================================
# Renkler Ghostty'nin tema dizinine "terminal-setup" adlı bir tema olarak
# yazılır; config dosyasına yalnızca "theme = terminal-setup" içeren
# yönetilen blok eklenir (sonda olduğu için önceki theme satırını ezer).
# ============================================================================

renderer_register ghostty "Ghostty"

GHOSTTY_DIR="$HOME/.config/ghostty"

rend_ghostty_available() { has_cmd ghostty; }

rend_ghostty_apply() {
    local i content
    content="# Terminal Setup: ${THEME[NAME]}
background = ${THEME[BACKGROUND]}
foreground = ${THEME[FOREGROUND]}
cursor-color = ${THEME[CURSOR]}
selection-background = ${THEME[SELECTION_BG]}
selection-foreground = ${THEME[SELECTION_FG]}"
    for ((i = 0; i < 16; i++)); do
        content+=$'\n'"palette = $i=${THEME[COLOR$i]}"
    done
    act_write_file "$GHOSTTY_DIR/themes/terminal-setup" "$content" &&
    act_rc_block "$GHOSTTY_DIR/config" theme "theme = terminal-setup"
}

rend_ghostty_font() {
    act_rc_block "$GHOSTTY_DIR/config" font "font-family = \"$TS_FONT_NAME\"
font-size = $TS_FONT_SIZE"
}
