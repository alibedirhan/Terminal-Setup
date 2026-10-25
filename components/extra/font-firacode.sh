#!/usr/bin/env bash
# Bileşen: Fira Code Nerd Font — isteğe bağlı yazı tipi (kurulunca seçilir)

component_register font-firacode "Fira Code" extra "Bitişik harfli (=> !=) kod yazı tipi (Nerd Font)" ""

component_tip font-firacode "terminal-setup.sh font set firacode" "Bu yazı tipini seç"

FONT_FIRACODE_DIR="$TS_FONT_DIR/terminal-setup-FiraCode"

comp_font_firacode_install() {
    # Nerd Fonts .tar.xz dağıtır; açmak için xz gerekir
    act_pkg xz-utils || return 1
    act_glob "$HOME/.cache/fontconfig"
    act_gh_extract ryanoasis/nerd-fonts '^FiraCode\.tar\.xz$' "$FONT_FIRACODE_DIR" 'FiraCodeNerdFont-*.ttf' || return 1
    act_font_cache
    is_dry_run || font_select firacode
}

comp_font_firacode_verify() {
    compgen -G "$FONT_FIRACODE_DIR/*.ttf" > /dev/null
}
