#!/usr/bin/env bash
# Bileşen: tldr — komutlar için kısa örnekler

component_register tldr "tldr" tools "Kısa komut örnekleri" ""

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
    # Sayfa önbelleği; başarısız olursa ilk kullanımda indirilir
    is_dry_run || run_logged tldr --update || true
}

comp_tldr_verify() { has_cmd tldr; }
