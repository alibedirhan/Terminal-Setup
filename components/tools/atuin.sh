#!/usr/bin/env bash
# Bileşen: atuin — aranabilir kabuk geçmişi (Ctrl+R). Yukarı ok tuşunun
# davranışı değiştirilmez.

component_register atuin "atuin" tools "Aranabilir komut geçmişi" ""

comp_atuin_install() {
    act_gh_binary atuinsh/atuin '^atuin-x86_64-unknown-linux-musl\.tar\.gz$' '^atuin-aarch64-unknown-linux-musl\.tar\.gz$' atuin || return 1
    act_zsh_snippet 70 atuin 'eval "$(atuin init zsh --disable-up-arrow)"' || return 1
    # atuin ilk çalıştığında ayar ve veritabanını bu konumlardan birine yazar
    act_userdata "$HOME/.local/share/atuin"
    act_userdata "$HOME/.atuin"
    act_glob "$HOME/.config/atuin"
}

comp_atuin_verify() { has_cmd atuin; }
