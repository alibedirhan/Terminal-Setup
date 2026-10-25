#!/usr/bin/env bash
# Teşhis: kaydı olan ama çalışmayan bileşenler (ör. elle silinmiş araç)

diag_register components "Bileşenler"

_diag_broken_components() {
    local id
    for id in $(ledger_components); do
        component_exists "$id" || continue
        [[ "$(component_state "$id")" == "broken" ]] && echo "$id"
    done
}

diag_components_check() {
    local broken
    broken=$(_diag_broken_components | tr '\n' ' ')
    if [[ -n "$broken" ]]; then
        echo "Bozuk: $broken(yeniden kurulabilir)"
        return 1
    fi
    echo "$(ledger_components | grep -vcE '^(core|theme)$') bileşen sağlam"
}

diag_components_fix() {
    local id
    runner_prepare || return 1
    for id in $(_diag_broken_components); do
        undo_component "$id"
        runner_install_one "$id"
    done
}
