#!/usr/bin/env bats
# Araçlar kişiliğe uyar: eza, bat, tmux, lazygit, btop (fzf: styles.bats)

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
    TS_CURRENT_COMPONENT=theme
    SNIP="$TS_CONFIG_DIR/zsh.d/65-theme-tools.zsh"
}

# Gerçek bir araç (sahte sistemin PATH'i dışında): real_tool AD -> REPLY
real_tool() {
    REPLY=$(PATH=/usr/bin:/bin:/usr/local/bin command -v "$1") || skip "gerçek $1 yok"
}

@test "kenar stili her araçta o aracın bildiği bir değere çevrilir" {
    local s
    for s in $(style_list); do
        style_load "$s"
        style_border_for fzf; in_list "$REPLY" rounded sharp bold double left
        style_border_for tmux; in_list "$REPLY" single heavy double
        style_border_for lazygit; in_list "$REPLY" rounded single double hidden
        style_border_for btop; in_list "$REPLY" True False
    done
    style_load arctic
    style_border_for lazygit; [ "$REPLY" = hidden ]
    style_load vivid
    style_border_for tmux; [ "$REPLY" = heavy ]
    run style_border_for olmayan-arac
    [ "$status" -ne 0 ]
}

@test "tırnağı bozan tarih biçimi ve bilinmeyen bat parçası reddedilir" {
    mkdir -p "$BATS_TEST_TMPDIR/root/styles"
    local r="$BATS_TEST_TMPDIR/root/styles"
    sed "s/^DATE_FORMAT=.*/DATE_FORMAT=\"+%H'%M\"/" "$REPO_ROOT/styles/modern.style" > "$r/tirnak.style"
    sed 's/^DATE_FORMAT=.*/DATE_FORMAT="%H:%M"/' "$REPO_ROOT/styles/modern.style" > "$r/arti.style"
    sed 's/^BAT_STYLE=.*/BAT_STYLE="numbers,dalgali"/' "$REPO_ROOT/styles/modern.style" > "$r/bat.style"
    sed 's/^BAT_STYLE=.*/BAT_STYLE=""/' "$REPO_ROOT/styles/modern.style" > "$r/bos.style"
    local s
    for s in tirnak arti bat bos; do
        TS_ROOT="$BATS_TEST_TMPDIR/root" run style_load "$s"
        [ "$status" -ne 0 ] || { echo "kabul edildi: $s"; false; }
    done
}

@test "eza ve bat: simge, tarih biçimi ve çerçeve kişilikten; soluk renk rolden" {
    theme_load one-dark
    rend_clitools_apply
    grep -qx "export BAT_STYLE='numbers,grid,header'" "$SNIP"
    grep -qx "TS_EZA_OPTS=(--icons=auto '--time-style=+%d.%m.%y %H:%M')" "$SNIP"
    local m
    m=$(theme_rgb "${ROLE[muted]}")
    grep -qx "export EZA_COLORS='da=38;2;$m:xx=38;2;$m'" "$SNIP"
    settings_set style retro
    theme_load one-dark
    rend_clitools_apply
    grep -qx "export BAT_STYLE='numbers'" "$SNIP"
    grep -qx "TS_EZA_OPTS=(--icons=never '--time-style=+%Y-%m-%d %H:%M')" "$SNIP"
}

