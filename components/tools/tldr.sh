#!/usr/bin/env bash
# Bileşen: tldr — komutlar için kısa örnekler

component_register tldr "tldr" tools "Kısa komut örnekleri" ""

comp_tldr_install() {
    act_glob "$HOME/.local/share/tldr"
    act_glob "$HOME/.cache/tldr"
    act_glob "$HOME/.cache/tealdeer"
    act_pkg tldr || return 1
    # Sayfa önbelleği; başarısız olursa ilk kullanımda indirilir
    is_dry_run || run_logged tldr --update || true
}

comp_tldr_verify() { has_cmd tldr; }
