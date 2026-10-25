#!/usr/bin/env bats
# Bileşen çalıştırıcı: bağımlılıklar, dış kurulumlar, hata halinde geri alma

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
}

@test "bağımlılıklar önce gelir" {
    run resolve_components p10k
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | tr '\n' ' ')" = "zsh ohmyzsh fonts p10k " ]
}

@test "bilinmeyen bileşen reddedilir" {
    run resolve_components olmayan
    [ "$status" -ne 0 ]
}

@test "her bileşenin install ve verify fonksiyonu var" {
    local id
    for id in "${COMP_IDS[@]}"; do
        declare -F "$(_comp_fn "$id" install)" >/dev/null
        declare -F "$(_comp_fn "$id" verify)" >/dev/null
    done
    [ "${#COMP_IDS[@]}" -eq 22 ]
}

@test "profillerdeki her bileşen tanımlı" {
    local p id
    for p in $(profile_list); do
        for id in $(profile_components "$p"); do
            component_exists "$id"
        done
    done
}

@test "sistemde zaten olan araç dış kurulum sayılır ve dokunulmaz" {
    echo bat >> "$FAKE_ROOT/dpkg.txt"
    printf '#!/bin/sh\n' > "$FAKE_ROOT/pkgbin/batcat"; chmod +x "$FAKE_ROOT/pkgbin/batcat"
    runner_install bat
    [ "$(component_state bat)" = "external" ]
    ledger_has note external:bat
    ! ledger_has pkg bat
}

@test "yarıda kalan bileşen geri alınır; diğerleri etkilenmez" {
    runner_install zsh ohmyzsh
    touch "$FAKE_ROOT/clone-fail"
    run runner_install zsh-plugins
    [ "$status" -ne 0 ]
    [ "$(component_state zsh-plugins)" = "absent" ]
    [ -z "$(ledger_lines zsh-plugins)" ]
    [ "$(component_state ohmyzsh)" = "ours" ]
}

@test "ikinci kurulum hiçbir şeyi değiştirmez" {
    runner_install bat ripgrep
    local before
    before=$(cat "$TS_LEDGER")
    runner_install bat ripgrep
    [ "$(cat "$TS_LEDGER")" = "$before" ]
}

@test "bağımlı bileşen varken kaldırma reddedilir" {
    runner_install ohmyzsh
    TS_CURRENT_COMPONENT=core
    runner_install p10k
    run runner_remove_component ohmyzsh
    [ "$status" -ne 0 ]
    [ "$(component_state ohmyzsh)" = "ours" ]
}

@test "GitHub aracı ~/.local/bin altına kurulur ve kaldırılır" {
    runner_install lazygit
    [ -x "$HOME/.local/bin/lazygit" ]
    runner_remove_component lazygit
    [ ! -e "$HOME/.local/bin/lazygit" ]
    [ ! -e "$HOME/.local/bin" ]
}

@test "desteklenmeyen mimaride GitHub aracı kurulmaz" {
    export TS_FAKE_ARCH=riscv64
    run runner_install dust
    [ "$status" -ne 0 ]
    [ ! -e "$HOME/.local/bin/dust" ]
}

@test "zip olarak dağıtılan araç (procs) kurulur" {
    runner_install procs
    [ -x "$HOME/.local/bin/procs" ]
    ledger_has pkg unzip
}

@test "delta git ayarlarını kaydeder; kaldırınca .gitconfig yok olur" {
    runner_install delta
    [ "$(git config --global --get core.pager)" = "delta" ]
    runner_remove_component delta
    [ ! -e "$HOME/.gitconfig" ]
}

@test "zsh bileşeni varsayılan kabuğu değiştirir; kaldırınca geri gelir" {
    runner_install zsh
    [ "$(login_shell)" = "$FAKE_ROOT/pkgbin/zsh" ]
    grep -q "terminal-setup:zsh" "$HOME/.zshrc"
    runner_remove_component zsh
    [ "$(login_shell)" = "/bin/bash" ]
    [ ! -e "$HOME/.zshrc" ]
    ! pkg_is_installed zsh
}
