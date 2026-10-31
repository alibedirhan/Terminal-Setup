#!/usr/bin/env bats
# Tema araçlara da uygulanır: bat/delta (BAT_THEME), fzf renkleri, btop teması

load '../helpers/common'

setup() {
    setup_fakesys
    SNIP="$HOME/.config/terminal-setup/zsh.d/65-theme-tools.zsh"
    BTOP_THEME="$HOME/.config/btop/themes/terminal-setup.theme"
    BTOP_CONF="$HOME/.config/btop/btop.conf"
}

@test "tema bat, delta, fzf ve btop'a uygulanır; değişince güncellenir" {
    ts install --components zsh,btop --theme nord
    grep -qx "export BAT_THEME='Nord'" "$SNIP"
    grep -q -- "--color=fg:#D8DEE9,bg:-1" "$SNIP"
    grep -qx 'theme\[main_bg\]="#2E3440"' "$BTOP_THEME"
    grep -qF "color_theme = \"$BTOP_THEME\"" "$BTOP_CONF"

    ts theme apply solarized
    grep -qx "export BAT_THEME='Solarized (dark)'" "$SNIP"
    ! grep -q "#2E3440" "$BTOP_THEME"
}

@test "görünümü sıfırlamak araç renklerini de geri alır, btop.conf arşivlenir" {
    ts install --components zsh,btop --theme dracula
    echo "update_ms = 1000" >> "$BTOP_CONF"
    run ts theme reset
    [ "$status" -eq 0 ]
    [ ! -e "$SNIP" ]
    [ ! -e "$BTOP_THEME" ]
    [ ! -e "$BTOP_CONF" ]
    grep -q "update_ms" "$HOME"/terminal-setup-kaldirilan-*/.config/btop/btop.conf
}

@test "kullanıcının kendi btop.conf dosyasına dokunulmaz" {
    mkdir -p "$HOME/.config/btop"
    echo 'color_theme = "Default"' > "$BTOP_CONF"
    cp "$BTOP_CONF" "$BATS_TEST_TMPDIR/conf-before"
    run ts install --components zsh,btop --theme nord
    [ "$status" -eq 0 ]
    [[ "$output" == *"btop ayarlarınız korunuyor"* ]]
    cmp "$BTOP_CONF" "$BATS_TEST_TMPDIR/conf-before"
    [ -f "$BTOP_THEME" ]
    ts uninstall
    cmp "$BTOP_CONF" "$BATS_TEST_TMPDIR/conf-before"
}

@test "zsh kurulu değilse araç renkleri yazılmaz" {
    ts install --components btop --theme nord
    [ ! -e "$SNIP" ]
    [ -f "$BTOP_THEME" ]
}

@test "bat karşılığı olmayan tema ansi kullanır" {
    ts install --components zsh --theme tokyo-night
    grep -qx "export BAT_THEME='ansi'" "$SNIP"
}

@test "style komutu: listeler, seçer, temayı yeniden uygular, auto ile döner" {
    ts install --components zsh --theme nord
    run ts style list
    [ "$status" -eq 0 ]
    [ "$(grep -c . <<< "$output")" -eq 6 ]
    [[ "$output" == *"* arctic"* ]]
    local snip="$HOME/.config/terminal-setup/zsh.d/65-theme-tools.zsh"
    grep -q -- "--border=left" "$snip"
    run ts style set neon
    [ "$status" -eq 0 ]
    grep -q -- "--border=double" "$snip"
    grep -qx "style=neon" "$HOME/.terminal-setup/settings"
    run ts style set auto
    grep -q -- "--border=left" "$snip"
    run ts style set olmayan
    [ "$status" -eq 2 ]
}
