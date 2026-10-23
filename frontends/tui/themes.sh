#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü: tema tarayıcı
# ============================================================================
# Sol/sağ ok ile temalar arasında gezilir, renkler canlı önizlenir. Enter
# temayı gerçek terminale uygular; "r" görünümü kurulum öncesine döndürür.

tui_theme_browser() {
    local themes=() idx=0 n key current i
    mapfile -t themes < <(theme_list)
    n=${#themes[@]}
    current=$(settings_get theme)
    for ((i = 0; i < n; i++)); do [[ "${themes[i]}" == "$current" ]] && idx=$i; done

    if ! ui_is_tty; then
        ui_menu "Tema seçin" "${themes[@]}" || return 0
        runner_prepare_light && theme_apply "${themes[UI_CHOICE]}"
        return
    fi

    while true; do
        ui_clear
        tui_header
        ui_title "Tema dene  ($((idx + 1))/$n)"
        theme_preview "${themes[idx]}"
        [[ "${themes[idx]}" == "$(settings_get theme)" ]] && printf '  %s\n' "${C_GREEN}● Şu an uygulanan tema${C_RESET}"
        printf '\n%s\n' "${C_DIM} ←→ tema değiştir   enter uygula   r görünümü sıfırla   q geri${C_RESET}"
        key=$(_ui_read_key)
        case "$key" in
            left|up|h|k) idx=$(((idx - 1 + n) % n)) ;;
            right|down|l|j) idx=$(((idx + 1) % n)) ;;
            enter)
                printf '\n'
                runner_prepare_light && theme_apply "${themes[idx]}"
                ui_pause ;;
            r) printf '\n'; appearance_reset; ui_pause ;;
            q|esc|eof) return 0 ;;
        esac
    done
}
