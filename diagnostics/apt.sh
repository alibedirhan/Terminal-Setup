#!/usr/bin/env bash
# Teşhis: yarım kalmış dpkg işlemleri

diag_register apt "Paket yöneticisi"

diag_apt_check() {
    has_cmd dpkg || { echo "dpkg yok"; return 2; }
    if [[ -n "$(dpkg --audit 2>/dev/null)" ]]; then
        echo "Yarım kalmış paket işlemi var: sudo dpkg --configure -a"
        return 2
    fi
    echo "Tutarlı"
}
