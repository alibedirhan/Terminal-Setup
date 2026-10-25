#!/usr/bin/env bash
# ============================================================================
# Renderer: btop
# ============================================================================
# Tema paletinden bir btop teması üretilir (~/.config/btop/themes/). btop.conf
# yoksa bu temayı seçen bir btop.conf oluşturulur; btop onu sonradan kendi
# ayarlarıyla doldurur, bu yüzden kullanıcı verisi sayılır ve kaldırırken
# arşive taşınır. Önceden var olan btop.conf'a dokunulmaz.
# ============================================================================

renderer_register btop "btop" tool

BTOP_THEME_FILE="$HOME/.config/btop/themes/terminal-setup.theme"
BTOP_CONF="$HOME/.config/btop/btop.conf"

rend_btop_available() {
    has_cmd btop
}

# btop tema dosyasının içeriği -> REPLY
_btop_theme() {
    local -A t=(
        [main_bg]=BACKGROUND [main_fg]=FOREGROUND [title]=FOREGROUND [hi_fg]=ACCENT
        [selected_bg]=SELECTION_BG [selected_fg]=SELECTION_FG [inactive_fg]=COLOR8
        [graph_text]=COLOR7 [meter_bg]=BORDER [proc_misc]=COLOR6 [div_line]=BORDER
        [cpu_box]=COLOR4 [mem_box]=COLOR2 [net_box]=COLOR5 [proc_box]=COLOR6
        [temp_start]=COLOR2 [temp_mid]=COLOR3 [temp_end]=COLOR1
        [cpu_start]=COLOR2 [cpu_mid]=COLOR3 [cpu_end]=COLOR1
        [free_start]=COLOR2 [free_mid]=COLOR2 [free_end]=COLOR10
        [cached_start]=COLOR4 [cached_mid]=COLOR4 [cached_end]=COLOR12
        [available_start]=COLOR6 [available_mid]=COLOR6 [available_end]=COLOR14
        [used_start]=COLOR3 [used_mid]=COLOR1 [used_end]=COLOR9
        [download_start]=COLOR4 [download_mid]=COLOR6 [download_end]=COLOR14
        [upload_start]=COLOR5 [upload_mid]=COLOR1 [upload_end]=COLOR9
        [process_start]=COLOR2 [process_mid]=COLOR3 [process_end]=COLOR1
    )
    local key
    REPLY="# Terminal Setup: ${THEME[NAME]}"
    for key in $(printf '%s\n' "${!t[@]}" | sort); do
        REPLY+=$'\n'"theme[$key]=\"${THEME[${t[$key]}]}\""
    done
}

rend_btop_apply() {
    _btop_theme
    act_write_file "$BTOP_THEME_FILE" "$REPLY" || return 1
    if [[ -e "$BTOP_CONF" ]] && ! ledger_has userdata "$BTOP_CONF"; then
        grep -qF "$BTOP_THEME_FILE" "$BTOP_CONF" 2>/dev/null ||
            log_info "btop ayarlarınız korunuyor; temayı btop'ta Options → color_theme → terminal-setup ile seçebilirsiniz."
        return 0
    fi
    act_seed_file "$BTOP_CONF" "color_theme = \"$BTOP_THEME_FILE\"
theme_background = True"
}
