#!/usr/bin/env bash
# ============================================================================
# Renderer: WezTerm
# ============================================================================
# Renkler WezTerm'in renk şeması dizinine "Terminal Setup" adlı şema olarak
# yazılır. WezTerm ayarı Lua koddur, içine satır eklenmez: ayar dosyası
# yoksa bu şemayı ve yazı tipini seçen küçük bir wezterm.lua oluşturulur
# (kullanıcı verisi sayılır, kaldırırken arşive taşınır); varsa kullanıcıya
# hangi satırı ekleyeceği söylenir.
# ============================================================================

renderer_register wezterm "WezTerm"

WEZTERM_DIR="$HOME/.config/wezterm"

rend_wezterm_available() { has_cmd wezterm; }

# Toml dizisi: _wezterm_colors 0 -> REPLY = ["#..", ... 8 renk]
_wezterm_colors() {
    local i
    REPLY="["
    for ((i = $1; i < $1 + 8; i++)); do
        REPLY+="\"${THEME[COLOR$i]}\""
        ((i < $1 + 7)) && REPLY+=", "
    done
    REPLY+="]"
}

rend_wezterm_apply() {
    local ansi brights
    _wezterm_colors 0; ansi="$REPLY"
    _wezterm_colors 8; brights="$REPLY"
    act_write_file "$WEZTERM_DIR/colors/terminal-setup.toml" "# Terminal Setup: ${THEME[NAME]}
[colors]
foreground = \"${THEME[FOREGROUND]}\"
background = \"${THEME[BACKGROUND]}\"
cursor_bg = \"${THEME[CURSOR]}\"
cursor_border = \"${THEME[CURSOR]}\"
cursor_fg = \"${THEME[BACKGROUND]}\"
selection_bg = \"${THEME[SELECTION_BG]}\"
selection_fg = \"${THEME[SELECTION_FG]}\"
ansi = $ansi
brights = $brights

[metadata]
name = \"Terminal Setup\"" || return 1
    _wezterm_config
}

rend_wezterm_font() { _wezterm_config; }

_wezterm_config() {
    if [[ -e "$HOME/.wezterm.lua" ]] || { [[ -e "$WEZTERM_DIR/wezterm.lua" ]] && ! ledger_has userdata "$WEZTERM_DIR/wezterm.lua"; }; then
        log_info "WezTerm ayarlarınız korunuyor; renkler için şunu ekleyin: %s" "config.color_scheme = 'Terminal Setup'"
        return 0
    fi
    act_seed_file "$WEZTERM_DIR/wezterm.lua" "-- Terminal Setup oluşturdu; kendi ayarlarınızı ekleyebilirsiniz.
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.color_scheme = 'Terminal Setup'
config.font = wezterm.font '$TS_FONT_NAME'
config.font_size = $TS_FONT_SIZE
return config"
}
