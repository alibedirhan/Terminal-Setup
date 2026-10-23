#!/usr/bin/env bash
# Bileşen: procs — renkli ve aranabilir ps

component_register procs "procs" tools "Modern ps" ""

comp_procs_install() {
    act_pkg unzip || return 1
    act_gh_binary dalance/procs 'x86_64-linux\.zip$' 'aarch64-linux\.zip$' procs
}

comp_procs_verify() { has_cmd procs; }
