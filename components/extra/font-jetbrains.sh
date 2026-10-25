#!/usr/bin/env bash
# Bileşen: JetBrains Mono Nerd Font — isteğe bağlı yazı tipi (kurulunca seçilir)

component_register font-jetbrains "JetBrains Mono" extra "Okunaklı kod yazı tipi (Nerd Font ikonlarıyla)" ""

component_tip font-jetbrains "terminal-setup.sh font set jetbrains" "Bu yazı tipini seç"

FONT_JETBRAINS_DIR="$TS_FONT_DIR/terminal-setup-JetBrainsMono"

comp_font_jetbrains_install() {
    # Nerd Fonts .tar.xz dağıtır; açmak için xz gerekir
    act_pkg xz-utils || return 1
    act_glob "$HOME/.cache/fontconfig"
    act_gh_extract ryanoasis/nerd-fonts '^JetBrainsMono\.tar\.xz$' "$FONT_JETBRAINS_DIR" 'JetBrainsMonoNerdFont-*.ttf' || return 1
    act_font_cache
    is_dry_run || font_select jetbrains
}

comp_font_jetbrains_verify() {
    compgen -G "$FONT_JETBRAINS_DIR/*.ttf" > /dev/null
}
