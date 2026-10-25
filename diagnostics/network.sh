#!/usr/bin/env bash
# Teşhis: GitHub erişimi (araçlar ve eklentiler oradan indirilir)

diag_register network "İnternet"

diag_network_check() {
    if net_online; then
        diag_say "github.com erişilebilir"
        return 0
    fi
    diag_say "github.com'a erişilemiyor (VPN, DNS veya proxy?)"
    return 2
}
