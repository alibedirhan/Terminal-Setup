#!/usr/bin/env bats
# Arayüz yapı taşları: metin ölçüsü, çizim, menü/liste davranışı, sorular

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

vwidth() { ui_vlen "$1"; echo "$UI_LEN"; }

# --- metin -------------------------------------------------------------------

@test "görünen genişlik renk kodlarını saymaz, Türkçe harfleri tek sayar" {
    colors_on
    [ "$(vwidth "${U_ACC}ğüşıöç${U_RST}")" -eq 6 ]
    [ "$(vwidth $'\033[38;2;1;2;3mab\033[48;5;12mc\033[0m')" -eq 3 ]
}

@test "ui_padr renkli metni görünen genişliğe tamamlar" {
    colors_on
    ui_padr "${U_OK}Çalış${U_RST}" 10
    [ "$(vwidth "$REPLY")" -eq 10 ]
}

@test "ui_trunc uzun metni üç noktayla kısaltır, kısayı değiştirmez" {
    ui_trunc "kısa" 10
    [ "$REPLY" = "kısa" ]
    ui_trunc "çok uzun bir açıklama" 8
    [ "$REPLY" = "çok uzu…" ]
    ui_trunc "metin" 0
    [ -z "$REPLY" ]
}

@test "ui_clip renk kodlarını koruyarak görünen genişlikte keser" {
    colors_on
    ui_clip "${U_ACC}abc${U_RST}${U_OK}defgh" 5
    [ "$(vwidth "$REPLY")" -eq 5 ]
    [[ "$REPLY" == *"$U_OK"* ]]
    [[ "$REPLY" == *$'\033[0m' ]]
    ui_clip "kısa" 10
    [ "$REPLY" = "kısa" ]
    # bozuk kaçış dizisi sonsuz döngüye sokmaz
    ui_clip $'ab\033[38' 10
    [ "$(vwidth "$REPLY")" -le 10 ]
}

@test "renk geçişi alt kabuk açmadan REPLY'ye yazar ve görünen metni korur" {
    colors_on
    ui_gradient_text "Terminal Setup"
    [ "$(vwidth "$REPLY")" -eq 14 ]
    [[ "$REPLY" == *$'\033[38;2;'* ]]
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

# --- çizim -------------------------------------------------------------------

card_demo() {
    ui_card_top "Özet"
    ui_card_row "${U_OK}●${U_RST} Değişiklik ğüşi"
    ui_card_row "$(printf 'çok uzun %.0s' {1..20})"
    ui_card_bottom
}

@test "kartın tüm satırları aynı genişlikte; uzun içerik kenarı kaydırmaz" {
    colors_on
    run card_demo
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 4 ]
    local line
    for line in "${lines[@]}"; do
        ui_vlen "$line"
        [ "$UI_LEN" -eq 84 ]
    done
}

@test "çerçeve yüksekliği aşarsa gövde kısalır, alt kısım korunur" {
    LINES=10
    local i
    ui_frame_begin
    for ((i = 0; i < 30; i++)); do ui_line "gövde $i"; done
    ui_frame_footer
    ui_line "tuşlar"
    ui_frame_end > /dev/null
    [ "${#UI_FRAME[@]}" -eq 10 ]
    [ "${UI_FRAME[0]}" = "gövde 0" ]
    [ "${UI_FRAME[9]}" = "tuşlar" ]
}

@test "çerçevede uzun satır terminal genişliğinde kesilir" {
    COLUMNS=30
    ui_frame_begin
    ui_line "$(printf 'x%.0s' {1..100})"
    ui_frame_end > /dev/null
    [ "$(vwidth "${UI_FRAME[0]}")" -eq 30 ]
}

@test "çerçeve çıktısı son satırdan sonra satır sonu yazmaz (ekran kaymaz)" {
    run bash -c 'source "$TS_ROOT/lib/core.sh"; ts_load >/dev/null; ui_frame_begin; ui_line a; ui_line b; ui_frame_end'
    [[ "$output" != *$'\n'*$'\n'* ]]
    [[ "$output" == *$'\033[J' ]]
}

# --- liste modeli ve davranış --------------------------------------------------

@test "menü ve liste satırları tam içerik genişliğinde" {
    colors_on
    ui_layout
    _ui_parse_items "Kurulum sihirbazı|Profil ve tema seçerek kur|✦" "fzf|Bulanık arama|$(status_symbol external)"
    _ui_row menu 1 20 0 0
    [ "$(vwidth "$REPLY")" -eq "$UI_W" ]
    _ui_row menu 0 20 0 0
    [ "$(vwidth "$REPLY")" -eq "$UI_W" ]
    _ui_row check 1 20 1 1
    [ "$(vwidth "$REPLY")" -eq "$UI_W" ]
    _ui_row check 0 20 0 1
    [ "$(vwidth "$REPLY")" -eq "$UI_W" ]
}

@test "uzun açıklama satırı taşırmaz" {
    ui_layout
    _ui_parse_items "Etiket|$(printf 'uzun%.0s' {1..40})"
    _ui_row menu 1 12 0 0
    [ "$(vwidth "$REPLY")" -eq "$UI_W" ]
}

