#!/usr/bin/env bats
# Eksik seçenek değerleri yanlışlıkla varsayılan kurulumu başlatmamalı.

load '../helpers/common'

setup() {
    setup_fakesys
}

@test "kurulum seçenekleri eksik değerle hiçbir şey kurmadan reddedilir" {
    local option
    for option in --profile --theme --components; do
        run ts install "$option"
        [ "$status" -eq 2 ]
        [ ! -e "$HOME/.terminal-setup/ledger" ]
        [ ! -e "$FAKE_ROOT/apt.log" ]
    done
}

@test "sonraki seçenek değer yerine kabul edilmez" {
    run ts install --components --theme nord
    [ "$status" -eq 2 ]
    [ ! -e "$HOME/.terminal-setup/ledger" ]
    [ ! -e "$FAKE_ROOT/apt.log" ]
}

@test "dil seçeneği eksik değerle reddedilir" {
    run ts --lang
    [ "$status" -eq 2 ]
    [ ! -e "$HOME/.terminal-setup/ledger" ]
}
