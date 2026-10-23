#!/usr/bin/env bats
# Tema paletleri ve renderer'lar

load '../helpers/common'

setup() {
    setup_fakesys
    # Varsayılan olarak hiçbir terminal yok; testler gerekeni ekler
    rm -f "$FAKE_ROOT/sysbin/gnome-terminal"
    export PATH="${PATH//$REPO_ROOT\/tests\/helpers\/bin:/$BATS_TEST_TMPDIR/shims:}"
    mkdir -p "$BATS_TEST_TMPDIR/shims"
    for f in "$REPO_ROOT"/tests/helpers/bin/*; do
        [[ "$(basename "$f")" == gnome-terminal ]] && continue
        ln -s "$f" "$BATS_TEST_TMPDIR/shims/"
    done
    load_lib
    runner_prepare_light
}

add_terminal() {
    printf '#!/bin/sh\nexit 0\n' > "$BATS_TEST_TMPDIR/shims/$1"
    chmod +x "$BATS_TEST_TMPDIR/shims/$1"
}

@test "7 tema da geçerli (16 renk, zorunlu anahtarlar)" {
    local t n=0
    for t in $(theme_list); do
        theme_load "$t"
        n=$((n + 1))
    done
    [ "$n" -eq 7 ]
}

@test "olmayan tema reddedilir" {
    run theme_load olmayan
    [ "$status" -ne 0 ]
}

@test "renk dönüşümü ve dconf paleti" {
    [ "$(theme_rgb '#FF8000')" = "255;128;0" ]
    theme_load nord
    [[ "$(theme_palette_gvariant)" == "['#3B4252', "*"'#ECEFF4']" ]]
}

@test "önizleme tema adını ve renk bloklarını yazdırır" {
    run theme_preview dracula
    [ "$status" -eq 0 ]
    [[ "$output" == *Dracula* ]]
    [[ "$output" == *$'\033[48;2;'* ]]
}

@test "desteklenen terminal yoksa tema uygulanamaz" {
    run theme_apply nord
    [ "$status" -ne 0 ]
}

@test "kitty: renk dosyası ve include bloğu; geri alınca kitty.conf eski haline döner" {
    add_terminal kitty
    mkdir -p "$HOME/.config/kitty"
    echo "font_size 12" > "$HOME/.config/kitty/kitty.conf"
    theme_apply gruvbox
    grep -qx "background #282828" "$HOME/.config/kitty/terminal-setup-theme.conf"
    [ "$(grep -c '^color' "$HOME/.config/kitty/terminal-setup-theme.conf")" -eq 16 ]
    grep -qx "include terminal-setup-theme.conf" "$HOME/.config/kitty/kitty.conf"
    undo_component theme
    [ "$(cat "$HOME/.config/kitty/kitty.conf")" = "font_size 12" ]
    [ ! -e "$HOME/.config/kitty/terminal-setup-theme.conf" ]
}

@test "alacritty: import satırı dosyanın en üstüne eklenir" {
    add_terminal alacritty
    mkdir -p "$HOME/.config/alacritty"
    printf '[window]\nopacity = 0.9\n' > "$HOME/.config/alacritty/alacritty.toml"
    theme_apply tokyo-night
    [ "$(sed -n 2p "$HOME/.config/alacritty/alacritty.toml")" = 'import = ["~/.config/alacritty/terminal-setup-theme.toml"]' ]
    grep -q 'background = "#1A1B26"' "$HOME/.config/alacritty/terminal-setup-theme.toml"
    grep -q '^\[colors.bright\]' "$HOME/.config/alacritty/terminal-setup-theme.toml"
    undo_component theme
    [ "$(cat "$HOME/.config/alacritty/alacritty.toml")" = "$(printf '[window]\nopacity = 0.9')" ]
}

@test "ptyxis: palet dosyası ve profil anahtarı" {
    add_terminal ptyxis
    dconf write /org/gnome/Ptyxis/default-profile-uuid "'abc123'"
    theme_apply catppuccin
    local pal="$HOME/.local/share/org.gnome.Ptyxis/palettes/terminal-setup.palette"
    grep -qx "\[Dark\]" "$pal"
    grep -qx "Background=#1E1E2E" "$pal"
    [ "$(dconf read /org/gnome/Ptyxis/Profiles/abc123/palette)" = "'terminal-setup'" ]
    undo_component theme
    [ -z "$(dconf read /org/gnome/Ptyxis/Profiles/abc123/palette)" ]
    [ ! -e "$pal" ]
    [ ! -e "$HOME/.local" ]
}

@test "ptyxis: profil yoksa palet yazılır, uyarı verilir" {
    add_terminal ptyxis
    run theme_apply nord
    [ "$status" -eq 0 ]
    [[ "$output" == *"Ptyxis profili henüz yok"* ]]
}

@test "gnome: profil anahtarları yazılır ve geri alınır" {
    add_terminal gnome-terminal
    theme_apply one-dark
    local p="/org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/"
    [ "$(dconf read "${p}background-color")" = "'#282C34'" ]
    [ "$(dconf read "${p}use-theme-colors")" = "false" ]
    undo_component theme
    [ -z "$(ls "$FAKE_ROOT/dconf")" ]
}

@test "tema değiştirmek önceki değeri ezmez; geri alma ilk duruma döner" {
    add_terminal gnome-terminal
    local p="/org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/"
    dconf write "${p}background-color" "'#000000'"
    theme_apply nord
    theme_apply dracula
    [ "$(dconf read "${p}background-color")" = "'#282A36'" ]
    undo_component theme
    [ "$(dconf read "${p}background-color")" = "'#000000'" ]
}

@test "tmux renderer yalnızca tmux bileşeni varken çalışır" {
    add_terminal kitty
    theme_apply nord
    [ ! -e "$TS_CONFIG_DIR/tmux-theme.conf" ]
    mkdir -p "$TS_CONFIG_DIR" && touch "$TS_CONFIG_DIR/tmux.conf"
    theme_apply nord
    grep -q "window-status-current-style bg='#88C0D0'" "$TS_CONFIG_DIR/tmux-theme.conf"
}
