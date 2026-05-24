#!/bin/bash

# ============================================================================
# Dracula Theme
# v5.0.2 - Dark theme with purple/pink accents
# ============================================================================

# GNOME Terminal
apply_dracula_gnome() {
    local path=$1
    gsettings set "$path" visible-name "Dracula" 2>/dev/null
    gsettings set "$path" background-color '#282A36' 2>/dev/null
    gsettings set "$path" foreground-color '#F8F8F2' 2>/dev/null
    gsettings set "$path" use-theme-colors false 2>/dev/null
    gsettings set "$path" palette "['#000000', '#FF5555', '#50FA7B', '#F1FA8C', '#BD93F9', '#FF79C6', '#8BE9FD', '#BFBFBF', '#4D4D4D', '#FF6E67', '#5AF78E', '#F4F99D', '#CAA9FA', '#FF92D0', '#9AEDFE', '#E6E6E6']" 2>/dev/null
    log_success "Dracula teması uygulandı"
}

# Kitty
get_kitty_theme_dracula() {
    cat << 'KITTY_EOF'
foreground #f8f8f2
background #282a36
selection_foreground #ffffff
selection_background #44475a
color0  #21222c
color1  #ff5555
color2  #50fa7b
color3  #f1fa8c
color4  #bd93f9
color5  #ff79c6
color6  #8be9fd
color7  #f8f8f2
color8  #6272a4
color9  #ff6e6e
color10 #69ff94
color11 #ffffa5
color12 #d6acff
color13 #ff92df
color14 #a4ffff
color15 #ffffff
KITTY_EOF
}

# Alacritty
get_alacritty_theme_dracula() {
    cat << 'ALACRITTY_EOF'
colors:
  primary:
    background: '#282a36'
    foreground: '#f8f8f2'
  normal:
    black:   '#000000'
    red:     '#ff5555'
    green:   '#50fa7b'
    yellow:  '#f1fa8c'
    blue:    '#bd93f9'
    magenta: '#ff79c6'
    cyan:    '#8be9fd'
    white:   '#bfbfbf'
  bright:
    black:   '#4d4d4d'
    red:     '#ff6e67'
    green:   '#5af78e'
    yellow:  '#f4f99d'
    blue:    '#caa9fa'
    magenta: '#ff92d0'
    cyan:    '#9aedfe'
    white:   '#e6e6e6'
ALACRITTY_EOF
}

# Tmux
get_tmux_theme_dracula() {
    cat << 'TMUX_EOF'
set -g status-style bg='#282a36',fg='#f8f8f2'
set -g window-status-current-style bg='#bd93f9',fg='#282a36'
set -g pane-border-style fg='#6272a4'
set -g pane-active-border-style fg='#ff79c6'
set -g message-style bg='#44475a',fg='#f8f8f2'
TMUX_EOF
}
