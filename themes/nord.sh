#!/bin/bash

# ============================================================================
# Nord Theme
# v5.0.2 - Blue/grey theme, easy on eyes
# ============================================================================

# GNOME Terminal
apply_nord_gnome() {
    local path=$1
    gsettings set "$path" visible-name "Nord" 2>/dev/null
    gsettings set "$path" background-color '#2E3440' 2>/dev/null
    gsettings set "$path" foreground-color '#D8DEE9' 2>/dev/null
    gsettings set "$path" use-theme-colors false 2>/dev/null
    gsettings set "$path" palette "['#3B4252', '#BF616A', '#A3BE8C', '#EBCB8B', '#81A1C1', '#B48EAD', '#88C0D0', '#E5E9F0', '#4C566A', '#BF616A', '#A3BE8C', '#EBCB8B', '#81A1C1', '#B48EAD', '#8FBCBB', '#ECEFF4']" 2>/dev/null
    log_success "Nord teması uygulandı"
}

# Kitty
get_kitty_theme_nord() {
    cat << 'KITTY_EOF'
foreground #d8dee9
background #2e3440
selection_foreground #000000
selection_background #fffacd
color0  #3b4252
color1  #bf616a
color2  #a3be8c
color3  #ebcb8b
color4  #81a1c1
color5  #b48ead
color6  #88c0d0
color7  #e5e9f0
color8  #4c566a
color9  #bf616a
color10 #a3be8c
color11 #ebcb8b
color12 #81a1c1
color13 #b48ead
color14 #8fbcbb
color15 #eceff4
KITTY_EOF
}

# Alacritty
get_alacritty_theme_nord() {
    cat << 'ALACRITTY_EOF'
colors:
  primary:
    background: '#2e3440'
    foreground: '#d8dee9'
  normal:
    black:   '#3b4252'
    red:     '#bf616a'
    green:   '#a3be8c'
    yellow:  '#ebcb8b'
    blue:    '#81a1c1'
    magenta: '#b48ead'
    cyan:    '#88c0d0'
    white:   '#e5e9f0'
  bright:
    black:   '#4c566a'
    red:     '#bf616a'
    green:   '#a3be8c'
    yellow:  '#ebcb8b'
    blue:    '#81a1c1'
    magenta: '#b48ead'
    cyan:    '#8fbcbb'
    white:   '#eceff4'
ALACRITTY_EOF
}

# Tmux
get_tmux_theme_nord() {
    cat << 'TMUX_EOF'
set -g status-style bg='#2e3440',fg='#d8dee9'
set -g window-status-current-style bg='#88c0d0',fg='#2e3440'
set -g pane-border-style fg='#4c566a'
set -g pane-active-border-style fg='#88c0d0'
set -g message-style bg='#3b4252',fg='#d8dee9'
TMUX_EOF
}