@test "eza takma adları kişiliğin seçeneklerini zsh'te tek tek argüman olarak alır" {
    local zsh
    real_tool zsh; zsh="$REPLY"
    comp_eza_install
    settings_set style retro
    theme_load nord
    rend_clitools_apply
    # Tema yokken varsayılan, tema varken kişiliğin seçenekleri. Takma ad
    # ayrıştırılırken açılır: -c metni tek seferde ayrıştırıldığı için eval
    run "$zsh" -f -c "source '$TS_CONFIG_DIR/zsh.d/60-eza.zsh'; print -rl -- \"\${TS_EZA_OPTS[@]}\""
    [ "$output" = "--icons=auto" ]
    run "$zsh" -f -c "source '$TS_CONFIG_DIR/zsh.d/60-eza.zsh'; source '$SNIP'
        eza() { print -rl -- \"\$@\"; }; eval ll"
    [ "${lines[0]}" = "-l" ]
    [ "${lines[3]}" = "--icons=never" ]
    [ "${lines[4]}" = "--time-style=+%Y-%m-%d %H:%M" ]
}

@test "tmux: pencere etiketi, tarih, ayırıcı ve bölme çizgisi kişilikten" {
    theme_load one-dark; tmux_theme_conf
    [[ "$REPLY" == *'set -g pane-border-lines single'* ]]
    [[ "$REPLY" == *"set -g status-right \"#[fg=${ROLE[muted]}]· #[fg=${ROLE[fg]}]%d.%m.%y %H:%M \""* ]]
    [[ "$REPLY" == *"window-status-current-format \"#[fg=${ROLE[bg]},bg=${ROLE[accent]},bold] #I:#W #[default]\""* ]]
    theme_load gruvbox; tmux_theme_conf
    [[ "$REPLY" == *'[#I:#W]'* && "$REPLY" == *'%Y-%m-%d %H:%M'* ]]
    theme_load tokyo-night; tmux_theme_conf
    [[ "$REPLY" == *'set -g pane-border-lines double'* && "$REPLY" == *'▸ #I:#W'* ]]
    theme_load dracula; tmux_theme_conf
    [[ "$REPLY" == *'set -g pane-border-lines heavy'* && "$REPLY" == *"\\ue0b0"* ]]
    theme_load catppuccin; tmux_theme_conf
    [[ "$REPLY" == *"\\ue0b6"* && "$REPLY" == *"\\ue0b4"* ]]
    # Ham Nerd Font karakteri yok (U+E000–U+F8FF baytları: EE 80 80 – EF A3 BF)
    ! LC_ALL=C grep -q $'[\xee\xef]' <<< "$REPLY"
}

@test "tmux: ayırıcıdaki tırnak, \$, \\ ve # kaçırılır" {
    theme_load nord
    STYLE[SEPARATOR]='a"b$c\d#e'
    tmux_theme_conf
    [[ "$REPLY" == *'#[fg='"${ROLE[muted]}"']a\"b\$c\\d##e #[fg='* ]]
}

@test "tmux: üretilen ayar her kişilikte gerçek tmux'a hatasız yüklenir" {
    local tmux s t
    real_tool tmux; tmux="$REPLY"
    export TMUX_TMPDIR="$BATS_TEST_TMPDIR"
    for t in one-dark nord dracula gruvbox catppuccin tokyo-night; do
        theme_load "$t"
        tmux_theme_conf
        printf '%s\n' "$REPLY" > "$BATS_TEST_TMPDIR/theme.conf"
        run "$tmux" -L ts-test -f /dev/null new-session -d \; source-file "$BATS_TEST_TMPDIR/theme.conf" \; \
            show -gv window-status-current-format
        "$tmux" -L ts-test kill-server 2>/dev/null || true
        [ "$status" -eq 0 ] || { echo "$t: $output"; false; }
        [ -n "$output" ]
    done
    # Kaçış dizisi tmux'ta gerçek karaktere dönüşür
    theme_load dracula; tmux_theme_conf
    printf '%s\n' "$REPLY" > "$BATS_TEST_TMPDIR/theme.conf"
    run "$tmux" -L ts-test -f /dev/null new-session -d \; source-file "$BATS_TEST_TMPDIR/theme.conf" \; \
        show -gv window-status-current-format
    "$tmux" -L ts-test kill-server 2>/dev/null || true
    [[ "$output" == *$'\xee\x82\xb0'* ]]
}

@test "lazygit: kenar, simgeler ve renkler kişilikten ve rollerden" {
    theme_load one-dark; lazygit_theme_yml
    [[ "$REPLY" == *$'\n  border: rounded\n  nerdFontsVersion: "3"\n'* ]]
    [[ "$REPLY" == *"activeBorderColor: ['${ROLE[accent]}', bold]"* ]]
    [[ "$REPLY" == *"selectedLineBgColor: ['${ROLE[sel]}']"* ]]
    theme_load nord; lazygit_theme_yml
    [[ "$REPLY" == *'  border: hidden'* ]]
    theme_load gruvbox; lazygit_theme_yml
    [[ "$REPLY" == *$'  border: single\n  nerdFontsVersion: ""'* ]]
    theme_load tokyo-night; lazygit_theme_yml
    [[ "$REPLY" == *'  border: double'* ]]
}

# lazygit parçasını çalıştırıp LG_CONFIG_FILE'ı yazdır
lg_env() {
    "$ZSH" -f -c "$1"$'\n'"source '$TS_CONFIG_DIR/zsh.d/65-theme-lazygit.zsh'; print -r -- \"\${LG_CONFIG_FILE-UNSET}\""
}

@test "lazygit: tema dosyası kullanıcının ayarından önce verilir, kullanıcınınki üstün" {
    real_tool zsh; ZSH="$REPLY"
    local theme="$TS_CONFIG_DIR/lazygit.yml" user="$HOME/.config/lazygit/config.yml"
    theme_load nord
    rend_lazygit_apply
    run lg_env ""
    [ "$output" = "$theme" ]
    mkdir -p "${user%/*}" && touch "$user"
    run lg_env ""
    [ "$output" = "$theme,$user" ]
    # Kullanıcı kendi listesini vermişse dokunulmaz; bizim eski değerimiz yenilenir
    run lg_env "export LG_CONFIG_FILE=/kendi/ayarim.yml"
    [ "$output" = /kendi/ayarim.yml ]
    run lg_env "export LG_CONFIG_FILE='$theme'"
    [ "$output" = "$theme,$user" ]
    run lg_env "export XDG_CONFIG_HOME='$BATS_TEST_TMPDIR/xdg'"
    [ "$output" = "$theme" ]
    # Tema dosyası yoksa lazygit kendi hâlinde
    rm "$theme"
    run lg_env ""
    [ "$output" = UNSET ]
}

@test "lazygit: önceden kurulu lazygit'e de uygulanır; lazygit yoksa hiçbir şey yazılmaz" {
    mkdir -p "$TS_CONFIG_DIR" && touch "$TS_CONFIG_DIR/init.zsh"
    ! rend_lazygit_available
    printf '#!/bin/sh\n' > "$FAKE_ROOT/pkgbin/lazygit" && chmod +x "$FAKE_ROOT/pkgbin/lazygit"
    rend_lazygit_available
    theme_load kanagawa
    rend_lazygit_apply
    grep -q "Tema: Kanagawa" "$TS_CONFIG_DIR/lazygit.yml"
    grep -q "LG_CONFIG_FILE" "$TS_CONFIG_DIR/zsh.d/65-theme-lazygit.zsh"
    # Geri alınınca ikisi birlikte gider
    undo_component theme
    [ ! -e "$TS_CONFIG_DIR/lazygit.yml" ]
    [ ! -e "$TS_CONFIG_DIR/zsh.d/65-theme-lazygit.zsh" ]
}

@test "btop.conf oluşturulurken köşeler kişilikten: yuvarlak" {
    theme_load catppuccin
    rend_btop_apply
    grep -qx "rounded_corners = True" "$HOME/.config/btop/btop.conf"
}

@test "btop.conf oluşturulurken köşeler kişilikten: köşeli kişilik" {
    theme_load gruvbox
    rend_btop_apply
    grep -qx "rounded_corners = False" "$HOME/.config/btop/btop.conf"
}
