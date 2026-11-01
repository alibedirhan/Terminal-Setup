#!/usr/bin/env bash
# ============================================================================
# Renderer: tmux
# ============================================================================
# tmux bileşeni kuruluysa durum çubuğu temanın renk rollerinden ve
# kişilikten üretilir. ~/.config/terminal-setup/tmux.conf bu dosyayı
# "source-file -q" ile okur; temel ayarlardaki varsayılanları ezer.
#
# Kişilikten gelenler:
#   SEGMENTS     pencere etiketlerinin biçimi, Starship prompt'uyla aynı dil
#                (plain dolgu, minimal yalnızca ad, powerline ok, pills hap,
#                brackets [köşeli], arrows ▸)
#   SEPARATOR    durum çubuğunun sağındaki ayırıcı
#   DATE_FORMAT  saat ve tarih
#   BORDER       bölme çizgileri (style_border_for tmux)
# Nerd Font karakterleri dosyaya tmux'un kendi kaçışıyla (\ue0b0) yazılır;
# tmux 3.0'dan beri çift tırnak içinde bunları kendisi çevirir.
# ============================================================================

renderer_register tmux "tmux" tool

TMUX_THEME_FILE="$TS_CONFIG_DIR/tmux-theme.conf"

rend_tmux_available() {
    [[ -f "$TS_CONFIG_DIR/tmux.conf" ]]
}

rend_tmux_apply() {
    tmux_theme_conf
    act_write_file "$TMUX_THEME_FILE" "$REPLY"
}

# tmux çift tırnaklı dizgesi için kaçır: \ " $ # -> REPLY
# (# biçim karakteridir; metindeki # iki kez yazılır)
_tmux_quote() {
    REPLY="${1//\\/\\\\}"
    REPLY="${REPLY//\"/\\\"}"
    REPLY="${REPLY//\$/\\\$}"
    REPLY="${REPLY//\#/##}"
}

# Pencere etiketleri: _tmux_window_formats -> REPLY="geçerli<TAB>diğer"
_tmux_window_formats() {
    local a="${ROLE[accent]}" bg="${ROLE[bg]}" m="${ROLE[muted]}" cur other
    case "${STYLE[SEGMENTS]}" in
        minimal)
            cur="#[fg=$a,bold] #W #[default]"
            other="#[fg=$m] #W #[default]" ;;
        powerline)
            cur="#[fg=$bg,bg=$a]\\ue0b0#[fg=$bg,bg=$a,bold] #I #W #[fg=$a,bg=$bg,nobold]\\ue0b0#[default]"
            other="#[fg=$m] #I #W #[default]" ;;
        pills)
            cur="#[fg=$a,bg=$bg]\\ue0b6#[fg=$bg,bg=$a,bold]#I #W#[fg=$a,bg=$bg,nobold]\\ue0b4#[default]"
            other="#[fg=$m] #I #W #[default]" ;;
        brackets)
            cur="#[fg=$a,bold][#I:#W]#[default]"
            other="#[fg=$m] #I:#W #[default]" ;;
        arrows)
            _tmux_quote "${STYLE[SEPARATOR]}"
            cur="#[fg=$a,bold]$REPLY #I:#W#[default]"
            other="#[fg=$m]  #I:#W#[default]" ;;
        *)
            cur="#[fg=$bg,bg=$a,bold] #I:#W #[default]"
            other="#[fg=$m] #I:#W #[default]" ;;
    esac
    REPLY="$cur"$'\t'"$other"
}

# tmux-theme.conf içeriği -> REPLY (tema ve kişilik yüklü olmalı)
tmux_theme_conf() {
    local cur other sep date lines
    _tmux_window_formats
    cur="${REPLY%%$'\t'*}" other="${REPLY#*$'\t'}"
    _tmux_quote "${STYLE[SEPARATOR]}"; sep="$REPLY"
    # DATE_FORMAT style_load'da denetlenir: yalnızca % harf rakam boşluk . : / -
    date="${STYLE[DATE_FORMAT]#+}"
    style_border_for tmux; lines="$REPLY"
    style_file_header
    REPLY="$REPLY
set -g status-style \"bg=${ROLE[bg]},fg=${ROLE[fg]}\"
set -g status-left \"#[fg=${ROLE[accent2]},bold] #S #[default]\"
set -g status-right \"#[fg=${ROLE[muted]}]$sep #[fg=${ROLE[fg]}]$date \"
set -g window-status-style default
set -g window-status-current-style default
setw -g window-status-format \"$other\"
setw -g window-status-current-format \"$cur\"
set -g pane-border-lines $lines
set -g pane-border-style \"fg=${ROLE[border]}\"
set -g pane-active-border-style \"fg=${ROLE[accent]}\"
set -g message-style \"bg=${ROLE[sel]},fg=${ROLE[sel_fg]}\"
set -g mode-style \"bg=${ROLE[sel]},fg=${ROLE[sel_fg]}\""
}
