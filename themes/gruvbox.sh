#!/bin/bash

# ============================================================================
# Gruvbox Theme
# v5.0.2 - Retro warm tones
# ============================================================================

# GNOME Terminal
apply_gruvbox_gnome() {
    local path=$1
    gsettings set "$path" visible-name "Gruvbox Dark" 2>/dev/null
    gsettings set "$path" background-color '#282828' 2>/dev/null
    gsettings set "$path" foreground-color '#EBDBB2' 2>/dev/null
    gsettings set "$path" use-theme-colors false 2>/dev/null
    gsettings set "$path" palette "['#282828', '#CC241D', '#98971A', '#D79921', '#458588', '#B16286', '#689D6A', '#A89984', '#928374', '#FB4934', '#B8BB26', '#FABD2F', '#83A598', '#D3869B', '#8EC07C', '#EBDBB2']" 2>/dev/null
    log_success "Gruvbox teması uygulandı"
}

# Kitty
get_kitty_theme_gruvbox() {
    cat << 'KITTY_EOF'
foreground #ebdbb2
background #282828
selection_foreground #928374
selection_background #ebdbb2
color0  #282828
color1  #cc241d
color2  #98971a
color3  #d79921
color4  #458588
color5  #b16286
color6  #689d6a
color7  #a89984
color8  #928374
color9  #fb4934
color10 #b8bb26
color11 #fabd2f
color12 #83a598
color13 #d3869b
color14 #8ec07c
color15 #ebdbb2
KITTY_EOF
}

# Alacritty
get_alacritty_theme_gruvbox() {
    cat << 'ALACRITTY_EOF'
colors:
  primary:
    background: '#282828'
    foreground: '#ebdbb2'
  normal:
    black:   '#282828'
    red:     '#cc241d'
    green:   '#98971a'
    yellow:  '#d79921'
    blue:    '#458588'
    magenta: '#b16286'
    cyan:    '#689d6a'
    white:   '#a89984'
  bright:
    black:   '#928374'
    red:     '#fb4934'
    green:   '#b8bb26'
    yellow:  '#fabd2f'
    blue:    '#83a598'
    magenta: '#d3869b'
    cyan:    '#8ec07c'
    white:   '#ebdbb2'
ALACRITTY_EOF
}

# Tmux
get_tmux_theme_gruvbox() {
    cat << 'TMUX_EOF'
set -g status-style bg='#282828',fg='#ebdbb2'
set -g window-status-current-style bg='#fabd2f',fg='#282828'
set -g pane-border-style fg='#504945'
set -g pane-active-border-style fg='#fabd2f'
set -g message-style bg='#504945',fg='#ebdbb2'
TMUX_EOF
}
