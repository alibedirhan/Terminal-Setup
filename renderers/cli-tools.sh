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

# fzf --color değeri: _clitools_fzf_colors -> REPLY
_clitools_fzf_colors() {
    REPLY="fg:${THEME[FOREGROUND]},bg:-1,hl:${THEME[COLOR4]},fg+:${THEME[FOREGROUND]}"
    REPLY+=",bg+:${THEME[SELECTION_BG]},hl+:${THEME[COLOR12]},info:${THEME[COLOR3]}"
    REPLY+=",prompt:${THEME[ACCENT]},pointer:${THEME[ACCENT]},marker:${THEME[COLOR2]}"
    REPLY+=",spinner:${THEME[ACCENT]},header:${THEME[COLOR8]},border:${THEME[BORDER]}"
}

rend_clitools_apply() {
    _clitools_fzf_colors
    act_zsh_snippet 65 theme-tools "export BAT_THEME='${THEME[BAT_THEME]:-ansi}'
export FZF_DEFAULT_OPTS=\"\${FZF_DEFAULT_OPTS:-} --color=$REPLY\""
}
