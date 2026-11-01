#!/usr/bin/env bash
# ============================================================================
# Renderer: lazygit
# ============================================================================
# lazygit kuruluysa (script kurmuş olsun ya da olmasın) kenar stili, simgeler
# ve renkler temadan ve kişilikten üretilir (~/.config/terminal-setup/
# lazygit.yml). Kullanıcının ~/.config/lazygit/config.yml dosyasına
# dokunulmaz: zsh parçası LG_CONFIG_FILE'a önce bu dosyayı, varsa ardından
# kullanıcınınkini yazar; lazygit sonra gelen dosyayı üstün tutar, yani
# kullanıcının ayarı kazanır. Birden çok dosya lazygit 0.30'dan (2021) beri
# desteklenir.
#
# Kişilikten gelenler: BORDER (style_border_for lazygit), ICONS (Nerd Font
# dosya simgeleri). Renkler rollerden.
# ============================================================================

renderer_register lazygit "lazygit" tool

LAZYGIT_THEME_FILE="$TS_CONFIG_DIR/lazygit.yml"

# Ortam değişkeni Terminal Setup'ın zsh başlangıcından verilir
rend_lazygit_available() {
    has_cmd lazygit && [[ -f "$TS_CONFIG_DIR/init.zsh" ]]
}

rend_lazygit_apply() {
    lazygit_theme_yml
    act_write_file "$LAZYGIT_THEME_FILE" "$REPLY" || return 1
    _lazygit_env
    act_zsh_snippet 65 theme-lazygit "$REPLY"
}

# lazygit.yml içeriği -> REPLY (tema ve kişilik yüklü olmalı)
lazygit_theme_yml() {
    local icons='""' border
    [[ "${STYLE[ICONS]}" == on ]] && icons='"3"'
    style_border_for lazygit; border="$REPLY"
    style_file_header
    REPLY="$REPLY
# Kendi ayarlarınız için ~/.config/lazygit/config.yml (o dosya bunun önüne geçer).
gui:
  border: $border
  nerdFontsVersion: $icons
  theme:
    activeBorderColor: ['${ROLE[accent]}', bold]
    inactiveBorderColor: ['${ROLE[border]}']
    searchingActiveBorderColor: ['${ROLE[warn]}', bold]
    optionsTextColor: ['${ROLE[info]}']
    selectedLineBgColor: ['${ROLE[sel]}']
    inactiveViewSelectedLineBgColor: ['${ROLE[sel]}']
    cherryPickedCommitFgColor: ['${ROLE[accent2]}']
    cherryPickedCommitBgColor: ['${ROLE[sel]}']
    markedBaseCommitFgColor: ['${ROLE[info]}']
    markedBaseCommitBgColor: ['${ROLE[sel]}']
    unstagedChangesColor: ['${ROLE[err]}']
    defaultFgColor: ['${ROLE[fg]}']"
}

# zsh parçası -> REPLY. lazygit LG_CONFIG_FILE'daki her dosyanın var olmasını
# ister, bu yüzden kullanıcının dosyası yalnızca varsa eklenir (lazygit'in
# baktığı yerler: CONFIG_DIR, XDG, eski jesseduffield klasörü). Kullanıcı
# LG_CONFIG_FILE'ı kendisi vermişse dokunulmaz; bizim eski değerimiz yenilenir.
_lazygit_env() {
    local file
    printf -v file '%q' "$LAZYGIT_THEME_FILE"
    REPLY="() {
    local ts=$file user
    [[ -r \$ts ]] || return 0
    [[ -n \${LG_CONFIG_FILE:-} && \$LG_CONFIG_FILE != \"\$ts\"* ]] && return 0
    for user in \"\${CONFIG_DIR:-\${XDG_CONFIG_HOME:-\$HOME/.config}/lazygit}/config.yml\" \\
        \"\${XDG_CONFIG_HOME:-\$HOME/.config}/jesseduffield/lazygit/config.yml\"; do
        [[ -f \$user ]] && break
        user=
    done
    export LG_CONFIG_FILE=\$ts\${user:+,\$user}
}"
}
