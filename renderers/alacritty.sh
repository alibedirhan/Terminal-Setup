#!/usr/bin/env bash
# ============================================================================
# Renderer: Alacritty (0.13+ TOML biçimi)
# ============================================================================
# Renkler terminal-setup-theme.toml dosyasına yazılır ve alacritty.toml'un
# EN ÜSTÜNE bir "import" satırı eklenir. (TOML'da üst düzey anahtarlar
# tablolardan önce gelmelidir; 0.14+ bu biçimi uyarıyla kabul eder.)
# MesloLGS NF kuruluysa yazı tipi de aynı dosyaya eklenir.
# ============================================================================

renderer_register alacritty "Alacritty"

ALACRITTY_DIR="$HOME/.config/alacritty"

rend_alacritty_available() { has_cmd alacritty; }

rend_alacritty_apply() {
    local names=(black red green yellow blue magenta cyan white) i content
    content="# Terminal Setup: ${THEME[NAME]}
[colors.primary]
background = \"${THEME[BACKGROUND]}\"
foreground = \"${THEME[FOREGROUND]}\"

[colors.cursor]
cursor = \"${THEME[CURSOR]}\"
text = \"${THEME[BACKGROUND]}\"

[colors.selection]
background = \"${THEME[SELECTION_BG]}\"
text = \"${THEME[SELECTION_FG]}\"

[colors.normal]"
    for ((i = 0; i < 8; i++)); do
        content+=$'\n'"${names[i]} = \"${THEME[COLOR$i]}\""
    done
    content+=$'\n\n[colors.bright]'
    for ((i = 0; i < 8; i++)); do
        content+=$'\n'"${names[i]} = \"${THEME[COLOR$((i + 8))]}\""
    done
    if fc-list 2>/dev/null | grep -q "$TS_FONT_NAME"; then
        content+=$'\n\n'"[font]"$'\n'"size = $TS_FONT_SIZE"$'\n'"normal = { family = \"$TS_FONT_NAME\" }"
    fi
    act_write_file "$ALACRITTY_DIR/terminal-setup-theme.toml" "$content" &&
    act_rc_block "$ALACRITTY_DIR/alacritty.toml" theme \
        "import = [\"~/.config/alacritty/terminal-setup-theme.toml\"]" top
}
