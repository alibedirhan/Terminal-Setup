#!/usr/bin/env bash
# Bileşen: komut paleti — Ctrl+Space ile projenin betikleri, testleri, sanal
# ortamı, git ve son komutlar tek listede (zsh/palette.zsh). Liste fzf'le
# süzülür; seçilen komut çalıştırılmaz, komut satırına yazılır.

component_register palette "Komut paleti" shell "Ctrl+Space: projenin betikleri, testler, git ve son komutlar" "zsh fzf"

component_tip palette "Ctrl+Space" "Bu projede çalıştırabileceklerinizi listeleyin"

# Paletin iletileri sistem dilinde
_palette_messages() {
    i18n_zsh_messages _ts_pmsg \
        script "betik" test "test" env "ortam" recent "geçmiş" \
        venv "sanal ortamı aç" empty "Bu dizinde önerilecek komut yok." \
        header "Enter: komut satırına yaz · Esc: kapat"
}

comp_palette_install() {
    _palette_messages
    act_zsh_snippet 97 palette "$REPLY"$'\n'"$(cat "$TS_ROOT/zsh/palette.zsh")"
}

comp_palette_verify() { [[ -f "$TS_CONFIG_DIR/zsh.d/97-palette.zsh" ]]; }
