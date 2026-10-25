#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Arayüz: renk paleti
# ============================================================================
# Terminal 24 bit renk destekliyorsa (COLORTERM=truecolor) gerçek renk,
# 256 renkte en yakın tonlar, aksi halde 8 temel renk kullanılır. NO_COLOR
# tanımlıysa ya da çıktı terminal değilse (C_RESET boş) hiç renk yoktur.
#
# Ekranlar renk kodu yazmaz, buradaki anlamlı adları kullanır:
#   U_ACC vurgu  U_ACC2 ikincil vurgu  U_MUTED soluk metin  U_FAINT çizgiler
#   U_OK U_WARN U_ERR U_INFO durumlar  U_SEL seçili satır  U_CAP tuş etiketi
# ============================================================================

UI_COLOR_DEPTH=0      # 0 renksiz, 8, 256, 24

ui_colors_init() {
    U_RST="" U_BOLD="" U_ACC="" U_ACC2="" U_PINK="" U_MUTED="" U_FAINT=""
    U_OK="" U_WARN="" U_ERR="" U_INFO="" U_SEL="" U_CAP=""
    UI_COLOR_DEPTH=0
    [[ -n "$C_RESET" ]] || return 0
    U_RST=$'\033[0m' U_BOLD=$'\033[1m'
    if [[ "${COLORTERM:-}" == truecolor || "${COLORTERM:-}" == 24bit ]]; then
        UI_COLOR_DEPTH=24
        U_ACC=$'\033[38;2;167;139;250m'    # menekşe
        U_ACC2=$'\033[38;2;103;232;249m'   # camgöbeği
        U_PINK=$'\033[38;2;244;114;182m'
        U_MUTED=$'\033[38;2;128;134;155m'
        U_FAINT=$'\033[38;2;76;80;99m'
        U_OK=$'\033[38;2;74;222;128m'
        U_WARN=$'\033[38;2;251;191;36m'
        U_ERR=$'\033[38;2;248;113;113m'
        U_INFO=$'\033[38;2;96;165;250m'
        U_SEL=$'\033[48;2;46;43;72m\033[38;2;237;235;255m'
        U_CAP=$'\033[48;2;55;58;78m\033[38;2;220;222;235m'
    elif [[ "${TERM:-}" == *256color* ]]; then
        UI_COLOR_DEPTH=256
        U_ACC=$'\033[38;5;141m' U_ACC2=$'\033[38;5;117m' U_PINK=$'\033[38;5;211m'
        U_MUTED=$'\033[38;5;245m' U_FAINT=$'\033[38;5;239m'
        U_OK=$'\033[38;5;78m' U_WARN=$'\033[38;5;214m' U_ERR=$'\033[38;5;203m' U_INFO=$'\033[38;5;75m'
        U_SEL=$'\033[48;5;237m\033[38;5;255m'
        U_CAP=$'\033[48;5;238m\033[38;5;253m'
    else
        UI_COLOR_DEPTH=8
        U_ACC=$'\033[35m' U_ACC2=$'\033[36m' U_PINK=$'\033[35m'
        U_MUTED=$'\033[2m' U_FAINT=$'\033[2m'
        U_OK=$'\033[32m' U_WARN=$'\033[33m' U_ERR=$'\033[31m' U_INFO=$'\033[34m'
        U_SEL=$'\033[7m' U_CAP=$'\033[7m'
    fi
}
ui_colors_init

# Renk geçişi (camgöbeği -> menekşe -> pembe) üzerindeki bir noktanın ön plan
# kodu -> REPLY. ui_gradient_code KONUM TOPLAM
_UI_GRAD_256=(117 117 111 147 141 141 177 213 211 211)
ui_gradient_code() {
    local pos="$1" total="$2" t r g b
    REPLY=""
    ((total < 2)) && total=2
    case "$UI_COLOR_DEPTH" in
        24)
            t=$((pos * 1000 / (total - 1)))
            if ((t < 500)); then
                r=$((103 + 64 * t / 500)) g=$((232 - 93 * t / 500)) b=$((249 + t / 500))
            else
                t=$((t - 500))
                r=$((167 + 77 * t / 500)) g=$((139 - 25 * t / 500)) b=$((250 - 68 * t / 500))
            fi
            printf -v REPLY '\033[38;2;%d;%d;%dm' "$r" "$g" "$b" ;;
        256) printf -v REPLY '\033[38;5;%dm' "${_UI_GRAD_256[pos * 10 / total]:-211}" ;;
        8) REPLY="$U_ACC2" ;;
    esac
}

# Metni harf harf renk geçişiyle boya -> REPLY. ui_gradient_text METİN [TOPLAM]
ui_gradient_text() {
    local s="$1" total="${2:-${#1}}" i out="" ch
    if ((UI_COLOR_DEPTH == 0)); then REPLY="$s"; return; fi
    for ((i = 0; i < ${#s}; i++)); do
        ch="${s:i:1}"
        if [[ "$ch" == " " ]]; then
            out+=" "
        else
            ui_gradient_code "$i" "$total"
            out+="$REPLY$ch"
        fi
    done
    REPLY="$out$U_RST"
}
