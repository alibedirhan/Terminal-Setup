#!/usr/bin/env bash
# Bileşen: zoxide — sık gidilen dizinleri öğrenen akıllı cd (z)

component_register zoxide "zoxide" tools "Akıllı cd: z proje" ""

component_tip zoxide "z proje" "Sık gittiğin dizine adının bir parçasıyla git"
component_tip zoxide "zi" "Dizin geçmişinden seçerek git"

comp_zoxide_install() {
    act_gh_binary ajeetdsouza/zoxide 'x86_64-unknown-linux-musl\.tar\.gz$' 'aarch64-unknown-linux-musl\.tar\.gz$' zoxide || return 1
    act_zsh_snippet 60 zoxide 'eval "$(zoxide init zsh)"' || return 1
    act_userdata "$HOME/.local/share/zoxide"
}

comp_zoxide_verify() { has_cmd zoxide; }
