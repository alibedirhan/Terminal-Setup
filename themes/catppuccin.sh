#!/bin/bash

# ============================================================================
# Catppuccin Theme
# v5.0.2 - Pastel colors (Mocha variant)
# ============================================================================

# GNOME Terminal
apply_catppuccin_gnome() {
    local path=$1
    gsettings set "$path" visible-name "Catppuccin Mocha" 2>/dev/null
    gsettings set "$path" background-color '#1E1E2E' 2>/dev/null
    gsettings set "$path" foreground-color '#CDD6F4' 2>/dev/null
    gsettings set "$path" use-theme-colors false 2>/dev/null
    gsettings set "$path" palette "['#45475A', '#F38BA8', '#A6E3A1', '#F9E2AF', '#89B4FA', '#F5C2E7', '#94E2D5', '#BAC2DE', '#585B70', '#F38BA8', '#A6E3A1', '#F9E2AF', '#89B4FA', '#F5C2E7', '#94E2D5', '#A6ADC8']" 2>/dev/null
    log_success "Catppuccin teması uygulandı"
}

# Kitty
get_kitty_theme_catppuccin() {
    cat << 'KITTY_EOF'
foreground #cdd6f4
background #1e1e2e
selection_foreground #1e1e2e
selection_background #f5e0dc
color0  #45475a
color1  #f38ba8
color2  #a6e3a1
color3  #f9e2af
color4  #89b4fa
color5  #f5c2e7
color6  #94e2d5
color7  #bac2de
color8  #585b70
color9  #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8
KITTY_EOF
}

# Alacritty
get_alacritty_theme_catppuccin() {
    cat << 'ALACRITTY_EOF'
colors:
  primary:
    background: '#1e1e2e'
    foreground: '#cdd6f4'
  normal:
    black:   '#45475a'
    red:     '#f38ba8'
    green:   '#a6e3a1'
    yellow:  '#f9e2af'
    blue:    '#89b4fa'
    magenta: '#f5c2e7'
    cyan:    '#94e2d5'
    white:   '#bac2de'
  bright:
    black:   '#585b70'
    red:     '#f38ba8'
    green:   '#a6e3a1'
    yellow:  '#f9e2af'
    blue:    '#89b4fa'
    magenta: '#f5c2e7'
    cyan:    '#94e2d5'
    white:   '#a6adc8'
ALACRITTY_EOF
}

# Tmux
get_tmux_theme_catppuccin() {
    cat << 'TMUX_EOF'
set -g status-style bg='#1e1e2e',fg='#cdd6f4'
set -g window-status-current-style bg='#89b4fa',fg='#1e1e2e'
set -g pane-border-style fg='#45475a'
set -g pane-active-border-style fg='#89b4fa'
set -g message-style bg='#45475a',fg='#cdd6f4'
TMUX_EOF
}
