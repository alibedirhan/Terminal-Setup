#!/bin/bash

# ============================================================================
# Solarized Dark Theme
# v5.0.2 - Classic precision colors
# ============================================================================

# GNOME Terminal
apply_solarized_gnome() {
    local path=$1
    gsettings set "$path" visible-name "Solarized Dark" 2>/dev/null
    gsettings set "$path" background-color '#002B36' 2>/dev/null
    gsettings set "$path" foreground-color '#839496' 2>/dev/null
    gsettings set "$path" use-theme-colors false 2>/dev/null
    gsettings set "$path" palette "['#073642', '#DC322F', '#859900', '#B58900', '#268BD2', '#D33682', '#2AA198', '#EEE8D5', '#002B36', '#CB4B16', '#586E75', '#657B83', '#839496', '#6C71C4', '#93A1A1', '#FDF6E3']" 2>/dev/null
    log_success "Solarized Dark teması uygulandı"
}

# Kitty
get_kitty_theme_solarized() {
    cat << 'KITTY_EOF'
foreground #839496
background #002b36
selection_foreground #93a1a1
selection_background #073642
color0  #073642
color1  #dc322f
color2  #859900
color3  #b58900
color4  #268bd2
color5  #d33682
color6  #2aa198
color7  #eee8d5
color8  #002b36
color9  #cb4b16
color10 #586e75
color11 #657b83
color12 #839496
color13 #6c71c4
color14 #93a1a1
color15 #fdf6e3
KITTY_EOF
}

# Alacritty
get_alacritty_theme_solarized() {
    cat << 'ALACRITTY_EOF'
colors:
  primary:
    background: '#002b36'
    foreground: '#839496'
  normal:
    black:   '#073642'
    red:     '#dc322f'
    green:   '#859900'
    yellow:  '#b58900'
    blue:    '#268bd2'
    magenta: '#d33682'
    cyan:    '#2aa198'
    white:   '#eee8d5'
  bright:
    black:   '#002b36'
    red:     '#cb4b16'
    green:   '#586e75'
    yellow:  '#657b83'
    blue:    '#839496'
    magenta: '#6c71c4'
    cyan:    '#93a1a1'
    white:   '#fdf6e3'
ALACRITTY_EOF
}

# Tmux
get_tmux_theme_solarized() {
    cat << 'TMUX_EOF'
set -g status-style bg='#002b36',fg='#839496'
set -g window-status-current-style bg='#268bd2',fg='#fdf6e3'
set -g pane-border-style fg='#073642'
set -g pane-active-border-style fg='#268bd2'
set -g message-style bg='#073642',fg='#839496'
TMUX_EOF
}
