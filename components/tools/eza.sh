#!/usr/bin/env bash
# Bileşen: eza — renkli, git farkında ls

component_register eza "eza" tools "Modern ls: ikonlar ve git durumu" ""

component_tip eza "ll" "Ayrıntılı liste (git durumuyla)"
component_tip eza "lt" "Ağaç görünümü"

comp_eza_install() {
    act_gh_binary eza-community/eza '^eza_x86_64-unknown-linux-musl\.tar\.gz$' '^eza_aarch64-unknown-linux-gnu\.tar\.gz$' eza || return 1
    # Simge ve tarih biçimi kişilikten gelir: tema uygulanınca 65-theme-tools
    # parçası TS_EZA_OPTS'u yeniden tanımlar. Takma adlar diziyi çalışırken okur.
    act_zsh_snippet 60 eza 'TS_EZA_OPTS=(--icons=auto)
alias ls="eza --group-directories-first \"\${TS_EZA_OPTS[@]}\""
alias ll="eza -l --git --group-directories-first \"\${TS_EZA_OPTS[@]}\""
alias la="eza -la --git --group-directories-first \"\${TS_EZA_OPTS[@]}\""
alias lt="eza --tree --level=2 \"\${TS_EZA_OPTS[@]}\""'
}

comp_eza_verify() { has_cmd eza; }
