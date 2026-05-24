#!/bin/bash

# ============================================================================
# Tokyo Night Theme
# v5.0.2 - Modern blue/purple theme
# ============================================================================

# GNOME Terminal
apply_tokyo_night_gnome() {
    local path=$1
    gsettings set "$path" visible-name "Tokyo Night" 2>/dev/null
    gsettings set "$path" background-color '#1A1B26' 2>/dev/null
    gsettings set "$path" foreground-color '#C0CAF5' 2>/dev/null
    gsettings set "$path" use-theme-colors false 2>/dev/null
    gsettings set "$path" palette "['#15161E', '#F7768E', '#9ECE6A', '#E0AF68', '#7AA2F7', '#BB9AF7', '#7DCFFF', '#A9B1D6', '#414868', '#F7768E', '#9ECE6A', '#E0AF68', '#7AA2F7', '#BB9AF7', '#7DCFFF', '#C0CAF5']" 2>/dev/null
    log_success "Tokyo Night teması uygulandı"
}

# Kitty
get_kitty_theme_tokyo_night() {
    cat << 'KITTY_EOF'
foreground #c0caf5
background #1a1b26
selection_foreground #c0caf5
selection_background #33467C
color0  #15161E
color1  #f7768e
color2  #9ece6a
color3  #e0af68
color4  #7aa2f7
color5  #bb9af7
color6  #7dcfff
color7  #a9b1d6
color8  #414868
color9  #f7768e
color10 #9ece6a
color11 #e0af68
color12 #7aa2f7
color13 #bb9af7
color14 #7dcfff
color15 #c0caf5
KITTY_EOF
}

# Alacritty
get_alacritty_theme_tokyo_night() {
    cat << 'ALACRITTY_EOF'
colors:
  primary:
    background: '#1a1b26'
    foreground: '#c0caf5'
  normal:
    black:   '#15161e'
    red:     '#f7768e'
    green:   '#9ece6a'
    yellow:  '#e0af68'
    blue:    '#7aa2f7'
    magenta: '#bb9af7'
    cyan:    '#7dcfff'
    white:   '#a9b1d6'
  bright:
    black:   '#414868'
    red:     '#f7768e'
    green:   '#9ece6a'
    yellow:  '#e0af68'
    blue:    '#7aa2f7'
    magenta: '#bb9af7'
    cyan:    '#7dcfff'
    white:   '#c0caf5'
ALACRITTY_EOF
}

# Tmux
get_tmux_theme_tokyo_night() {
    cat << 'TMUX_EOF'
set -g status-style bg='#1a1b26',fg='#c0caf5'
set -g window-status-current-style bg='#7aa2f7',fg='#1a1b26'
set -g pane-border-style fg='#414868'
set -g pane-active-border-style fg='#7aa2f7'
set -g message-style bg='#414868',fg='#c0caf5'
TMUX_EOF
}
