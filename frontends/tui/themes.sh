#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: tema tarayıcı
# ============================================================================
# Sol/sağ ok ile temalar arasında gezilir, renkler canlı önizlenir. Enter
# temayı gerçek terminale uygular; "r" görünümü kurulum öncesine döndürür.
# Alçak ekranda (30 satırdan az) üst başlık atlanır; yine yetmezse önce
# palet, sonra pencere gizlenir.

# Menülerde tema simgesi: yüklü temanın vurgu renginde bir nokta
tui_theme_dot() {
    if ((UI_COLOR_DEPTH == 24)); then
        printf '\033[38;2;%sm●' "$(theme_rgb "${THEME[ACCENT]}")"
    else
        printf '●'
    fi
}

# Tema adları şerit halinde; seçili olan vurgulu -> REPLY
_tui_theme_chips() {
    local idx="$1" i out="" prev next
    shift
    local -a names=("$@")
    for ((i = 0; i < ${#names[@]}; i++)); do
        if ((i == idx)); then out+="${U_SEL}${U_BOLD} ${names[i]} ${U_RST} "
        else out+="${U_MUTED} ${names[i]} ${U_RST} "; fi
    done
    ui_vlen "$out"
    if ((UI_LEN + 8 > UI_W)); then
        # Sığmıyorsa yalnızca önceki, şimdiki ve sonraki tema
        prev=$(((idx - 1 + ${#names[@]}) % ${#names[@]})) next=$(((idx + 1) % ${#names[@]}))
        out="${U_MUTED} ${names[prev]} ${U_RST} ${U_SEL}${U_BOLD} ${names[idx]} ${U_RST} ${U_MUTED} ${names[next]} ${U_RST}"
    fi
    REPLY="${U_ACC}‹${U_RST} $out ${U_ACC}›${U_RST}"
}

tui_theme_browser() {
    local -a _tt_themes=()
    local _tt_idx=0 _tt_current i
    mapfile -t _tt_themes < <(theme_list)
    ((${#_tt_themes[@]})) || return 0
    _tt_current=$(settings_get theme)
    for ((i = 0; i < ${#_tt_themes[@]}; i++)); do [[ "${_tt_themes[i]}" == "$_tt_current" ]] && _tt_idx=$i; done

    if ! ui_is_tty; then
        ui_menu "Tema seçin" "${_tt_themes[@]}" || return 0
        runner_prepare_light && theme_apply "${_tt_themes[UI_CHOICE]}"
        return
    fi
    UI_HEADER_STALE=1
    ui_loop _tui_theme_draw _tui_theme_key
    return 0
}

# Çerçeveyi çiz (terminal okumaz; test edilebilir)
_tui_theme_draw() {
    ui_frame_begin
    theme_load "${_tt_themes[_tt_idx]}" >/dev/null
    _tui_theme_head
    ui_line ""
    # Kalan yükseklik: durum satırı (2) ve tuşlar (2) hariç
    _tui_theme_preview $((UI_ROWS - ${#UI_FRAME[@]} - 4))
    ui_line ""
    if [[ "${_tt_themes[_tt_idx]}" == "$_tt_current" ]]; then
        _t "Şu an uygulanan tema"
        ui_line "  ${U_OK}●${U_RST} $TR"
    else
        _t "Enter ile bu temayı terminalinize uygulayın."
        ui_line "  ${U_MUTED}${TR}${U_RST}"
    fi
    ui_line ""
    ui_frame_footer
    ui_keys "enter" "uygula" "←→" "tema" "r" "sıfırla" "q" "geri"
    ui_frame_end
}

# Başlık ve tema şeridi; alçak ekranda üst başlık atlanır
_tui_theme_head() {
    local count="${U_MUTED}$((_tt_idx + 1)) / ${#_tt_themes[@]}${U_RST}" title
    _t "Tema dene"
    title="${U_ACC}◆${U_RST} ${U_BOLD}${TR}${U_RST}  $count"
    if ((UI_ROWS >= 30)); then
        tui_header 0
        ui_line ""
        ui_line "$title"
    else
        ui_line ""
        _t "${THEME[DESC]:-}"
        ui_line "$title   ${U_BOLD}${THEME[NAME]}${U_RST}  ${U_MUTED}${TR}"
    fi
    ui_line ""
    _tui_theme_chips "$_tt_idx" "${_tt_themes[@]}"
    ui_line "  $REPLY"
    if ((UI_ROWS >= 30)); then
        ui_line ""
        theme_preview_title
    fi
}

# Pencere ve paletten sığanları çiz: _tui_theme_preview KALAN-SATIR
_tui_theme_preview() {
    local rows_left="$1" w sw
    w=$((UI_W - 4))
    ((w > 64)) && w=64
    sw=$(((UI_W - 12) / 8 - 1))
    ((sw > 6)) && sw=6
    ((sw < 2)) && sw=2
    if ((rows_left >= THEME_PREVIEW_WINDOW_ROWS + THEME_PREVIEW_PALETTE_ROWS + 1)); then
        theme_preview_window "$w"
        ui_line ""
        theme_preview_palette "$sw"
    elif ((rows_left >= THEME_PREVIEW_WINDOW_ROWS)); then
        theme_preview_window "$w"
    else
        theme_preview_palette "$sw"
    fi
}

_tui_theme_key() {
    local n=${#_tt_themes[@]}
    case "$1" in
        left|up|h|k) _tt_idx=$(((_tt_idx - 1 + n) % n)) ;;
        right|down|l|j|tab) _tt_idx=$(((_tt_idx + 1) % n)) ;;
        home|g) _tt_idx=0 ;;
        end|G) _tt_idx=$((n - 1)) ;;
        enter)
            tui_run tui_theme_apply "${_tt_themes[_tt_idx]}"
            _tt_current=$(settings_get theme) ;;
        r)
            tui_run appearance_reset
            _tt_current=$(settings_get theme) ;;
        q|esc|eof|backspace) return 11 ;;
    esac
    return 0
}

tui_theme_apply() {
    runner_prepare_light && theme_apply "$1"
}
