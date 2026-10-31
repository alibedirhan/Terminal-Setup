#!/usr/bin/env bash
# ============================================================================
# Renderer: bat, delta, fzf ve eza
# ============================================================================
# Tema ya da kişilik değişince komut satırı araçları da aynı renge ve biçime
# geçer. Kullanıcının araç ayar dosyalarına dokunulmaz; her şey Terminal
# Setup'ın kendi zsh parçasında ortam değişkeniyle yapılır (bloktan sonra
# gelen kendi .zshrc satırlarınız bunları ezebilir):
#   BAT_THEME          bat ve delta (delta, syntax-theme verilmezse bunu okur)
#   BAT_STYLE          bat'ın çerçevesi kişilikten (cat takma adı sade kalır)
#   FZF_DEFAULT_OPTS   fzf renkleri rollerden; kenar, imleç, istem kişilikten
#   TS_EZA_OPTS        eza takma adlarına simge ve tarih biçimi (kişilik)
#   EZA_COLORS         eza'nın tarih ve noktalama rengi soluk rolden; eza'nın
#                      varsayılanı (koyu gri) çoğu temada okunmuyor
# bat'ın yerleşik karşılığı olmayan temalarda "ansi" kullanılır; o da
# terminalin (yani temanın) 16 rengini kullanır.
# ============================================================================

renderer_register clitools "bat · delta · fzf · eza" tool

# Parçalar ancak Terminal Setup'ın zsh başlangıcı (zsh bileşeni) varsa yüklenir
rend_clitools_available() {
    [[ -f "$TS_CONFIG_DIR/init.zsh" ]]
}

# fzf --color değeri, renk rollerinden (lib/palette.sh): _clitools_fzf_colors -> REPLY
_clitools_fzf_colors() {
    REPLY="fg:${ROLE[fg]},bg:-1,hl:${ROLE[accent]},fg+:${ROLE[sel_fg]}"
    REPLY+=",bg+:${ROLE[sel]},hl+:${ROLE[accent]},info:${ROLE[muted]}"
    REPLY+=",prompt:${ROLE[accent]},pointer:${ROLE[accent]},marker:${ROLE[ok]}"
    REPLY+=",spinner:${ROLE[accent]},header:${ROLE[muted]},border:${ROLE[border]}"
}

# eza seçenekleri (zsh dizisi) ve renkleri -> REPLY (iki satır)
_clitools_eza() {
    local icons=auto muted
    [[ "${STYLE[ICONS]}" == off ]] && icons=never
    muted=$(theme_rgb "${ROLE[muted]}")
    REPLY="TS_EZA_OPTS=(--icons=$icons '--time-style=${STYLE[DATE_FORMAT]}')
export EZA_COLORS='da=38;2;$muted:xx=38;2;$muted'"
}

rend_clitools_apply() {
    local colors fzf
    _clitools_fzf_colors; colors="$REPLY"
    # Kişilik: kenar, imleç ve istem simgesi. Çift tırnak içinde $ kaçırılır ($ simgeli retro)
    style_fzf_opts; fzf="${REPLY//\$/\\\$}"
    _clitools_eza
    act_zsh_snippet 65 theme-tools "export BAT_THEME='${THEME[BAT_THEME]:-ansi}'
export BAT_STYLE='${STYLE[BAT_STYLE]}'
export FZF_DEFAULT_OPTS=\"\${FZF_DEFAULT_OPTS:-} --color=$colors $fzf\"
$REPLY"
}
