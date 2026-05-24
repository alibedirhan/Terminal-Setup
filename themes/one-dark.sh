#!/bin/bash

# ============================================================================
# One Dark Theme
# v5.0.2 - Atom's iconic dark theme
# ============================================================================

# GNOME Terminal
apply_one_dark_gnome() {
    local path=$1
    gsettings set "$path" visible-name "One Dark" 2>/dev/null
    gsettings set "$path" background-color '#282C34' 2>/dev/null
    gsettings set "$path" foreground-color '#ABB2BF' 2>/dev/null
    gsettings set "$path" use-theme-colors false 2>/dev/null
    gsettings set "$path" palette "['#282C34', '#E06C75', '#98C379', '#E5C07B', '#61AFEF', '#C678DD', '#56B6C2', '#ABB2BF', '#5C6370', '#E06C75', '#98C379', '#E5C07B', '#61AFEF', '#C678DD', '#56B6C2', '#FFFFFF']" 2>/dev/null
    log_success "One Dark teması uygulandı"
}

# Kitty
get_kitty_theme_one_dark() {
    cat << 'KITTY_EOF'
foreground #abb2bf
background #282c34
selection_foreground #282c34
selection_background #abb2bf
color0  #282c34
color1  #e06c75
color2  #98c379
color3  #e5c07b
color4  #61afef
color5  #c678dd
color6  #56b6c2
color7  #abb2bf
color8  #5c6370
color9  #e06c75
color10 #98c379
color11 #e5c07b
color12 #61afef
color13 #c678dd
color14 #56b6c2
color15 #ffffff
KITTY_EOF
}

# Alacritty
get_alacritty_theme_one_dark() {
    cat << 'ALACRITTY_EOF'
colors:
  primary:
    background: '#282c34'
    foreground: '#abb2bf'
  normal:
    black:   '#282c34'
    red:     '#e06c75'
    green:   '#98c379'
    yellow:  '#e5c07b'
    blue:    '#61afef'
    magenta: '#c678dd'
    cyan:    '#56b6c2'
    white:   '#abb2bf'
  bright:
    black:   '#5c6370'
    red:     '#e06c75'
    green:   '#98c379'
    yellow:  '#e5c07b'
    blue:    '#61afef'
    magenta: '#c678dd'
    cyan:    '#56b6c2'
    white:   '#ffffff'
ALACRITTY_EOF
}

# Tmux
get_tmux_theme_one_dark() {
    cat << 'TMUX_EOF'
set -g status-style bg='#282c34',fg='#abb2bf'
set -g window-status-current-style bg='#61afef',fg='#282c34'
set -g pane-border-style fg='#5c6370'
set -g pane-active-border-style fg='#61afef'
set -g message-style bg='#3e4451',fg='#abb2bf'
TMUX_EOF
}
