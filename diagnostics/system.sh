#!/usr/bin/env bash
# Teşhis: işletim sistemi ve mimari desteği

diag_register system "Sistem"

diag_system_check() {
    local arch
    arch=$(sys_arch) || { echo "Desteklenmeyen mimari: $(uname -m)"; return 2; }
    if sys_is_supported; then
        echo "$(sys_os), $arch"
        return 0
    fi
    echo "$(sys_os) resmi olarak desteklenmiyor (Ubuntu 22.04/24.04/26.04)"
    return 1
}
