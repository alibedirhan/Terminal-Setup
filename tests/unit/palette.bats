#!/usr/bin/env bats
# Renk rolleri: her temada okunabilirlik (WCAG 2 kontrastı) garanti edilir

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
}

# Kontrast oranı en az SINIR mı? (awk ile ondalık karşılaştırma)
at_least() {
    awk -v c="$(palette_contrast "$1" "$2")" -v m="$3" 'BEGIN { exit !(c >= m) }'
}

@test "kontrast oranı WCAG formülüyle hesaplanır" {
    [ "$(palette_contrast '#FFFFFF' '#000000')" = "21.00" ]
    [ "$(palette_contrast '#777777' '#777777')" = "1.00" ]
    [ "$(palette_contrast '#000000' '#FFFFFF')" = "21.00" ]
    # Bilinen değer: #767676 beyaz zeminde 4.54:1 (WCAG AA sınırının hemen üstü)
    [ "$(palette_contrast '#767676' '#FFFFFF')" = "4.54" ]
}

@test "renk karışımı uçlarda renklerin kendisidir" {
    [ "$(palette_mix '#000000' '#FFFFFF' 0)" = "#000000" ]
    [ "$(palette_mix '#000000' '#FFFFFF' 100)" = "#FFFFFF" ]
    [ "$(palette_mix '#000000' '#FFFFFF' 50)" = "#808080" ]
}

@test "her temada metin rolleri 4.5:1, renkli roller 3:1 sınırının üstünde" {
    local t r
    for t in $(theme_list); do
        theme_load "$t"
        at_least "${ROLE[fg]}" "${ROLE[bg]}" 4.5 || { echo "$t fg"; false; }
        at_least "${ROLE[muted]}" "${ROLE[bg]}" 4.5 || { echo "$t muted"; false; }
        at_least "${ROLE[sel_fg]}" "${ROLE[sel]}" 4.5 || { echo "$t sel"; false; }
        for r in accent accent2 info ok warn err; do
            at_least "${ROLE[$r]}" "${ROLE[bg]}" 3.0 || { echo "$t $r"; false; }
        done
    done
}

@test "soluk renk ön plandan daha az belirgindir (aynı renk değil)" {
    local t fg_c mu_c
    for t in $(theme_list); do
        theme_load "$t"
        fg_c=$(palette_contrast "${ROLE[fg]}" "${ROLE[bg]}")
        mu_c=$(palette_contrast "${ROLE[muted]}" "${ROLE[bg]}")
        awk -v f="$fg_c" -v m="$mu_c" 'BEGIN { exit !(m <= f) }' || { echo "$t"; false; }
    done
}

@test "temanın 16 rengi değişmez; roller ayrı tutulur" {
    local i want
    theme_load solarized
    for ((i = 0; i < 16; i++)); do
        want=$(sed -n "s/^COLOR$i=\"\(#[0-9A-Fa-f]*\)\"$/\1/p" "$REPO_ROOT/themes/solarized.theme")
        [ "${THEME[COLOR$i]}" = "$want" ]
    done
    # Solarized'ın COLOR8'i okunmaz (1.0:1); soluk rol ondan bağımsız hesaplanır
    [ "${ROLE[muted]}" != "${THEME[COLOR8]}" ]
    [[ "${ROLE[muted]}" =~ ^#[0-9A-F]{6}$ ]]
}

@test "araçlar rolleri kullanır: fzf başlığı ve btop pasif yazısı okunur" {
    theme_load nord
    _clitools_fzf_colors
    [[ "$REPLY" == *"header:${ROLE[muted]}"* && "$REPLY" == *"info:${ROLE[muted]}"* ]]
    # Nord'un COLOR8'i metin için kullanılmaz (yalnızca kenar rengi olabilir)
    [[ "$REPLY" != *"header:${THEME[COLOR8]}"* && "$REPLY" != *"info:${THEME[COLOR8]}"* ]]
    _btop_theme
    [[ "$REPLY" == *"theme[inactive_fg]=\"${ROLE[muted]}\""* ]]
}

@test "rol hesabı gawk eklentisi gerektirmez (mawk ile aynı sonuç)" {
    local mawk
    mawk=$(PATH=/usr/bin:/bin command -v mawk) || skip "mawk yok"
    theme_load catppuccin-latte
    local want="${ROLE[muted]} ${ROLE[warn]} ${ROLE[sel]}"
    mkdir -p "$BATS_TEST_TMPDIR/mawk"
    ln -s "$mawk" "$BATS_TEST_TMPDIR/mawk/awk"
    PATH="$BATS_TEST_TMPDIR/mawk:$PATH" theme_load catppuccin-latte
    [ "${ROLE[muted]} ${ROLE[warn]} ${ROLE[sel]}" = "$want" ]
}
