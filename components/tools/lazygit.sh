#!/usr/bin/env bash
# Bileşen: lazygit — terminalde git arayüzü (lg)

component_register lazygit "lazygit" tools "Git arayüzü (lg)" ""

comp_lazygit_install() {
    act_gh_binary jesseduffield/lazygit '_[Ll]inux_x86_64\.tar\.gz$' '_[Ll]inux_arm64\.tar\.gz$' lazygit || return 1
    act_zsh_snippet 60 lazygit "alias lg='lazygit'" || return 1
    act_glob "$HOME/.config/lazygit"
    act_glob "$HOME/.local/state/lazygit"
}

comp_lazygit_verify() { has_cmd lazygit; }
