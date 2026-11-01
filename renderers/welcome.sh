#!/usr/bin/env bash
# ============================================================================
# Renderer: karşılama kartı
# ============================================================================
# Karşılama kartı bileşeni kuruluysa kartın biçimi kişilikten, renkleri
# rollerden üretilir (zsh.d/65-theme-welcome.zsh). Kartı çizen kod
# (zsh/welcome.zsh, 96-welcome parçası) bu dizideki değerleri okur; tema
# yokken kendi varsayılanlarıyla (terminalin 16 rengi) çizer.
#
# Kişilikten gelenler: BORDER (kenar), SEGMENTS (başlığın biçimi),
# TITLE_CASE ve TEXT_CASE, SEPARATOR, DATE_FORMAT, CARD_MARKS (uyarı, hata,
# kaldığınız yer işaretleri).
# ============================================================================

renderer_register welcome "karşılama kartı" tool

rend_welcome_available() {
    [[ -f "$TS_CONFIG_DIR/zsh.d/96-welcome.zsh" ]]
}

rend_welcome_apply() {
    welcome_theme_zsh
    act_zsh_snippet 65 theme-welcome "$REPLY"
}

# Rolün ön plan rengi zsh $'...' dizgesi olarak: _welcome_fg ROL [kalın] -> REPLY
_welcome_fg() {
    REPLY="\$'\\e[${2:+1;}38;2;$(theme_rgb "${ROLE[$1]}")m'"
}

# 65-theme-welcome.zsh içeriği -> REPLY (tema ve kişilik yüklü olmalı)
welcome_theme_zsh() {
    local frame title text muted warn err cmd tag tagend sep
    _welcome_fg border; frame="$REPLY"
    _welcome_fg accent 1; title="$REPLY"
    _welcome_fg fg; text="$REPLY"
    _welcome_fg muted; muted="$REPLY"
    _welcome_fg warn; warn="$REPLY"
    _welcome_fg err; err="$REPLY"
    _welcome_fg accent 1; cmd="$REPLY"
    _welcome_fg accent; tagend="$REPLY"
    tag="\$'\\e[1;38;2;$(theme_rgb "${ROLE[bg]}");48;2;$(theme_rgb "${ROLE[accent]}")m'"
    printf -v sep '%q' "${STYLE[SEPARATOR]}"
    REPLY="typeset -gA _ts_card=(
    border ${STYLE[BORDER]} seg ${STYLE[SEGMENTS]} tcase ${STYLE[TITLE_CASE]} xcase ${STYLE[TEXT_CASE]}
    marks '${STYLE[CARD_MARKS]}' sep $sep date '${STYLE[DATE_FORMAT]}'
    frame $frame title $title text $text muted $muted
    warn $warn err $err cmd $cmd tag $tag tagend $tagend
)"
}
