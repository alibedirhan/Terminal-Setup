#!/usr/bin/env bash
# Teşhis: temanın uygulanabileceği terminal var mı?

diag_register terminal "Terminal"

diag_terminal_check() {
    local found=() id
    for id in $(renderers_available terminal); do
        found+=("${RENDERER_NAME[$id]}")
    done
    if ((${#found[@]} == 0)); then
        diag_say "Desteklenen terminal yok; temalar uygulanamaz"
        return 1
    fi
    echo "${found[*]}"
}
