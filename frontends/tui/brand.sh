#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: logo, durum kartı ve öneri kartı
# ============================================================================
# Ana menüde büyük logo (hero), diğer ekranlarda tek satırlık başlık
# gösterilir. Durum bilgisi her tuşta değil yalnızca UI_HEADER_STALE=1
# iken okunur (ekran açılırken ve bir işlemden sonra); gezinme hızlı kalır.
# ============================================================================

# Yarım blok karakterlerle çizilmiş logo
_TUI_LOGO=(
    '▀▀█▀▀ █▀▀▀ █▀▀▄ █▄ ▄█ ▀█▀ █▄  █ ▄▀▀▄ █       ▄▀▀▀ █▀▀▀ ▀▀█▀▀ █  █ █▀▀▄'
    '  █   █▀▀  █▀█  █ ▀ █  █  █ ▀▄█ █▀▀█ █        ▀▀▄ █▀▀    █   █  █ █▀▀ '
    '  ▀   ▀▀▀▀ ▀  ▀ ▀   ▀ ▀▀▀ ▀   ▀ ▀  ▀ ▀▀▀▀    ▀▀▀  ▀▀▀▀   ▀    ▀▀  ▀   '
)
TUI_LOGO_W=70
TUI_HERO_ROWS=32      # büyük logo için gereken en az satır

# Önbellek: renk derinliği değişirse yeniden üretilir
_TUI_LOGO_CACHE=() _TUI_NAME_CACHE="" _TUI_CACHE_DEPTH=""

# Durum önbelleği
_TUI_ST_ZSH=off _TUI_ST_P10K=off _TUI_ST_THEME="" _TUI_ST_THEME_NAME=""
_TUI_ST_COUNT=0 _TUI_ST_BROKEN=0 _TUI_ST_PILLS=""

_tui_cache_art() {
    local line
    [[ "$_TUI_CACHE_DEPTH" == "$UI_COLOR_DEPTH" ]] && return 0
    _TUI_LOGO_CACHE=()
    for line in "${_TUI_LOGO[@]}"; do
        ui_gradient_text "$line" "$TUI_LOGO_W"
        _TUI_LOGO_CACHE+=("$REPLY")
    done
    ui_gradient_text "Terminal Setup"
    _TUI_NAME_CACHE="$REPLY"
    _TUI_CACHE_DEPTH="$UI_COLOR_DEPTH"
}

# Giriş kabuğu gerçekten zsh mi; zsh kurulu ama varsayılan değil mi
_tui_zsh_state() {
    local shell
    shell=$(sys_login_shell)
    if [[ "$shell" == */zsh ]]; then echo ok
    elif has_cmd zsh; then echo warn
    else echo off; fi
}

_tui_p10k_state() {
    case "$(component_state p10k)" in
        ours) echo ok ;;
        broken) echo err ;;
        *) [[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]] && echo info || echo off ;;
    esac
}

_tui_status_refresh() {
    local id pills
    ((UI_HEADER_STALE)) || return 0
    UI_HEADER_STALE=0
    _TUI_ST_ZSH=$(_tui_zsh_state)
    _TUI_ST_P10K=$(_tui_p10k_state)
    _TUI_ST_THEME=$(settings_get theme)
    _TUI_ST_THEME_NAME=""
    [[ -n "$_TUI_ST_THEME" ]] && _TUI_ST_THEME_NAME=$(theme_load "$_TUI_ST_THEME" >/dev/null 2>&1 && echo "${THEME[NAME]}")
    _TUI_ST_COUNT=$(ledger_count 2>/dev/null)
    [[ "$_TUI_ST_COUNT" =~ ^[0-9]+$ ]] || _TUI_ST_COUNT=0
    _TUI_ST_BROKEN=0
    if ((_TUI_ST_COUNT > 0)); then
        for id in "${COMP_IDS[@]}"; do
            [[ "$(component_state "$id")" == broken ]] && _TUI_ST_BROKEN=$((_TUI_ST_BROKEN + 1))
        done
    fi

    if [[ "$_TUI_ST_ZSH" == warn ]]; then ui_badge warn "Zsh (varsayılan değil)"; else ui_badge "$_TUI_ST_ZSH" "Zsh"; fi
    pills="$REPLY   "
    ui_badge "$_TUI_ST_P10K" "Powerlevel10k"
    pills+="$REPLY   "
    if [[ -n "$_TUI_ST_THEME_NAME" ]]; then ui_badge acc "Tema ${U_BOLD}${_TUI_ST_THEME_NAME}${U_RST}"
    else ui_badge off "${U_MUTED}Tema yok${U_RST}"; fi
    pills+="$REPLY   "
    if ((_TUI_ST_COUNT > 0)); then ui_badge info "${_TUI_ST_COUNT} kayıt"
    else ui_badge off "${U_MUTED}kayıt yok${U_RST}"; fi
    _TUI_ST_PILLS="$pills$REPLY"
}

# Uygulama başlığı (ui_menu her çizimde çağırır). tui_header HERO
tui_header() {
    local hero="${1:-0}" line
    _tui_status_refresh
    _tui_cache_art
    if ((hero && UI_W >= TUI_LOGO_W + 4 && UI_ROWS >= TUI_HERO_ROWS)); then
        ui_line ""
        for line in "${_TUI_LOGO_CACHE[@]}"; do ui_center "$line"; done
        ui_line ""
        ui_center "${U_MUTED}Terminalinizi güzelleştirir  ·  ${U_RST}${U_BOLD}her adımı geri alınabilir${U_RST}"
        ui_center "${U_FAINT}sürüm ${TS_VERSION}  ·  github.com/alibedirhan/Terminal-Setup${U_RST}"
        ui_line ""
        ui_card_top ""
        ui_card_row "$_TUI_ST_PILLS"
        ui_card_bottom
    else
        ui_line ""
        ui_line "${U_BOLD}${_TUI_NAME_CACHE}${U_RST} ${U_FAINT}${TS_VERSION}${U_RST}"
        # Durum rozetleri sığmıyorsa kelime ortasında kesilmesin, hiç gösterilmesin
        ui_vlen "$_TUI_ST_PILLS"
        ((UI_LEN <= UI_W)) && ui_line "$_TUI_ST_PILLS"
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
    if ((UI_LEN > UI_W - 4)); then
        # Dar ekranda kart yerine tek satır
        ui_line "${U_ACC}✦${U_RST} $msg"
        return 0
    fi
    ui_card_top "${U_ACC}✦${U_RST} Öneri"
    ui_card_row "$msg"
    ui_card_bottom
}
