#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: tema tarayıcı
# ============================================================================
# Sol/sağ ok ile temalar arasında gezilir, renkler canlı önizlenir. Enter
# temayı gerçek terminale uygular; "r" görünümü kurulum öncesine döndürür.

# Menülerde tema simgesi: temanın vurgu renginde bir nokta
tui_theme_dots() {
    theme_load "$1" >/dev/null 2>&1 || { printf '●'; return; }
    if ((UI_COLOR_DEPTH == 24)); then
        printf '\033[38;2;%sm●' "$(theme_rgb "${THEME[ACCENT]}")"
    else
        printf '●'
    fi
}

# Tema adları şerit halinde; seçili olan vurgulu
_tui_theme_chips() {
    local idx="$1" i out="" chip
    shift
    for ((i = 1; i <= $#; i++)); do
        if ((i - 1 == idx)); then chip="${U_SEL}${U_BOLD} ${!i} ${U_RST}"
        else chip="${U_MUTED} ${!i} ${U_RST}"; fi
        out+="$chip "
    done
    ui_vlen "$out"
    if ((UI_LEN + 4 > UI_W)); then
        # Sığmıyorsa yalnızca önceki, şimdiki ve sonraki tema
        local prev=$(((idx - 1 + $#) % $#)) next=$(((idx + 1) % $#))
        prev=$((prev + 1)) next=$((next + 1)) i=$((idx + 1))
        out="${U_MUTED} ${!prev} ${U_RST} ${U_SEL}${U_BOLD} ${!i} ${U_RST} ${U_MUTED} ${!next} ${U_RST}"
    fi
    printf '%s‹%s %s %s›%s' "$U_ACC" "$U_RST" "$out" "$U_ACC" "$U_RST"
}

tui_theme_browser() {
    local themes=() idx=0 n current i
    mapfile -t themes < <(theme_list)
    n=${#themes[@]}
    current=$(settings_get theme)
    for ((i = 0; i < n; i++)); do [[ "${themes[i]}" == "$current" ]] && idx=$i; done

    if ! ui_is_tty; then
        ui_menu "Tema seçin" "${themes[@]}" || return 0
        runner_prepare_light && theme_apply "${themes[UI_CHOICE]}"
        return
    fi

    UI_HEADER_STALE=1
    _ui_cursor_hide
    while true; do
        ui_frame_begin
        tui_header
        ui_line ""
        ui_line "${U_ACC}◆${U_RST} ${U_BOLD}Tema dene${U_RST}  ${U_MUTED}$((idx + 1)) / $n${U_RST}"
        ui_line ""
        ui_line "  $(_tui_theme_chips "$idx" "${themes[@]}")"
        ui_line ""
        theme_preview "${themes[idx]}"
        ui_line ""
        if [[ "${themes[idx]}" == "$(settings_get theme)" ]]; then
            ui_line "  ${U_OK}●${U_RST} Şu an uygulanan tema"
        else
            ui_line "  ${U_MUTED}Enter ile bu temayı terminalinize uygulayın.${U_RST}"
        fi
        ui_line ""
        ui_keys "←→" "tema değiştir" "enter" "uygula" "r" "görünümü sıfırla" "q" "geri"
        ui_frame_end
        ui_read_key
        case "$UI_KEY" in
            left|up|h|k) idx=$(((idx - 1 + n) % n)) ;;
            right|down|l|j) idx=$(((idx + 1) % n)) ;;
            enter)
                printf '\n'
                _ui_cursor_show
                runner_prepare_light && theme_apply "${themes[idx]}"
                UI_HEADER_STALE=1
                ui_pause
                _ui_cursor_hide ;;
            r)
                printf '\n'
                _ui_cursor_show
                appearance_reset
                UI_HEADER_STALE=1
                ui_pause
                _ui_cursor_hide ;;
            q|esc|eof) _ui_cursor_show; return 0 ;;
        esac
    done
}
