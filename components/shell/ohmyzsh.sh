#!/usr/bin/env bash
# Bileşen: Oh My Zsh — kurulum betiği çalıştırılmaz (o betik ~/.zshrc'yi
# yeniden yazar); depo klonlanır ve yükleme yönetilen parçalardan yapılır.

component_register ohmyzsh "Oh My Zsh" shell "Zsh eklenti ve tema çatısı" "zsh"

OMZ_DIR="$HOME/.oh-my-zsh"

comp_ohmyzsh_install() {
    act_clone https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR" || return 1
    act_zsh_snippet 15 ohmyzsh-base 'export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
zstyle '"':omz:update'"' mode reminder
plugins=(git colored-man-pages)' || return 1
    act_zsh_snippet 40 ohmyzsh-load '[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"'
}

# Kullanıcının kendi Oh My Zsh kurulumu (.zshrc'si onu yüklüyorsa) dış
# kurulum sayılır ve dokunulmaz.
comp_ohmyzsh_verify() {
    [[ -f "$OMZ_DIR/oh-my-zsh.sh" ]] || return 1
    [[ -f "$TS_CONFIG_DIR/zsh.d/40-ohmyzsh-load.zsh" ]] && return 0
    [[ -f "$HOME/.zshrc" ]] && rc_without_blocks "$HOME/.zshrc" | grep 'oh-my-zsh.sh' >/dev/null
}
