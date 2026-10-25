#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Arayüz: çizim
# ============================================================================
# İki kip vardır:
#   Satır kipi    (varsayılan) ui_line doğrudan yazar. Komut satırı çıktısı,
#                 durum ve teşhis ekranları böyle çizilir.
#   Çerçeve kipi  ui_frame_begin ... ui_frame_end arası. Satırlar UI_FRAME
#                 dizisinde toplanır ve tek seferde yazılır; ekran silinip
#                 yeniden çizilmediği için titreme olmaz.
#
# Çerçeve sözleşmesi (testlerle denetlenir):
#   - Hiçbir satır terminal genişliğini aşmaz (renk kodları korunarak kesilir).
#   - Çerçeve terminal yüksekliğini aşmaz. Aşarsa gövde kısaltılır;
#     ui_frame_footer ile işaretlenen alt kısım (tuş ipuçları) hep görünür.
# ============================================================================

UI_W=80               # içerik genişliği
UI_M=""               # sol boşluk (menülerde içerik ortalanır)
UI_FRAME=()           # çerçeve satırları
UI_FRAMING=0          # çerçeve kipinde mi
_UI_FOOT_AT=-1        # alt kısmın başladığı satır

# Ölçüleri güncelle. Menü oturumunda içerik ortalanır, aksi halde sola yaslanır.
ui_layout() {
    ui_term_size
    UI_W=$((UI_COLS - 4))
    ((UI_W > 84)) && UI_W=84
    ((UI_W < 36)) && UI_W=$((UI_COLS > 36 ? 36 : UI_COLS))
    if ((UI_TERM_ACTIVE && UI_COLS > UI_W)); then
        printf -v UI_M '%*s' $(((UI_COLS - UI_W) / 2)) ''
    else
        UI_M=""
    fi
}

ui_width() { ui_layout; echo "$UI_W"; }

ui_line() {
    if ((UI_FRAMING)); then
        ui_clip "${UI_M}$1" "$UI_COLS"
        UI_FRAME+=("$REPLY$U_RST")
    else
        printf '%s%s%s\n' "$UI_M" "$1" "$U_RST"
    fi
}

ui_frame_begin() {
    ui_layout
    UI_FRAME=() UI_FRAMING=1 _UI_FOOT_AT=-1
}

