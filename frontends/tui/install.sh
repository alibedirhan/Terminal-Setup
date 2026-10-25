#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: kurulum sihirbazı
# ============================================================================
# Adımlar: profil -> tema -> özet ve onay -> kurulum -> P10k sihirbazı.
# Seçimler menüde yapılır; özet, onay ve kurulum tui_run ile normal ekranda.

TUI_PICKED=()

# Adım göstergesi -> REPLY: tui_steps ŞİMDİKİ "Profil" "Tema" "Onay"
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
    REPLY="$out"
}

tui_install_wizard() {
    local profiles=() items=() themes=() ids=() p theme=""
    mapfile -t profiles < <(profile_list)
    for p in "${profiles[@]}"; do items+=("$p|$(profile_description "$p")|▸"); done
    items+=("özel|Bileşenleri kendim seçeceğim|▸")
    tui_steps 1 Profil Tema Onay
    ui_menu --subtitle "$REPLY" "Kurulum sihirbazı" "${items[@]}" || return 0

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
        theme_load "$p" >/dev/null || continue
        items+=("${THEME[NAME]}|${THEME[DESC]:-}|$(tui_theme_dot)")
    done
    items+=("Tema uygulama|Terminal renklerine dokunma|${U_MUTED}○")
    tui_steps 2 Profil Tema Onay
    ui_menu --subtitle "$REPLY    ${U_MUTED}sonradan 'Tema dene' ile değiştirilebilir" \
        "Kurulum sihirbazı" "${items[@]}" || return 0
    ((UI_CHOICE < ${#themes[@]})) && theme="${themes[UI_CHOICE]}"

    tui_run tui_install_confirmed "$theme" "${ids[@]}"
}

# Özet, onay ve kurulum: tui_install_confirmed TEMA BİLEŞEN...
tui_install_confirmed() {
    local theme="$1" id comps="" theme_name="uygulanmayacak"
    shift
    ui_layout
    ui_line "${U_ACC}◆${U_RST} ${U_BOLD}Kurulum sihirbazı"
    tui_steps 3 Profil Tema Onay
    ui_line "  $REPLY"
    ui_line ""
    for id in $(resolve_components "$@"); do comps+="${comps:+ · }${COMP_NAME[$id]}"; done
    [[ -n "$theme" ]] && theme_load "$theme" >/dev/null && theme_name="${THEME[NAME]}"
    ui_card_top "Özet"
    tui_card_wrap "Bileşenler" "$comps"
    ui_card_row "${U_MUTED}$(ui_pad Tema 14)${U_RST}$theme_name"
    ui_card_row ""
    ui_card_row "${U_MUTED}Her değişiklik kaydedilir; 'Kaldır' menüsü hepsini geri alır.${U_RST}"
    ui_card_bottom
    printf '\n'
    ui_confirm "Kurulum başlasın mı?" e || return 0

    printf '\n'
    runner_install "$@"
    [[ -n "$theme" ]] && theme_apply "$theme"
    tui_offer_p10k_wizard
    install_next_steps
}

# Kart içinde etiketli, satır kaydıran alan: tui_card_wrap "Etiket" "uzun metin"
tui_card_wrap() {
    local label="$1" text="$2" word line="" room prefix
    room=$((UI_W - 4 - 14))
    ui_padr "${U_MUTED}${label}${U_RST}" 14
    prefix="$REPLY"
    for word in $text; do
        if ((${#line} + ${#word} + 1 > room)) && [[ -n "$line" ]]; then
            ui_card_row "$prefix$line"
            printf -v prefix '%14s' ''
            line=""
        fi
        line+="${line:+ }$word"
    done
    ui_card_row "$prefix$line"
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

# Bileşen listesi öğeleri (kategori başlıklarıyla) -> TUI_ITEMS, TUI_ITEM_IDS
# İsteğe bağlı rozet fonksiyonu her bileşen için çağrılır: tui_component_items [FN]
tui_component_items() {
    local badge_fn="${1:-}" cat id extra
    TUI_ITEMS=() TUI_ITEM_IDS=()
    for cat in "${COMP_CATEGORIES[@]}"; do
        TUI_ITEMS+=("#${COMP_CAT_LABEL[$cat]}")
        for id in $(component_ids_by_cat "$cat"); do
            extra=""
            [[ -n "$badge_fn" ]] && extra="|$("$badge_fn" "$id")"
            TUI_ITEM_IDS+=("$id")
            TUI_ITEMS+=("${COMP_NAME[$id]}|${COMP_DESC[$id]}$extra")
        done
    done
}

# Kategorilere göre bileşen seçimi; sonuç TUI_PICKED
tui_pick_components() {
    local i
    tui_component_items ""
    ui_checklist "Kurulacak bileşenleri seçin" "" "${TUI_ITEMS[@]}" || return 1
    TUI_PICKED=()
    for i in "${UI_SELECTED[@]}"; do TUI_PICKED+=("${TUI_ITEM_IDS[i]}"); done
    ((${#TUI_PICKED[@]} > 0))
}
