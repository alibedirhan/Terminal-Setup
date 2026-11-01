#!/usr/bin/env bats
# Starship ayarı: temanın renk rollerinden ve kişiliğinden üretilir

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
}

# TOML geçerli mi? (python3 tomllib: 3.11+)
toml_ok() {
    local py
    py=$(PATH=/usr/bin:/bin command -v python3) || return 0
    "$py" -c 'import sys, tomllib; tomllib.loads(sys.stdin.read())' 2>/dev/null <<< "$1" && return 0
    "$py" -c 'import tomllib' 2>/dev/null || return 0   # eski python: denetlenemez
    return 1
}

@test "her kişilik için geçerli TOML üretilir; palet ve simge doğru" {
    local t
    for t in one-dark nord dracula gruvbox catppuccin tokyo-night; do
        theme_load "$t"
        starship_config
        toml_ok "$REPLY" || { echo "$t: TOML bozuk"; false; }
        [[ "$REPLY" == *'palette = "terminal_setup"'* ]]
        [[ "$REPLY" == *"accent = \"${ROLE[accent]}\""* && "$REPLY" == *"muted = \"${ROLE[muted]}\""* ]]
        [[ "$REPLY" == *"# Kişilik: ${STYLE[ID]}"* ]]
    done
}

@test "Nerd Font karakterleri ham değil, TOML kaçışı olarak yazılır" {
    local t
    for t in dracula catppuccin one-dark; do
        theme_load "$t"
        starship_config
        # Özel kullanım alanı (U+E000–U+F8FF) baytları: EE 80 80 – EF A3 BF
        ! LC_ALL=C grep -q $'[\xee\xef]' <<< "$REPLY" || false
        [[ "$REPLY" == *'symbol = "\ue0a0 "'* ]]
        [[ "$REPLY" != *'@PL@'* && "$REPLY" != *'@PILL_'* ]]
    done
    theme_load dracula; starship_config
    [[ "$REPLY" == *'[\ue0b0](fg:accent)'* ]]
    theme_load catppuccin; starship_config
    [[ "$REPLY" == *'[\ue0b6](fg:accent)'* && "$REPLY" == *'[\ue0b4](fg:accent)'* ]]
}

@test "kişilik prompt'un biçimini değiştirir" {
    theme_load nord; starship_config
    [[ "$REPLY" == *'success_symbol = "[›](bold ok)"'* ]]
    [[ "$(grep '^format' <<< "$REPLY")" != *'$line_break'* ]]   # arctic tek satır
    theme_load one-dark; starship_config
    [[ "$(grep '^format' <<< "$REPLY")" == *'$line_break$character'* ]]
    [[ "$REPLY" == *'[on](muted)'* ]]
    theme_load tokyo-night; starship_config
    [[ "$(grep '^format' <<< "$REPLY")" == *'[▸](accent2)'* ]]
}

@test "retro: \$ simgesi ve köşeli parantezler Starship için kaçırılır" {
    theme_load gruvbox
    starship_config
    toml_ok "$REPLY"
    [[ "$REPLY" == *'success_symbol = "[\\$](bold ok)"'* ]]
    [[ "$(grep '^format' <<< "$REPLY")" == 'format = "[\\[](fg)$directory[\\]](fg)'* ]]
    [[ "$REPLY" == *'modified = "*"'* ]]
}

@test "tema yokken renkler terminalin kendi renk adlarından gelir" {
    THEME=() ROLE=()
    style_load modern
    starship_config
    toml_ok "$REPLY"
    [[ "$REPLY" != *'palette ='* && "$REPLY" != *'[palettes'* ]]
    [[ "$REPLY" == *'success_symbol = "[❯](bold green)"'* && "$REPLY" == *'style = "bold blue"'* ]]
}

@test "kullanıcının seçtiği kişilik Starship'e de yansır" {
    settings_set style retro
    theme_load nord
    starship_config
    [[ "$REPLY" == *'# Kişilik: retro'* && "$REPLY" == *'[\\$](bold ok)'* ]]
    [[ "$REPLY" == *"bg = \"${ROLE[bg]}\""* ]]   # renkler yine Nord'dan
}
