#!/usr/bin/env bash
# ============================================================================
# Renderer: bat, delta ve fzf
# ============================================================================
# Tema değişince komut satırı araçları da aynı renklere geçer. Kullanıcının
# araç ayar dosyalarına dokunulmaz; her şey Terminal Setup'ın kendi zsh
# parçasında ortam değişkeniyle yapılır:
#   BAT_THEME          bat ve delta (delta, syntax-theme verilmezse bunu okur)
#   FZF_DEFAULT_OPTS   fzf renkleri doğrudan tema paletinden
# bat'ın yerleşik karşılığı olmayan temalarda "ansi" kullanılır; o da
# terminalin (yani temanın) 16 rengini kullanır.
# ============================================================================

renderer_register clitools "bat · delta · fzf" tool

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

rend_clitools_apply() {
    _clitools_fzf_colors
    act_zsh_snippet 65 theme-tools "export BAT_THEME='${THEME[BAT_THEME]:-ansi}'
export FZF_DEFAULT_OPTS=\"\${FZF_DEFAULT_OPTS:-} --color=$REPLY\""
}
