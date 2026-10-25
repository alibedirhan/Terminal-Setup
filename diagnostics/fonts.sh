#!/usr/bin/env bash
# Teşhis: Powerlevel10k var ama MesloLGS NF yazı tipi yok

diag_register fonts "Yazı tipi"

diag_fonts_check() {
    if fc-list 2>/dev/null | grep -q "MesloLGS NF"; then
        echo "MesloLGS NF kurulu"
        return 0
    fi
    if [[ "$(component_state p10k)" == "ours" ]]; then
        echo "MesloLGS NF yok; prompt ikonları kare görünür"
        return 1
    fi
    echo "MesloLGS NF yok (gerekmiyor)"
}

diag_fonts_fix() {
    runner_prepare && runner_install_one fonts
}
