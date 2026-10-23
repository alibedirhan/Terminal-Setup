#!/usr/bin/env bash
# Bileşen: btop — sistem izleyici

component_register btop "btop" tools "Sistem izleyici" ""

comp_btop_install() {
    act_pkg btop || return 1
    act_glob "$HOME/.config/btop"
}

comp_btop_verify() { has_cmd btop; }
