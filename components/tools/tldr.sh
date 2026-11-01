#!/usr/bin/env bash
# Bileşen: tldr — komutlar için kısa örnekler

component_register tldr "tldr" tools "Kısa komut örnekleri" ""

component_tip tldr "tldr tar" "Bir komutun kısa örneklerini göster"
component_tip tldr "Alt+H" "Yazdığınız komutun kısa yardımını göster"

# Alt+H yardımının iletisi sistem dilinde; "lang" sayfanın aranacağı dil
_tldr_help_messages() {
    i18n_zsh_messages _ts_hmsg none "%s için yardım sayfası yok."
}

# Ubuntu 25.10'dan itibaren depoda "tldr" paketi yok; aynı komutu sağlayan
# tealdeer 24.04'ten beri var (daha hızlı ve bakımı sürüyor). 22.04'te
# yalnızca tldr paketi bulunur.
comp_tldr_install() {
    local pkg=tealdeer
    sys_os_at_least 24.04 || pkg=tldr
    act_glob "$HOME/.local/share/tldr"
    act_glob "$HOME/.cache/tldr"
    act_glob "$HOME/.cache/tealdeer"
    act_pkg "$pkg" || return 1
    # Alt+H: yazılan komutun kısa yardımı (zsh/help.zsh)
    _tldr_help_messages
    act_zsh_snippet 61 tldr-help "$REPLY"$'\n'"$(cat "$TS_ROOT/zsh/help.zsh")" || return 1
    # Sayfa önbelleği; başarısız olursa ilk kullanımda indirilir
    is_dry_run || run_logged tldr --update || true
}

comp_tldr_verify() { has_cmd tldr; }
