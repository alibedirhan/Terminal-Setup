#!/usr/bin/env bash
# Teşhis: yarım kalmış dpkg işlemleri

diag_register apt "Paket yöneticisi"

diag_apt_check() {
    has_cmd dpkg || { diag_say "dpkg yok"; return 2; }
    if [[ -n "$(dpkg --audit 2>/dev/null)" ]]; then
        diag_say "Yarım kalmış paket işlemi var: %s" "sudo dpkg --configure -a"
        return 2
    fi
    diag_say "Tutarlı"
}
