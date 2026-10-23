#!/usr/bin/env bash
# Bileşen: MesloLGS NF — Powerlevel10k'nin önerdiği, ikon içeren yazı tipi

component_register fonts "MesloLGS NF" shell "Prompt ikonları için yazı tipi" ""

FONT_BASE_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"
FONT_FILES=("MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf")

comp_fonts_install() {
    local f
    # fc-cache kullanıcı önbelleği oluşturur; önceden yoksa kaldırmada silinir
    act_glob "$HOME/.cache/fontconfig"
    # fontconfig 2.13 (Ubuntu 22.04) yazı tipi dizinine .uuid dosyası bırakır
    act_glob "$TS_FONT_DIR/.uuid"
    act_pkg fontconfig || return 1
    for f in "${FONT_FILES[@]}"; do
        act_download "$FONT_BASE_URL/${f// /%20}" "$TS_FONT_DIR/$f" || return 1
    done
    act_font_cache
    theme_apply_font
}

comp_fonts_verify() {
    local f
    for f in "${FONT_FILES[@]}"; do
        [[ -s "$TS_FONT_DIR/$f" ]] || return 1
    done
}
