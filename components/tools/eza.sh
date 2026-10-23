#!/usr/bin/env bash
# Bileşen: eza — renkli, git farkında ls

component_register eza "eza" tools "Modern ls: ikonlar ve git durumu" ""

comp_eza_install() {
    act_gh_binary eza-community/eza '^eza_x86_64-unknown-linux-musl\.tar\.gz$' '^eza_aarch64-unknown-linux-gnu\.tar\.gz$' eza || return 1
    act_zsh_snippet 60 eza "alias ls='eza --group-directories-first --icons=auto'
alias ll='eza -l --git --group-directories-first --icons=auto'
alias la='eza -la --git --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --icons=auto'"
}

comp_eza_verify() { has_cmd eza; }