@test "bölüm başlıkları seçilebilir öğe sayılmaz" {
    _ui_parse_items "#A" "bir|x" "#B" "iki|y" "üç|z"
    [ "$_UI_N" -eq 3 ]
    [ "${_UI_KIND[2]}" = section ]
    [ "${_UI_EXTRA[1]}" = "" ]
}

@test "menü tuşları: başa sarma, kısayol, vazgeçme" {
    local -a _UI_KIND _UI_LABEL _UI_DESC _UI_EXTRA
    local _UI_N _ui_pos=0
    _ui_parse_items "a|" "b|" "c|"
    _ui_menu_key up || true
    [ "$_ui_pos" -eq 2 ]
    _ui_menu_key down || true
    [ "$_ui_pos" -eq 0 ]
    _ui_menu_key end || true
    [ "$_ui_pos" -eq 2 ]
    run _ui_menu_key 9
    [ "$status" -eq 0 ]
    _ui_menu_key 2 || [ $? -eq 10 ]
    [ "$UI_CHOICE" -eq 1 ]
    run _ui_menu_key q
    [ "$status" -eq 11 ]
}

@test "liste tuşları: işaretle, hepsi, onayla" {
    local -a _UI_KIND _UI_LABEL _UI_DESC _UI_EXTRA _ui_checked=(0 0 0)
    local _UI_N _ui_pos=1
    _ui_parse_items "a|" "b|" "c|"
    _ui_check_key space
    [ "${_ui_checked[*]}" = "0 1 0" ]
    _ui_check_key a
    [ "${_ui_checked[*]}" = "1 1 1" ]
    _ui_check_key a
    [ "${_ui_checked[*]}" = "0 0 0" ]
    _ui_check_key x
    _ui_check_key enter || [ $? -eq 10 ]
    [ "${UI_SELECTED[*]}" = "1" ]
}

@test "düz menü bölüm başlıklarını atlar; seçim yalnızca öğeleri sayar" {
    ui_menu "Başlık" "#Kurulum" "Bir|a" "İki|b" "#Yönetim" "Üç|c" <<< "3" > "$BATS_TEST_TMPDIR/out"
    [ "$UI_CHOICE" -eq 2 ]
    grep -q " 3) Üç" "$BATS_TEST_TMPDIR/out"
    ! grep -q "Kurulum" "$BATS_TEST_TMPDIR/out"
}

@test "seçenekler (--subtitle) düz menüde başlık sanılmaz" {
    ui_menu --subtitle "alt" --hero "Başlık" "Bir|a" <<< "1" > "$BATS_TEST_TMPDIR/out"
    [ "$UI_CHOICE" -eq 0 ]
    grep -q "Başlık" "$BATS_TEST_TMPDIR/out"
}

@test "düz liste bölüm başlıklarını atlar" {
    ui_checklist "Seç" "" "#Kabuk" "zsh|a" "#Araçlar" "fzf|b" "bat|c" <<< "1 3" > /dev/null
    [ "${UI_SELECTED[*]}" = "0 2" ]
}

@test "ekran seçenekleri çağrıdan sonra sızmaz" {
    ui_is_tty() { return 0; }
    UI_DRAW_ONCE=1 UI_TERM_ACTIVE=1
    ui_menu --subtitle "geçici" --footer tui_hint --hero "Başlık" "a|" > /dev/null || true
    [ -z "$UI_SUBTITLE" ]
    [ -z "$UI_FOOTER_FN" ]
    [ "$UI_HERO" -eq 0 ]
}

# --- terminal ve sorular ----------------------------------------------------------

@test "terminal yokken oturum fonksiyonları zararsızdır" {
    ui_term_enter
    [ "$UI_TERM_ACTIVE" -eq 0 ]
    ui_term_suspend
    ui_term_resume
    ui_term_leave
    [ "$UI_TERM_ACTIVE" -eq 0 ]
}

@test "onay sorusu: varsayılan, evet, hayır, geçersiz girdi" {
    ui_confirm "Soru?" e <<< ""
    ! ui_confirm "Soru?" h <<< "" || false
    ui_confirm "Soru?" h <<< "evet"
    ! ui_confirm "Soru?" e <<< "h" || false
    ui_confirm "Soru?" h <<< $'belki\ne' > /dev/null
}

@test "yazarak onay yalnızca kelime tam yazılınca geçer" {
    ui_type_confirm "kaldır" <<< "kaldır" > /dev/null
    ! ui_type_confirm "kaldır" <<< "kaldir" > /dev/null || false
    ! ui_type_confirm "kaldır" < /dev/null > /dev/null
}

@test "sürüm karşılaştırması yalnızca daha yeni sürümü kabul eder" {
    version_newer 6.1.0 6.0.0
    version_newer 6.0.10 6.0.9
    ! version_newer 5.0.2 6.0.0 || false
    ! version_newer 6.0.0 6.0.0 || false
    ! version_newer "" 6.0.0 || false
    ! version_newer "<html>" 6.0.0
}
