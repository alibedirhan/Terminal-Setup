#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: kurulum sihirbazı
# ============================================================================
# Adımlar: profil -> tema -> özet ve onay -> kurulum -> P10k sihirbazı

tui_install_wizard() {
    local profiles=() items=() p ids=() themes=() theme=""
    mapfile -t profiles < <(profile_list)
    for p in "${profiles[@]}"; do items+=("$p|$(profile_description "$p")"); done
    items+=("özel|Bileşenleri kendim seçeceğim")
    ui_menu "1/3  Profil seçin" "${items[@]}" || return 0

    if ((UI_CHOICE == ${#profiles[@]})); then
        tui_pick_components || return 0
        ids=("${TUI_PICKED[@]}")
    else
        mapfile -t ids < <(profile_components "${profiles[UI_CHOICE]}")
    fi
    ((${#ids[@]})) || return 0

    mapfile -t themes < <(theme_list)
    items=()
    for p in "${themes[@]}"; do theme_load "$p" >/dev/null && items+=("${THEME[NAME]}|${THEME[DESC]:-}"); done
    items+=("Tema uygulama|Terminal renklerine dokunma")
    ui_menu "2/3  Tema seçin (sonradan 'Tema dene' ile değiştirebilirsiniz)" "${items[@]}" || return 0
    ((UI_CHOICE < ${#themes[@]})) && theme="${themes[UI_CHOICE]}"

    ui_clear
    ui_title "3/3  Özet"
    printf '  %s%s\n' "$(ui_pad Bileşenler 14)" "$(resolve_components "${ids[@]}" | tr '\n' ' ')"
    printf '  %s%s\n' "$(ui_pad Tema 14)" "${theme:-uygulanmayacak}"
    printf '\n  %s\n\n' "${C_DIM}Her değişiklik kaydedilir; 'Kaldır' menüsü hepsini geri alır.${C_RESET}"
    ui_confirm "Kurulum başlasın mı?" e || return 0

    runner_install "${ids[@]}"
    [[ -n "$theme" ]] && theme_apply "$theme"
    tui_offer_p10k_wizard
    install_next_steps
    ui_pause
}

# Kurulumdan sonra Powerlevel10k sihirbazını başlatmayı öner
tui_offer_p10k_wizard() {
    is_dry_run && return 0
    [[ "$(component_state p10k)" == "ours" && ! -f "$HOME/.p10k.zsh" ]] || return 0
    ui_is_tty || return 0
    if ui_confirm "Powerlevel10k görünüm sihirbazı şimdi açılsın mı?" e; then
        zsh -i -c 'p10k configure' || log_warn "Sihirbaz açılamadı; yeni terminalde 'p10k configure' yazın."
    fi
}

TUI_PICKED=()

# Kategorilere göre bileşen seçimi; sonuç TUI_PICKED
tui_pick_components() {
    local items=() map=() id i preset=""
    for id in "${COMP_IDS[@]}"; do
        map+=("$id")
        items+=("${COMP_NAME[$id]}|${COMP_DESC[$id]}")
    done
    ui_checklist "Kurulacak bileşenleri seçin" "$preset" "${items[@]}" || return 1
    TUI_PICKED=()
    for i in "${UI_SELECTED[@]}"; do TUI_PICKED+=("${map[i]}"); done
    ((${#TUI_PICKED[@]} > 0))
}
