#!/usr/bin/env bash
# Teşhis: işletim sistemi ve mimari desteği

diag_register system "Sistem"

diag_system_check() {
    local arch
    arch=$(sys_arch) || { diag_say "Desteklenmeyen mimari: %s" "$(uname -m)"; return 2; }
    if sys_is_supported; then
        echo "$(sys_os), $arch"
        return 0
    fi
    diag_say "%s resmi olarak desteklenmiyor (Ubuntu 22.04/24.04/26.04)" "$(sys_os)"
    return 1
}
