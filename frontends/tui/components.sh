#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: bileşen yönetimi
# ============================================================================
# İşaretli = kurulu kalsın/kurulsun, işaretsiz = kaldırılsın. Kurulumdan önce
# sizde olan (dış) bileşenler kaldırılamaz; onlara dokunulmaz.

declare -gA TUI_COMP_STATE=()

# Liste rozeti: önceden hesaplanmış durumdan (her bileşen bir kez okunur)
_tui_comp_badge() { status_symbol "${TUI_COMP_STATE[$1]}"; }

tui_components() {
    local preset="" i id
    local -a to_install=() to_remove=() keep_external=()
    TUI_COMP_STATE=()
    for id in "${COMP_IDS[@]}"; do TUI_COMP_STATE[$id]=$(component_state "$id"); done
    tui_component_items _tui_comp_badge
    for ((i = 0; i < ${#TUI_ITEM_IDS[@]}; i++)); do
        id="${TUI_ITEM_IDS[i]}"
        [[ "${TUI_COMP_STATE[$id]}" == ours || "${TUI_COMP_STATE[$id]}" == external ]] && preset+="$i "
    done
    ui_checklist --subtitle "İşaretli olanlar kurulu kalır ya da kurulur, işareti kaldırılanlar kaldırılır." \
        "Bileşenler" "$preset" "${TUI_ITEMS[@]}" || return 0

    for ((i = 0; i < ${#TUI_ITEM_IDS[@]}; i++)); do
        id="${TUI_ITEM_IDS[i]}"
        if in_list "$i" "${UI_SELECTED[@]}"; then
            [[ "${TUI_COMP_STATE[$id]}" == absent || "${TUI_COMP_STATE[$id]}" == broken ]] && to_install+=("$id")
        else
            [[ "${TUI_COMP_STATE[$id]}" == ours ]] && to_remove+=("$id")
            [[ "${TUI_COMP_STATE[$id]}" == external ]] && keep_external+=("$id")
        fi
    done
    tui_run tui_components_apply "${#to_install[@]}" "${to_install[@]}" "${#to_remove[@]}" "${to_remove[@]}" \
        "${keep_external[@]}"
}

# tui_components_apply N KURULACAK... M KALDIRILACAK... DOKUNULMAYACAK...
tui_components_apply() {
    local n="$1" id
    shift
    local -a inst=("${@:1:n}")
    shift "$n"
    local m="$1"
    shift
    local -a rem=("${@:1:m}")
    shift "$m"
    local -a ext=("$@")

    ui_title "Değişiklikler"
    if ((${#inst[@]})); then
        _t "Kurulacak"; ui_padr "$TR" 16
        ui_line "  ${U_OK}+${U_RST} ${REPLY}${inst[*]}"
    fi
    if ((${#rem[@]})); then
        _t "Kaldırılacak"; ui_padr "$TR" 16
        ui_line "  ${U_ERR}−${U_RST} ${REPLY}${rem[*]}"
    fi
    if ((${#ext[@]})); then
        _t "Dokunulmayacak"; ui_padr "$TR" 16
        local pad="$REPLY"
        _t "(sizde zaten vardı)"
        ui_line "  ${U_MUTED}• ${pad}${ext[*]} $TR"
    fi
    if ((${#inst[@]} + ${#rem[@]} == 0)); then
        log_info "Değişiklik yok."
        return 0
    fi
    printf '\n'
    ui_confirm "Uygulansın mı?" e || return 0
    ((${#inst[@]})) && runner_install "${inst[@]}"
    for id in "${rem[@]}"; do runner_remove_component "$id"; done
    return 0
}
