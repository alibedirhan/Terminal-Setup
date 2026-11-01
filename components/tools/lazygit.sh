#!/usr/bin/env bash
# Bileşen: lazygit — terminalde git arayüzü (lg)

component_register lazygit "lazygit" tools "Git arayüzü (lg)" ""

component_tip lazygit "lg" "Git arayüzünü aç"

comp_lazygit_install() {
    local theme
    act_gh_binary jesseduffield/lazygit '_[Ll]inux_x86_64\.tar\.gz$' '_[Ll]inux_arm64\.tar\.gz$' lazygit || return 1
    act_zsh_snippet 60 lazygit "alias lg='lazygit'" || return 1
    # Ayar dosyası kullanıcınındır (lazygit ilk açılışta boş olarak yazar):
    # kaldırırken arşive taşınır, dizin boş kalırsa silinir. Durum dosyası önbellektir.
    act_userdata "$HOME/.config/lazygit/config.yml"
    act_glob "$HOME/.local/state/lazygit"
    # Uygulanmış bir tema varsa kenar ve renkleri ona göre üret (renderers/lazygit.sh)
    theme=$(settings_get theme)
    if [[ -n "$theme" ]] && rend_lazygit_available && theme_load "$theme"; then
        rend_lazygit_apply
    fi
}

comp_lazygit_verify() { has_cmd lazygit; }
