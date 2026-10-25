#!/usr/bin/env bash
# Bileşen: tmux — terminal çoğaltıcı. Ayarlar ~/.config/terminal-setup/
# altında durur; ~/.tmux.conf'a yalnızca bir "source-file" bloğu eklenir.

component_register tmux "tmux" extra "Terminal çoğaltıcı, temalı durum çubuğu (önek: Ctrl+a)" ""

component_tip tmux "tmux" "Oturum aç (önek: Ctrl+a)"
component_tip tmux "Ctrl+a c" "Yeni pencere"
component_tip tmux "Ctrl+a %" "Pencereyi dikey böl"
component_tip tmux "Ctrl+a d" "Oturumdan ayrıl (arka planda sürer)"

_tmux_base_conf() {
    cat <<CONF
# Terminal Setup — tmux ayarları (yönetilir, kaldırmada silinir)
unbind C-b
set -g prefix C-a
bind C-a send-prefix
set -g mouse on
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
set -g base-index 1
setw -g pane-base-index 1
set -sg escape-time 10
set -g history-limit 10000
set -g renumber-windows on
set -g status-left-length 40
set -g status-left "#[bold] #S "
set -g status-right "#[bold] %d.%m.%Y %H:%M "
set -g status-justify centre
setw -g window-status-format " #I:#W "
setw -g window-status-current-format " #I:#W "
source-file -q "$TS_CONFIG_DIR/tmux-theme.conf"
CONF
}

comp_tmux_install() {
    local theme
    if [[ -f "$HOME/.tmux.conf" ]] && ! rc_has_block "$HOME/.tmux.conf" tmux; then
        log_info "Mevcut ~/.tmux.conf korunur; sonuna bir yükleme bloğu eklenir."
        ui_confirm "tmux ayarları eklensin mi?" e || return 1
    fi
    act_pkg tmux || return 1
    act_write_file "$TS_CONFIG_DIR/tmux.conf" "$(_tmux_base_conf)" || return 1
    act_rc_block "$HOME/.tmux.conf" tmux "source-file \"$TS_CONFIG_DIR/tmux.conf\"" || return 1
    # Uygulanmış bir tema varsa durum çubuğunu ona göre renklendir
    theme=$(settings_get theme)
    if [[ -n "$theme" ]] && theme_load "$theme"; then
        rend_tmux_apply
    fi
}

comp_tmux_verify() {
    has_cmd tmux && rc_has_block "$HOME/.tmux.conf" tmux
}
