#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: kurulum sihirbazı
# ============================================================================
# Adımlar: profil -> tema -> özet ve onay -> kurulum -> P10k sihirbazı

# Adım göstergesi: tui_steps ŞİMDİKİ "Profil" "Tema" "Onay"
tui_steps() {
    local cur="$1" i=1 out="" label
    shift
    for label in "$@"; do
        ((i > 1)) && out+=" ${U_FAINT}───${U_RST} "
        if ((i < cur)); then out+="${U_OK}✓${U_RST} ${U_MUTED}${label}${U_RST}"
        elif ((i == cur)); then out+="${U_ACC}●${U_RST} ${U_BOLD}${label}${U_RST}"
        else out+="${U_FAINT}○ ${label}${U_RST}"; fi
        i=$((i + 1))
    done
    printf '%s' "$out"
}

tui_install_wizard() {
    local profiles=() items=() p ids=() themes=() theme="" comps rc
    mapfile -t profiles < <(profile_list)
    for p in "${profiles[@]}"; do items+=("$p|$(profile_description "$p")|▸"); done
    items+=("özel|Bileşenleri kendim seçeceğim|▸")
    UI_SUBTITLE=$(tui_steps 1 Profil Tema Onay)
    ui_menu "Kurulum sihirbazı" "${items[@]}"
    rc=$?
    UI_SUBTITLE=""
    ((rc == 0)) || return 0

    if ((UI_CHOICE == ${#profiles[@]})); then
        tui_pick_components || return 0
        ids=("${TUI_PICKED[@]}")
    else
        mapfile -t ids < <(profile_components "${profiles[UI_CHOICE]}")
    fi
    ((${#ids[@]})) || return 0

    mapfile -t themes < <(theme_list)
    items=()
    for p in "${themes[@]}"; do
        theme_load "$p" >/dev/null && items+=("${THEME[NAME]}|${THEME[DESC]:-}|$(tui_theme_dots "$p")")
    done
    items+=("Tema uygulama|Terminal renklerine dokunma|${U_MUTED}○${U_RST}")
    UI_SUBTITLE="$(tui_steps 2 Profil Tema Onay)    ${U_MUTED}sonradan 'Tema dene' ile değiştirebilirsiniz${U_RST}"
    ui_menu "Kurulum sihirbazı" "${items[@]}"
    rc=$?
    UI_SUBTITLE=""
    ((rc == 0)) || return 0
    ((UI_CHOICE < ${#themes[@]})) && theme="${themes[UI_CHOICE]}"

    ui_clear
    ui_layout
    ui_line ""
    ui_line "${U_ACC}◆${U_RST} ${U_BOLD}Kurulum sihirbazı"
    ui_line "  $(tui_steps 3 Profil Tema Onay)"
    ui_line ""
    comps=""
    for p in $(resolve_components "${ids[@]}"); do comps+="${comps:+ · }${COMP_NAME[$p]}"; done
    ui_card_top "Özet"
    tui_card_wrap "Bileşenler" "$comps"
    p="uygulanmayacak"
    [[ -n "$theme" ]] && theme_load "$theme" >/dev/null && p="${THEME[NAME]}"
    ui_card_row "${U_MUTED}$(ui_pad Tema 14)${U_RST}$p"
    ui_card_row ""
    ui_card_row "${U_MUTED}Her değişiklik kaydedilir; 'Kaldır' menüsü hepsini geri alır.${U_RST}"
    ui_card_bottom
    printf '\n'
    ui_confirm "Kurulum başlasın mı?" e || return 0

    printf '\n'
    runner_install "${ids[@]}"
    [[ -n "$theme" ]] && theme_apply "$theme"
    UI_HEADER_STALE=1
    tui_offer_p10k_wizard
    install_next_steps
    ui_pause
}

# Kart içinde etiketli, satır kaydıran alan: tui_card_wrap "Etiket" "uzun metin"
tui_card_wrap() {
    local label="$1" text="$2" word line="" room first=1
    room=$((UI_W - 4 - 14))
    for word in $text; do
        if ((${#line} + ${#word} + 1 > room)) && [[ -n "$line" ]]; then
            if ((first)); then ui_card_row "${U_MUTED}$(ui_pad "$label" 14)${U_RST}$line"; first=0
            else ui_card_row "$(ui_pad "" 14)$line"; fi
            line=""
        fi
        line+="${line:+ }$word"
    done
    if ((first)); then ui_card_row "${U_MUTED}$(ui_pad "$label" 14)${U_RST}$line"
    else ui_card_row "$(ui_pad "" 14)$line"; fi
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
    local items=() map=() id i cat
    for cat in "${COMP_CATEGORIES[@]}"; do
        items+=("#${COMP_CAT_LABEL[$cat]}")
        for id in $(component_ids_by_cat "$cat"); do
            map+=("$id")
            items+=("${COMP_NAME[$id]}|${COMP_DESC[$id]}")
        done
    done
    ui_checklist "Kurulacak bileşenleri seçin" "" "${items[@]}" || return 1
    TUI_PICKED=()
    for i in "${UI_SELECTED[@]}"; do TUI_PICKED+=("${map[i]}"); done
    ((${#TUI_PICKED[@]} > 0))
}
