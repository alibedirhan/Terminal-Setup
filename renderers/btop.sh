#!/usr/bin/env bash
# ============================================================================
# Renderer: btop
# ============================================================================
# Tema paletinden bir btop teması üretilir (~/.config/btop/themes/). btop.conf
# yoksa bu temayı seçen bir btop.conf oluşturulur; btop onu sonradan kendi
# ayarlarıyla doldurur, bu yüzden kullanıcı verisi sayılır ve kaldırırken
# arşive taşınır. Önceden var olan btop.conf'a dokunulmaz.
# Kişilikten yalnızca köşe biçimi gelir (rounded_corners) ve yalnızca
# btop.conf oluşturulurken yazılır: btop ayarı kendi menüsünden değiştirilir.
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
        [main_bg]=BACKGROUND [main_fg]=FOREGROUND [title]=FOREGROUND [hi_fg]=role:accent
        [selected_bg]=role:sel [selected_fg]=role:sel_fg [inactive_fg]=role:muted
        [graph_text]=role:muted [meter_bg]=BORDER [proc_misc]=role:info [div_line]=BORDER
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
    local key src color
    REPLY="# Terminal Setup: ${THEME[NAME]}"
    for key in $(printf '%s\n' "${!t[@]}" | sort); do
        src="${t[$key]}"
        if [[ "$src" == role:* ]]; then color="${ROLE[${src#role:}]}"; else color="${THEME[$src]}"; fi
        REPLY+=$'\n'"theme[$key]=\"$color\""
    done
}

rend_btop_apply() {
    _btop_theme
    act_write_file "$BTOP_THEME_FILE" "$REPLY" || return 1
    # Var olan btop.conf'a dokunulmaz (bizim oluşturduğumuz da btop'un
    # kendisinin ya da kullanıcının yazdığı da)
    if [[ -e "$BTOP_CONF" ]]; then
        grep -qF "$BTOP_THEME_FILE" "$BTOP_CONF" 2>/dev/null ||
            log_info "btop ayarlarınız korunuyor; temayı btop'ta Options → color_theme → terminal-setup ile seçebilirsiniz."
        return 0
    fi
    style_border_for btop
    act_seed_file "$BTOP_CONF" "color_theme = \"$BTOP_THEME_FILE\"
theme_background = True
rounded_corners = $REPLY"
}
