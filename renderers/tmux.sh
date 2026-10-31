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
set -g status-style bg='${ROLE[bg]}',fg='${ROLE[fg]}'
set -g window-status-style fg='${ROLE[muted]}'
set -g window-status-current-style bg='${ROLE[accent]}',fg='${ROLE[bg]}',bold
set -g pane-border-style fg='${ROLE[border]}'
set -g pane-active-border-style fg='${ROLE[accent]}'
set -g message-style bg='${ROLE[sel]}',fg='${ROLE[sel_fg]}'
set -g mode-style bg='${ROLE[sel]}',fg='${ROLE[sel_fg]}'"
}
