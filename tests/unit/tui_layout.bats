#!/usr/bin/env bats
# Yerleşim sözleşmesi: her menü ekranı, her terminal boyutunda
#   - terminal yüksekliğini aşmaz (aşarsa çerçeve kayar ve bozulur),
#   - hiçbir satırı terminal genişliğini aşmaz (aşarsa alt satıra taşar),
#   - tuş ipuçlarını en alt satırda gösterir.
# Ekranlar gerçek giriş noktalarından, UI_DRAW_ONCE ile tek kare çizilir.

load '../helpers/common'

SIZES=("40x12" "60x20" "80x24" "100x32" "120x40" "200x60")

setup() {
    setup_fakesys
    load_lib
    # Terminal varmış gibi çiz; tuş okunmaz, terminal kipine dokunulmaz
    ui_is_tty() { return 0; }
    UI_TERM_ACTIVE=1 UI_DRAW_ONCE=1 UI_HEADER_FN=tui_header
    C_RESET=$'\033[0m' COLORTERM=truecolor
    ui_colors_init
}

# Pencere boyutu değişmiş gibi davran (WINCH sinyalinin yaptığı)
resize_to() {
    export COLUMNS=$1 LINES=$2
    _UI_SIZE_KNOWN=0
}

# Çerçevenin renk kodları ayıklanmış düz metni
frame_text() { printf '%s\n' "${UI_FRAME[@]}" | sed 's/\x1b\[[0-9;]*m//g'; }

# check_screen KOMUT... : her boyutta çiz ve sözleşmeyi denetle
check_screen() {
    local size line n
    for size in "${SIZES[@]}"; do
        resize_to "${size%x*}" "${size#*x}"
        UI_HEADER_STALE=1
        "$@" > /dev/null || true
        n=${#UI_FRAME[@]}
        if ((n == 0 || n > LINES)); then
            echo "$* @ $size: $n satır (sınır $LINES)"
            return 1
        fi
        for line in "${UI_FRAME[@]}"; do
            ui_vlen "$line"
            if ((UI_LEN > COLUMNS)); then
                echo "$* @ $size: $UI_LEN sütunluk satır (sınır $COLUMNS)"
                return 1
            fi
        done
        if [[ "${UI_FRAME[n - 1]}" != *"enter"* ]]; then
            echo "$* @ $size: son satırda tuş ipuçları yok: ${UI_FRAME[n - 1]}"
            return 1
        fi
    done
}

@test "ana menü (logo ve öneri kartıyla) her boyuta sığar" {
    check_screen tui_main_menu
}

@test "geniş ve uzun ekranda ana menü büyük logoyu gösterir" {
    resize_to 100 40
    tui_main_menu > /dev/null || true
    [[ "$(frame_text)" == *"▀▀█▀▀"* ]]
    resize_to 80 24
    tui_main_menu > /dev/null || true
    [[ "$(frame_text)" != *"▀▀█▀▀"* ]]
    [[ "$(frame_text)" == *"Terminal Setup"* ]]
}

@test "kurulum sihirbazı ilk adımı her boyuta sığar" {
    check_screen tui_install_wizard
}

@test "bileşen listesi her boyuta sığar ve küçük ekranda kayar" {
    check_screen tui_components
    resize_to 80 24
    tui_components > /dev/null || true
    [[ "$(frame_text)" == *"satır daha"* ]]
}

@test "tema tarayıcı her boyuta sığar" {
    check_screen tui_theme_browser
}

@test "tema tarayıcı yüksekliğe göre pencereyi ve paleti seçer" {
    resize_to 100 40
    tui_theme_browser > /dev/null || true
    [[ "$(frame_text)" == *"normal"* && "$(frame_text)" == *"git status"* ]]
    # en yaygın varsayılan boyutta pencere önizlemesi görünür
    resize_to 80 24
    tui_theme_browser > /dev/null || true
    [[ "$(frame_text)" == *"git status"* ]]
    resize_to 100 16
    tui_theme_browser > /dev/null || true
    [[ "$(frame_text)" == *"normal"* && "$(frame_text)" != *"git status"* ]]
}

@test "kaldırma ve ayarlar menüleri her boyuta sığar" {
    check_screen tui_uninstall
    check_screen tui_settings
}

@test "çizim kurulum ya da kaldırma yapmaz, dosya oluşturmaz" {
    check_screen tui_main_menu
    check_screen tui_components
    [ ! -e "$TS_STATE_DIR/ledger" ]
    [ ! -e "$TS_STATE_DIR/baseline" ]
}
