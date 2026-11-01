#!/usr/bin/env bats
# Kısayollar ekranı, açılış ipucu, zsh açılış süresi teşhisi ve fzf-tab

load '../helpers/common'

setup() {
    setup_fakesys
    TIPS="$HOME/.config/terminal-setup/tips.txt"
    SNIP="$HOME/.config/terminal-setup/zsh.d/95-tips.zsh"
}

@test "kısayollar yalnızca kurulu araçlar için gösterilir" {
    run ts tips
    [[ "$output" == *"kısayolu olan bir araç kurulu değil"* ]]
    ts install --components fzf
    run ts tips
    [ "$status" -eq 0 ]
    [[ "$output" == *"Ctrl+T"*"Dosya seçip komut satırına ekle"* ]]
    [[ "$output" != *"Git arayüzünü aç"* ]]
    TS_LANG=en run ts tips
    [[ "$output" == *"Pick a file and insert it into the command line"* ]]
}

@test "açılış ipucu açılır, kurulumla güncellenir, kapanınca iz bırakmaz" {
    ts install --components zsh,fzf
    ts tips --shell on
    grep -q "Ctrl+T — Dosya seçip komut satırına ekle" "$TIPS"
    grep -q "add-zsh-hook precmd _ts_tip" "$SNIP"
    ! grep -q "lg — " "$TIPS" || false

    ts install --components lazygit
    grep -q "lg — Git arayüzünü aç" "$TIPS"

    ts tips --shell off
    [ ! -e "$TIPS" ]
    [ ! -e "$SNIP" ]
}

@test "açılış ipucu açıkken kaldırma kalıntı bırakmaz" {
    ts install --components zsh,fzf
    ts tips --shell on
    run ts uninstall
    [[ "$output" == *"Sonuç: kalıntı yok."* ]]
    [ -z "$(cd "$HOME" && find . -mindepth 1 | grep -v '^./terminal-setup-kaldirilan-')" ]
}

@test "açılış ipucu zsh bileşeni olmadan açılmaz" {
    run ts tips --shell on
    [ "$status" -ne 0 ]
    [[ "$output" == *"Zsh bileşeni kurulu olmalı"* ]]
}

@test "zsh parçası zsh sözdizimine uygun" {
    command -v zsh >/dev/null || PATH=/usr/bin:/bin command -v zsh >/dev/null || skip "gerçek zsh yok"
    ts install --components zsh,fzf
    ts tips --shell on
    PATH=/usr/bin:/bin zsh -n "$SNIP"
}

@test "zsh yavaş açılırsa doctor en yavaş parçayı söyler" {
    ts install --components zsh
    printf '#!/bin/sh\nsleep 0.35\n[ -n "${TS_ZSH_TIMING+x}" ] && echo "ts-timing 40-ohmyzsh-load 300" >&2\nexit 0\n' > "$FAKE_ROOT/pkgbin/zsh"
    run ts doctor < /dev/null
    [[ "$output" == *"Zsh açılışı"*"yavaş. En çok zaman alan: 40-ohmyzsh-load 300 ms"* ]]
}

@test "zsh yavaşlığı bizim parçalarda değilse doctor bunu söyler" {
    ts install --components zsh
    printf '#!/bin/sh\nsleep 0.35\n[ -n "${TS_ZSH_TIMING+x}" ] && echo "ts-timing 70-atuin 12" >&2\nexit 0\n' > "$FAKE_ROOT/pkgbin/zsh"
    run ts doctor < /dev/null
    [[ "$output" == *"Terminal Setup parçaları yalnızca 12 ms; kalan süre ~/.zshrc"* ]]
}

@test "zsh hızlı açılırsa süre bilgi olarak gösterilir" {
    ts install --components zsh
    printf '#!/bin/sh\nexit 0\n' > "$FAKE_ROOT/pkgbin/zsh"
    run ts doctor < /dev/null
    [[ "$output" =~ Zsh\ açılışı\ +[0-9]+\ ms ]]
}

@test "fzf-tab bağımlılıklarıyla kurulur ve eklentilerden önce yüklenir" {
    run ts install --components fzf-tab
    [ "$status" -eq 0 ]
    [ -f "$HOME/.config/terminal-setup/zsh.d/18-fzf-tab.zsh" ]
    [ -d "$HOME/.local/share/terminal-setup/plugins/fzf-tab" ]
    [ ! -d "$HOME/.oh-my-zsh" ]
    command -v fzf
}

@test "starship kurulur; powerlevel10k ile birlikte kurulamaz" {
    run ts install --components starship
    [ "$status" -eq 0 ]
    [ -f "$HOME/.config/terminal-setup/zsh.d/90-starship.zsh" ]
    [ "$(starship)" = "starship v0.1.0 (taklit)" ]
    run ts install --components p10k
    [ "$status" -ne 0 ]
    [[ "$output" == *"birlikte kullanılamaz"* ]]
    [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]
    run ts uninstall
    [[ "$output" == *"Sonuç: kalıntı yok."* ]]
}

@test "powerlevel10k kuruluyken starship reddedilir" {
    ts install --components p10k
    run ts install --components starship
    [ "$status" -ne 0 ]
    [[ "$output" == *"birlikte kullanılamaz"* ]]
    [ ! -e "$HOME/.local/bin/starship" ]
}
