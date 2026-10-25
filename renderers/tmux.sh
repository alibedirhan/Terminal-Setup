#!/usr/bin/env bash
# ============================================================================
# Renderer: tmux
# ============================================================================
# tmux bileşeni kuruluysa durum çubuğu renkleri temaya göre üretilir.
# ~/.config/terminal-setup/tmux.conf bu dosyayı "source-file -q" ile okur.
# ============================================================================

renderer_register tmux "tmux" tool

rend_tmux_available() {
    [[ -f "$TS_CONFIG_DIR/tmux.conf" ]]
}

rend_tmux_apply() {
    act_write_file "$TS_CONFIG_DIR/tmux-theme.conf" "# Terminal Setup: ${THEME[NAME]}
set -g status-style bg='${THEME[BACKGROUND]}',fg='${THEME[FOREGROUND]}'
set -g window-status-current-style bg='${THEME[ACCENT]}',fg='${THEME[BACKGROUND]}',bold
set -g pane-border-style fg='${THEME[BORDER]}'
set -g pane-active-border-style fg='${THEME[ACCENT]}'
set -g message-style bg='${THEME[BORDER]}',fg='${THEME[FOREGROUND]}'
set -g mode-style bg='${THEME[SELECTION_BG]}',fg='${THEME[SELECTION_FG]}'"
}