# Bundan sonraki satırlar alt kısımdır; çerçeve sığmazsa kesilmez.
ui_frame_footer() { _UI_FOOT_AT=${#UI_FRAME[@]}; }

# Çerçeveyi sığdır ve yaz. Son satırdan sonra satır sonu yazılmaz; yazılsa
# en alt satırda ekran bir satır kayardı.
ui_frame_end() {
    local -a out=()
    local foot=0 keep i buf
    UI_FRAMING=0
    ((_UI_FOOT_AT >= 0)) && foot=$((${#UI_FRAME[@]} - _UI_FOOT_AT))
    if ((${#UI_FRAME[@]} > UI_ROWS)); then
        keep=$((UI_ROWS - foot))
        ((keep < 0)) && keep=0
        out=("${UI_FRAME[@]:0:keep}")
        ((foot > 0)) && out+=("${UI_FRAME[@]:${#UI_FRAME[@]}-foot:UI_ROWS-keep}")
    else
        out=("${UI_FRAME[@]}")
    fi
    UI_FRAME=("${out[@]}")
    buf=$'\033[H'
    ((UI_RESIZED)) && buf=$'\033[H\033[2J' && UI_RESIZED=0
    for ((i = 0; i < ${#out[@]}; i++)); do
        ((i > 0)) && buf+=$'\n'
        buf+="${out[i]}"$'\033[K'
    done
    printf '%s\033[J' "$buf"
}

ui_clear() { ui_is_tty && printf '\033[H\033[2J'; return 0; }

# ----------------------------------------------------------------------------
# Yapı taşları
# ----------------------------------------------------------------------------

ui_rule() {
    ((UI_FRAMING)) || ui_layout
    ui_repeat "─" "$UI_W"
    ui_line "${U_FAINT}$REPLY"
}

# Bölüm başlığı: "◆ Başlık" ve altında ince çizgi. Çevrilir: ui_title "Biçim %s" ARG...
ui_title() {
    ((UI_FRAMING)) || { ui_layout; printf '\n'; }
    _t "$@"
    ui_line "${U_ACC}◆${U_RST} ${U_BOLD}${TR}${U_RST}"
    ui_rule
}

# Küçük bölüm etiketi metni: "KABUK ─────" -> REPLY
ui_section_str() {
    local label="${1^^}" n
    n=$((UI_W - ${#label} - 1))
    ((n < 1)) && n=1
    ui_repeat "─" "$n"
    REPLY="${U_MUTED}${U_BOLD}${label}${U_RST} ${U_FAINT}${REPLY}${U_RST}"
}

ui_section() {
    ((UI_FRAMING)) || ui_layout
    _t "$1"
    ui_section_str "$TR"
    ui_line "$REPLY"
}

# Yuvarlak köşeli kart: ui_card_top "Başlık" [simge] ; ui_card_row "içerik" ; ui_card_bottom
# Başlık çevrilir; satırlar ham metindir (çağıran çevirir).
ui_card_top() {
    local title=""
    ((UI_FRAMING)) || ui_layout
    if [[ -n "$1" ]]; then
        _t "$1"
        title="$TR"
        [[ -n "${2:-}" ]] && title="${U_ACC}${2}${U_RST} ${title}"
        ui_vlen "$title"
        ui_repeat "─" $((UI_W - UI_LEN - 5))
        ui_line "${U_FAINT}╭─${U_RST} ${U_BOLD}${title}${U_RST} ${U_FAINT}${REPLY}╮"
    else
        ui_repeat "─" $((UI_W - 2))
        ui_line "${U_FAINT}╭${REPLY}╮"
    fi
}

# Kart satırı; içerik sığmazsa kesilir, sağ kenar kaymaz
ui_card_row() {
    ui_clip "$1" $((UI_W - 4))
    ui_padr "$REPLY$U_RST" $((UI_W - 4))
    ui_line "${U_FAINT}│${U_RST} ${REPLY} ${U_FAINT}│"
}

ui_card_bottom() {
    ui_repeat "─" $((UI_W - 2))
    ui_line "${U_FAINT}╰${REPLY}╯"
}

# Tuş ipuçları metni -> REPLY: ui_keys_str "enter" "seç" "↑↓" "gez" ...
# Önem sırasına göre verilir; içerik genişliğine sığmayan sondakiler atlanır.
# Tuş adı ve açıklaması çevrilir.
ui_keys_str() {
    local keys="" item key
    while (($# >= 2)); do
        _t "$1"
        key="$TR"
        _t "$2"
        item="${U_CAP} ${key} ${U_RST} ${U_MUTED}${TR}${U_RST}   "
        ui_vlen "$keys$item"
        ((UI_LEN - 3 > UI_W)) && break
        keys+="$item"
        shift 2
    done
    REPLY="$keys"
}

ui_keys() {
    ui_keys_str "$@"
    ui_line "$REPLY"
}

# Durum rozeti -> REPLY: ui_badge ok|warn|err|info|acc|off "metin"
ui_badge() {
    local color
    case "$1" in
        ok) color="$U_OK" ;; warn) color="$U_WARN" ;; err) color="$U_ERR" ;;
        info) color="$U_INFO" ;; acc) color="$U_ACC" ;; *) color="$U_MUTED" ;;
    esac
    REPLY="${color}●${U_RST} $2"
}

# Ortalanmış satır
ui_center() {
    local n
    ui_vlen "$1"
    n=$(((UI_W - UI_LEN) / 2))
    ((n < 0)) && n=0
    printf -v REPLY '%*s' "$n" ''
    ui_line "$REPLY$1"
}
