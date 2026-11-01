#!/usr/bin/env bash
# Bileşen: atuin — aranabilir kabuk geçmişi (Ctrl+R). Yukarı ok tuşunun
# davranışı değiştirilmez.

component_register atuin "atuin" tools "Aranabilir komut geçmişi" ""

component_tip atuin "Ctrl+R" "Geçmişi atuin ile ara (tarih, dizin ve çıkış koduyla)"

comp_atuin_install() {
    act_gh_binary atuinsh/atuin '^atuin-x86_64-unknown-linux-musl\.tar\.gz$' '^atuin-aarch64-unknown-linux-musl\.tar\.gz$' atuin || return 1
    # fzf de kuruluysa Ctrl+R atuin'de kalır (70 > 60, Oh My Zsh'i script kurduğundaki gibi)
    act_zsh_snippet 70 atuin 'eval "$(atuin init zsh --disable-up-arrow)"'$'\n'"$(zsh_late_rebind atuin atuin-search fzf-history-widget)" || return 1
    # atuin ilk çalıştığında ayar ve veritabanını bu konumlardan birine yazar
    act_userdata "$HOME/.local/share/atuin"
    act_userdata "$HOME/.atuin"
    act_userdata "$HOME/.config/atuin/config.toml"
}

comp_atuin_verify() { has_cmd atuin; }
