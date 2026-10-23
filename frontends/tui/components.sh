#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: bileşen yönetimi
# ============================================================================
# İşaretli = kurulu kalsın/kurulsun, işaretsiz = kaldırılsın. Kurulumdan önce
# sizde olan (dış) bileşenler kaldırılamaz; onlara dokunulmaz.

tui_components() {
    local items=() map=() states=() preset="" id i state
    local to_install=() to_remove=() keep_external=()
    for id in "${COMP_IDS[@]}"; do
        state=$(component_state "$id")
        i=${#map[@]}
        map+=("$id")
        states+=("$state")
        [[ "$state" == ours || "$state" == external ]] && preset+="$i "
        items+=("${COMP_NAME[$id]}|${COMP_DESC[$id]}  [$(status_symbol "$state")]")
    done
    ui_checklist "Bileşenler (işaretli = kurulu)" "$preset" "${items[@]}" || return 0

    for ((i = 0; i < ${#map[@]}; i++)); do
        if in_list "$i" "${UI_SELECTED[@]}"; then
            [[ "${states[i]}" == absent || "${states[i]}" == broken ]] && to_install+=("${map[i]}")
        else
            [[ "${states[i]}" == ours ]] && to_remove+=("${map[i]}")
            [[ "${states[i]}" == external ]] && keep_external+=("${map[i]}")
        fi
    done

    ui_clear
    ui_title "Değişiklikler"
    ((${#to_install[@]})) && printf '  Kurulacak:   %s\n' "${to_install[*]}"
    ((${#to_remove[@]})) && printf '  Kaldırılacak: %s\n' "${to_remove[*]}"
    ((${#keep_external[@]})) && printf '  %s\n' "${C_DIM}Dokunulmayacak (sizde zaten vardı): ${keep_external[*]}${C_RESET}"
    if ((${#to_install[@]} + ${#to_remove[@]} == 0)); then
        log_info "Değişiklik yok."
        ui_pause
        return 0
    fi
    printf '\n'
    ui_confirm "Uygulansın mı?" e || return 0
    ((${#to_install[@]})) && runner_install "${to_install[@]}"
    for id in "${to_remove[@]}"; do runner_remove_component "$id"; done
    ui_pause
}
