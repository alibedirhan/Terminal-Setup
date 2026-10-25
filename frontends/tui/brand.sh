#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: logo, durum kartı ve öneri kartı
# ============================================================================
# Ana menüde büyük logo, diğer ekranlarda tek satırlık başlık gösterilir.
# Durum bilgisi her tuşta değil, yalnızca menü açılırken okunur
# (UI_HEADER_STALE); böylece gezinme hızlı kalır.
# ============================================================================

TUI_BIG_HEADER=0

# Yarım blok karakterlerle çizilmiş logo (70 sütun)
_TUI_LOGO=(
    '▀▀█▀▀ █▀▀▀ █▀▀▄ █▄ ▄█ ▀█▀ █▄  █ ▄▀▀▄ █       ▄▀▀▀ █▀▀▀ ▀▀█▀▀ █  █ █▀▀▄'
    '  █   █▀▀  █▀█  █ ▀ █  █  █ ▀▄█ █▀▀█ █        ▀▀▄ █▀▀    █   █  █ █▀▀ '
    '  ▀   ▀▀▀▀ ▀  ▀ ▀   ▀ ▀▀▀ ▀   ▀ ▀  ▀ ▀▀▀▀    ▀▀▀  ▀▀▀▀   ▀    ▀▀  ▀   '
)
_TUI_LOGO_CACHE=()
_TUI_LOGO_DEPTH=""

# Durum önbelleği
_TUI_ST_ZSH="" _TUI_ST_P10K="" _TUI_ST_THEME="" _TUI_ST_COUNT=0 _TUI_ST_BROKEN=0 _TUI_ST_OURS=0

_tui_status_refresh() {
    local id state shell
    ((UI_HEADER_STALE)) || return 0
    UI_HEADER_STALE=0
    shell=$(sys_login_shell)
    if [[ "$shell" == */zsh ]]; then _TUI_ST_ZSH=ok
    elif has_cmd zsh; then _TUI_ST_ZSH=warn
    else _TUI_ST_ZSH=off; fi
    case "$(component_state p10k)" in
        ours) _TUI_ST_P10K=ok ;;
        external) _TUI_ST_P10K=info ;;
        broken) _TUI_ST_P10K=err ;;
        *) [[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]] && _TUI_ST_P10K=info || _TUI_ST_P10K=off ;;
    esac
    _TUI_ST_THEME=$(settings_get theme)
    _TUI_ST_COUNT=$(ledger_count 2>/dev/null || echo 0)
    _TUI_ST_BROKEN=0 _TUI_ST_OURS=0
    if ((_TUI_ST_COUNT > 0)); then
        for id in "${COMP_IDS[@]}"; do
            state=$(component_state "$id")
            [[ "$state" == broken ]] && _TUI_ST_BROKEN=$((_TUI_ST_BROKEN + 1))
            [[ "$state" == ours ]] && _TUI_ST_OURS=$((_TUI_ST_OURS + 1))
        done
    fi
}

# Logoyu renk geçişiyle bir kez boya, sonra önbellekten kullan
_tui_logo_lines() {
    local line
    if [[ "$_TUI_LOGO_DEPTH" != "$UI_COLOR_DEPTH" ]]; then
        _TUI_LOGO_CACHE=()
        for line in "${_TUI_LOGO[@]}"; do
            _TUI_LOGO_CACHE+=("$(ui_gradient_text "$line" 70)")
        done
        _TUI_LOGO_DEPTH="$UI_COLOR_DEPTH"
    fi
}

# Ortalanmış satır: _tui_center "metin"
_tui_center() {
    local n
    ui_vlen "$1"
    n=$(((UI_W - UI_LEN) / 2))
    ((n < 0)) && n=0
    ui_line "$(printf '%*s' "$n" '')$1"
}

_tui_status_pills() {
    local zsh_label="Zsh" p10k_label="Powerlevel10k" theme_badge count_badge name
    [[ "$_TUI_ST_ZSH" == warn ]] && zsh_label="Zsh (varsayılan değil)"
    if [[ -n "$_TUI_ST_THEME" ]] && theme_load "$_TUI_ST_THEME" >/dev/null 2>&1; then
        name="${THEME[NAME]}"
        theme_badge=$(ui_badge acc "Tema ${U_BOLD}${name}${U_RST}")
    else
        theme_badge=$(ui_badge off "${U_MUTED}Tema yok${U_RST}")
    fi
    if ((_TUI_ST_COUNT > 0)); then
        count_badge=$(ui_badge info "${_TUI_ST_COUNT} kayıt")
    else
        count_badge=$(ui_badge off "${U_MUTED}kayıt yok${U_RST}")
    fi
    printf '%s   %s   %s   %s' "$(ui_badge "$_TUI_ST_ZSH" "$zsh_label")" \
        "$(ui_badge "$_TUI_ST_P10K" "$p10k_label")" "$theme_badge" "$count_badge"
}

# Her menü çiziminde üstte görünen başlık (ağa çıkmaz)
tui_header() {
    local line pills name
    _tui_status_refresh
    pills=$(_tui_status_pills)
    if ((TUI_BIG_HEADER && UI_COLS >= 78 && UI_ROWS >= 32)); then
        _tui_logo_lines
        ui_line ""
        for line in "${_TUI_LOGO_CACHE[@]}"; do _tui_center "$line"; done
        ui_line ""
        _tui_center "${U_MUTED}Terminalinizi güzelleştirir  ·  ${U_RST}${U_BOLD}her adımı geri alınabilir${U_RST}"
        _tui_center "${U_FAINT}sürüm ${TS_VERSION}  ·  $(sys_os)  ·  github.com/alibedirhan/Terminal-Setup${U_RST}"
        ui_line ""
        ui_card_top ""
        ui_card_row "$pills"
        ui_card_bottom
    else
        name="$(ui_gradient_text "Terminal Setup")"
        line="${U_BOLD}${name}${U_RST} ${U_FAINT}${TS_VERSION}${U_RST}"
        ui_line ""
        ui_line "$line"
        ui_vlen "$pills"
        if ((UI_LEN <= UI_W)); then ui_line "$pills"; fi
        ui_rule
    fi
}

# Ana menünün altındaki öneri kartı
tui_hint() {
    local msg
    _tui_status_refresh
    if ((_TUI_ST_COUNT == 0)); then
        msg="İlk kez mi? ${U_BOLD}Kurulum sihirbazı${U_RST} ile başlayın; her adım geri alınabilir."
    elif ((_TUI_ST_BROKEN > 0)); then
        msg="${U_WARN}${_TUI_ST_BROKEN} bileşen bozuk görünüyor.${U_RST} ${U_BOLD}Durum ve teşhis${U_RST} ekranına bakın."
    elif [[ -z "$_TUI_ST_THEME" ]]; then
        msg="Kurulum tamam. ${U_BOLD}Tema dene${U_RST} ile 7 renk temasını canlı önizleyin."
    else
        msg="Her şey yolunda. Beğenmezseniz ${U_BOLD}Kaldır${U_RST} her şeyi geri alır."
    fi
    ui_vlen "$msg"
    if ((UI_LEN > UI_W - 6)); then
        # Dar ekranda kart yerine tek satır
        ui_line "${U_ACC}✦${U_RST} $msg"
        return 0
    fi
    ui_card_top "${U_ACC}✦${U_RST} Öneri"
    ui_card_row "$msg"
    ui_card_bottom
}
