#!/usr/bin/env bats
# Arayüz yapı taşları: genişlik hesabı, kartlar, menü satırları, kaydırma

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
    export COLUMNS=100 LINES=40
}

# Renkleri aç (testler NO_COLOR ile başlar)
colors_on() {
    C_RESET=$'\033[0m' COLORTERM=truecolor
    ui_colors_init
}

# Kaçış kodları ayıklanmış görünen genişlik
vwidth() { ui_vlen "$1"; echo "$UI_LEN"; }

@test "görünen genişlik renk kodlarını saymaz, Türkçe harfleri tek sayar" {
    colors_on
    [ "$(vwidth "${U_ACC}ğüşıöç${U_RST}")" -eq 6 ]
    [ "$(vwidth $'\033[38;2;1;2;3mab\033[48;5;12mc\033[0m')" -eq 3 ]
}

@test "ui_pad renkli metni görünen genişliğe göre doldurur" {
    colors_on
    [ "$(vwidth "$(ui_pad "${U_OK}Çalış${U_RST}" 10)")" -eq 10 ]
}

@test "ui_trunc uzun metni üç noktayla kısaltır, kısayı değiştirmez" {
    [ "$(ui_trunc "kısa" 10)" = "kısa" ]
    [ "$(ui_trunc "çok uzun bir açıklama" 8)" = "çok uzu…" ]
}

card_demo() {
    ui_card_top "Özet"
    ui_card_row "${U_OK}●${U_RST} Değişiklik ğüşi"
    ui_card_row ""
    ui_card_bottom
}

@test "kartın tüm satırları aynı genişlikte (renk ve Türkçe karakterle)" {
    colors_on
    run card_demo
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 4 ]
    local line w=""
    for line in "${lines[@]}"; do
        ui_vlen "$line"
        [ -z "$w" ] && w=$UI_LEN
        [ "$UI_LEN" -eq "$w" ]
    done
    # menü dışında kenar boşluğu yok; içerik genişliği 84
    [ "$w" -eq 84 ]
}

@test "menü ve liste satırları tam içerik genişliğinde" {
    colors_on
    ui_layout
    _ui_parse_items "Kurulum sihirbazı|Profil ve tema seçerek kur|✦" "fzf|Bulanık arama|$(status_symbol external)"
    [ "$(vwidth "$(_ui_row menu 1 20 0 0)")" -eq "$UI_W" ]
    [ "$(vwidth "$(_ui_row menu 0 20 0 0)")" -eq "$UI_W" ]
    [ "$(vwidth "$(_ui_row check 1 20 1 1)")" -eq "$UI_W" ]
    [ "$(vwidth "$(_ui_row check 0 20 0 1)")" -eq "$UI_W" ]
}

@test "uzun açıklama satırı taşırmaz" {
    ui_layout
    _ui_parse_items "Etiket|$(printf 'uzun%.0s' {1..40})"
    [ "$(vwidth "$(_ui_row menu 1 12 0 0)")" -eq "$UI_W" ]
}

@test "düz menü bölüm başlıklarını atlar; seçim yalnızca öğeleri sayar" {
    ui_menu "Başlık" "#Kurulum" "Bir|a" "İki|b" "#Yönetim" "Üç|c" <<< "3" > "$BATS_TEST_TMPDIR/out"
    [ "$UI_CHOICE" -eq 2 ]
    grep -q " 3) Üç" "$BATS_TEST_TMPDIR/out"
    ! grep -q "Kurulum" "$BATS_TEST_TMPDIR/out"
}

@test "düz liste bölüm başlıklarını atlar" {
    ui_checklist "Seç" "" "#Kabuk" "zsh|a" "#Araçlar" "fzf|b" "bat|c" <<< "1 3" > /dev/null
    [ "${UI_SELECTED[*]}" = "0 2" ]
}

@test "liste ekrana sığmazsa seçili satırı gösterecek şekilde kayar" {
    local items=() i
    for ((i = 0; i < 30; i++)); do items+=("Öğe$i|açıklama $i"); done
    _ui_parse_items "${items[@]}"
    LINES=16 run _ui_draw menu "Uzun liste" 25
    [[ "$output" == *"Öğe25"* ]]
    [[ "$output" != *"Öğe2 "* ]]
    [[ "$output" == *"satır daha"* ]]
}

@test "sürüm karşılaştırması yalnızca daha yeni sürümü kabul eder" {
    version_newer 6.1.0 6.0.0
    version_newer 6.0.10 6.0.9
    ! version_newer 5.0.2 6.0.0
    ! version_newer 6.0.0 6.0.0
    ! version_newer "" 6.0.0
    ! version_newer "<html>" 6.0.0
}

@test "renk derinliği terminale göre seçilir" {
    C_RESET=$'\033[0m'
    COLORTERM=truecolor ui_colors_init
    [ "$UI_COLOR_DEPTH" -eq 24 ]
    COLORTERM="" TERM=xterm-256color ui_colors_init
    [ "$UI_COLOR_DEPTH" -eq 256 ]
    COLORTERM="" TERM=xterm ui_colors_init
    [ "$UI_COLOR_DEPTH" -eq 8 ]
    C_RESET="" ui_colors_init
    [ "$UI_COLOR_DEPTH" -eq 0 ]
    [ -z "$U_ACC" ]
}
