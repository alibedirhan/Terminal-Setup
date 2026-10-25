#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Yazı tipi seçimi
# ============================================================================
# MesloLGS NF (fonts bileşeni) Powerlevel10k için varsayılandır. İsteğe bağlı
# JetBrains Mono ve Fira Code (Nerd Font) bileşenleri de kurulabilir; kurulan
# yazı tipi seçilir ve terminallere uygulanır (theme_apply_font). Seçim
# "font" ayarında tutulur. Seçili yazı tipinin bileşeni kaldırılırsa
# MesloLGS NF'ye dönülür.
# ============================================================================

FONT_IDS=(meslo jetbrains firacode)
declare -gA FONT_FAMILY=([meslo]="MesloLGS NF" [jetbrains]="JetBrainsMono Nerd Font" [firacode]="FiraCode Nerd Font")
declare -gA FONT_COMPONENT=([meslo]=fonts [jetbrains]=font-jetbrains [firacode]=font-firacode)
RUNNER_AFTER_CHANGE+=(fonts_after_change)

# Yazı tipi kurulu mu (script ya da kullanıcı): font_installed ID
font_installed() {
    local st
    st=$(component_state "${FONT_COMPONENT[$1]}")
    [[ "$st" == ours || "$st" == external ]]
}

# Seçili yazı tipi kimliği -> REPLY (seçili olan kurulu değilse meslo)
font_current() {
    REPLY=$(settings_get font meslo)
    [[ -n "${FONT_FAMILY[$REPLY]:-}" ]] && font_installed "$REPLY" || REPLY=meslo
}

# Yazı tipini seç ve terminallere uygula: font_select ID
font_select() {
    local id="$1" owner="$TS_CURRENT_COMPONENT"
    if [[ -z "${FONT_FAMILY[$id]:-}" ]]; then
        log_err "Bilinmeyen yazı tipi: %s (seçenekler: %s)" "$id" "${FONT_IDS[*]}"
        return 2
    fi
    if ! font_installed "$id"; then
        log_err "%s kurulu değil; önce bileşeni kurun: %s" "${FONT_FAMILY[$id]}" "${FONT_COMPONENT[$id]}"
        return 1
    fi
    runner_prepare_light || return 1
    settings_set font "$id"
    TS_CURRENT_COMPONENT="${FONT_COMPONENT[$id]}"
    theme_apply_font
    TS_CURRENT_COMPONENT="$owner"
    log_ok "Yazı tipi: %s. Yeni açılan pencerelerde görünür." "${FONT_FAMILY[$id]}"
}

fonts_list() {
    local id mark state cur
    font_current
    cur="$REPLY"
    for id in "${FONT_IDS[@]}"; do
        [[ "$id" == "$cur" ]] && mark="*" || mark=" "
        if font_installed "$id"; then _t "kurulu"; else _t "kurulu değil"; fi
        state="$TR"
        printf '%s %-10s %-26s %s\n' "$mark" "$id" "${FONT_FAMILY[$id]}" "$state"
    done
}

# Seçili yazı tipinin bileşeni kaldırıldıysa MesloLGS NF'ye dön
fonts_after_change() {
    local chosen
    chosen=$(settings_get font meslo)
    [[ "$chosen" == meslo ]] && return 0
    font_installed "$chosen" && return 0
    settings_set font meslo
    font_installed meslo && font_select meslo > /dev/null
    return 0
}
