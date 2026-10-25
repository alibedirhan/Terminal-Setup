#!/usr/bin/env bash
# Bileşen: fd — hızlı ve sade find

component_register fd "fd" tools "Modern find" ""

component_tip fd "fd ad" "Dosya ve dizin bul"

comp_fd_install() {
    act_pkg fd-find || return 1
    # Ubuntu'da komutun adı fdfind'dır
    act_zsh_snippet 60 fd "(( \$+commands[fdfind] && ! \$+commands[fd] )) && alias fd='fdfind'"
}

comp_fd_verify() { has_cmd fdfind || has_cmd fd; }
