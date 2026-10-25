#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Arayüz: etkileşim döngüsü, menü ve çoklu seçim listesi
# ============================================================================
# Her etkileşimli ekran iki parçadır:
#   ÇİZ   yalnızca çerçeveyi doldurur (terminal okumaz) -> test edilebilir
#   İŞLE  basılan tuşa göre durumu değiştirir; 0 devam, 10 kabul, 11 vazgeç
# ui_loop ikisini birleştirir: terminal oturumunu, pencere boyutu
# değişimini ve yeniden çizimi tek yerde yönetir.
#
# Başlık, alt başlık, etiket, açıklama ve bölüm adları çevrilir (lib/i18n.sh).
# Öğe biçimi: "Etiket|Açıklama|Ek". Menüde Ek tek karakterlik bir simgedir
# (✦ gibi), listede sağa yaslanan durum rozetidir. "#Başlık" seçilemeyen
# bir bölüm başlığıdır ve sıra numaralarına dahil edilmez.
#
# Ekran seçenekleri parametreyle verilir (--subtitle, --footer, --hero) ve
# local tanımlanır; çağrı bitince kendiliğinden eski haline döner.
# ============================================================================

UI_CHOICE=""          # ui_menu sonucu (seçilebilir öğeler arasında 0'dan sıra)
UI_SELECTED=()        # ui_checklist sonucu (seçilen sıralar)
UI_HEADER_FN=""       # uygulama başlığı: "$UI_HEADER_FN" HERO
UI_HEADER_STALE=1     # 1 ise başlık durumu yeniden okur (her tuşta değil)
UI_SUBTITLE="" UI_FOOTER_FN="" UI_HERO=0
UI_DRAW_ONCE=0        # 1: ekranı bir kez çiz ve vazgeçilmiş say (testler, ekran görüntüsü)

# ui_loop ÇİZ İŞLE -> kabulde 0, vazgeçmede 1
ui_loop() {
    local draw="$1" handle="$2" rc=0 owned=0 resumed=0
    if ((UI_DRAW_ONCE)); then
        "$draw"
        return 1
    fi
    if ((!UI_TERM_ACTIVE)); then
        ui_term_enter
        owned=1
    elif ((UI_TERM_SUSPENDED)); then
        ui_term_resume
        resumed=1
    fi
    while true; do
        "$draw"
        ui_read_key
        [[ "$UI_KEY" == resize ]] && continue
        "$handle" "$UI_KEY"
        rc=$?
        ((rc == 10 || rc == 11)) && break
    done
    ((owned)) && ui_term_leave
    ((resumed)) && ui_term_suspend
    ((rc == 10))
}

# Ekran seçeneklerini ayrıştır -> _UI_O_SUB, _UI_O_FOOT, _UI_O_HERO;
# tüketilen argüman sayısı _UI_OPT_SHIFT
_ui_parse_opts() {
    _UI_O_SUB="" _UI_O_FOOT="" _UI_O_HERO=0 _UI_OPT_SHIFT=0
    while (($#)); do
        case "$1" in
            --subtitle) _UI_O_SUB="$2"; shift 2; _UI_OPT_SHIFT=$((_UI_OPT_SHIFT + 2)) ;;
            --footer) _UI_O_FOOT="$2"; shift 2; _UI_OPT_SHIFT=$((_UI_OPT_SHIFT + 2)) ;;
            --hero) _UI_O_HERO=1; shift; _UI_OPT_SHIFT=$((_UI_OPT_SHIFT + 1)) ;;
            *) return 0 ;;
        esac
    done
}

# ----------------------------------------------------------------------------
# Liste modeli ve çizimi
# ----------------------------------------------------------------------------

_ui_parse_items() {
    local it rest
    _UI_KIND=() _UI_LABEL=() _UI_DESC=() _UI_EXTRA=() _UI_N=0
    for it in "$@"; do
        if [[ "$it" == "#"* ]]; then
            _t "${it#\#}"
            _UI_KIND+=(section) _UI_LABEL+=("$TR") _UI_DESC+=("") _UI_EXTRA+=("")
            continue
        fi
        _UI_KIND+=(item)
        _UI_N=$((_UI_N + 1))
        _t "${it%%|*}"
        _UI_LABEL+=("$TR")
        rest="${it#*|}"
        [[ "$rest" == "$it" ]] && rest=""
        _t "${rest%%|*}"
        _UI_DESC+=("$TR")
        if [[ "$rest" == *"|"* ]]; then _UI_EXTRA+=("${rest#*|}"); else _UI_EXTRA+=(""); fi
    done
}

# Öğe satırı -> REPLY. _ui_row MOD SEÇİLİ ETİKET-GENİŞLİĞİ İŞARETLİ i
# Satır tam UI_W genişliğindedir: seçili satırın zemini kenara kadar uzanır.
_ui_row() {
    local mode="$1" active="$2" lw="$3" checked="$4" i="$5"
    local desc="${_UI_DESC[i]}" extra="${_UI_EXTRA[i]}" lead mark badge="" blen=0 base="" room label

    if [[ "$mode" == menu ]]; then
        mark="${extra:-·}"
        if ((active)); then lead="${U_ACC}▌${U_SEL} ${U_ACC}${mark}"; else lead="  ${U_ACC2}${mark}"; fi
    else
        if ((checked)); then mark="${U_OK}◉"; else mark="${U_MUTED}○"; fi
        if ((active)); then lead="${U_ACC}▌${U_SEL} ${mark}"; else lead="  ${mark}"; fi
        badge="$extra"
        ui_vlen "$badge"
        blen=$UI_LEN
    fi
    ((active)) && base="$U_SEL"
    # öncü (3) + boşluk (2) + etiket + boşluk (2) + açıklama + rozet ve boşlukları
    room=$((UI_W - 7 - lw - (blen ? blen + 2 : 1)))
    ui_trunc "$desc" "$room"
    desc="$REPLY"
    ui_padr "${_UI_LABEL[i]}" "$lw"
    label="$REPLY"
    ui_padr "${lead}${U_RST}${base}  ${U_BOLD}${label}${U_RST}${base}  ${U_MUTED}${desc}${U_RST}${base}" \
        $((UI_W - (blen ? blen + 1 : 0)))
    ((blen)) && REPLY+="${badge}${U_RST}${base} "
    REPLY+="$U_RST"
}

# Listeyi çerçeveye çiz. Çerçeve açık olmalıdır (ui_frame_begin).
# _ui_list_render MOD BAŞLIK SEÇİLİ-SIRA; işaretler çağıranın _ui_checked
# dizisinden okunur. Yardımcılar aşağıdaki local değişkenleri paylaşır.
_ui_list_render() {
    local mode="$1" title="$2" pos="$3"
    local -a lines=() footer=()
    local sel_line=0 nchecked=0 head
    _ui_list_head "$title"
    head=${#UI_FRAME[@]}
    _ui_list_build "$mode" "$pos"
    _ui_list_footer
    _ui_list_window $((UI_ROWS - head - 2 - ${#footer[@]}))
    UI_FRAME+=("${footer[@]}")
    ui_line ""
    ui_frame_footer
    if [[ "$mode" == menu ]]; then
        ui_keys "enter" "seç" "↑↓" "gez" "q" "geri" "1-9" "kısayol"
    else
        ui_keys_str "enter" "onayla" "boşluk" "işaretle" "↑↓" "gez" "a" "hepsi" "q" "vazgeç"
        _t "seçili"
        ui_line "$REPLY${U_ACC}${nchecked}${U_RST}${U_MUTED} ${TR}"
    fi
}

_ui_list_head() {
    [[ -n "$UI_HEADER_FN" ]] && "$UI_HEADER_FN" "$UI_HERO"
    ui_line ""
    _t "$1"
    ui_line "${U_ACC}◆${U_RST} ${U_BOLD}${TR}"
    if [[ -n "$UI_SUBTITLE" ]]; then
        _t "$UI_SUBTITLE"
        ui_line "  ${U_MUTED}${TR}"
    fi
    ui_line ""
}

# Tüm satırları oluştur -> lines, sel_line, nchecked (çağıranın local'leri)
_ui_list_build() {
    local mode="$1" pos="$2" i j=0 lw=12
    for ((i = 0; i < ${#_UI_KIND[@]}; i++)); do
        [[ "${_UI_KIND[i]}" == item ]] && ((${#_UI_LABEL[i]} > lw)) && lw=${#_UI_LABEL[i]}
    done
    lw=$((lw + 2))
    for ((i = 0; i < ${#_UI_KIND[@]}; i++)); do
        if [[ "${_UI_KIND[i]}" == section ]]; then
            ((${#lines[@]})) && lines+=("")
            ui_section_str "${_UI_LABEL[i]}"
            lines+=("$REPLY")
            continue
        fi
        ((j == pos)) && sel_line=${#lines[@]}
        ((${_ui_checked[j]:-0})) && nchecked=$((nchecked + 1))
        _ui_row "$mode" $((j == pos)) "$lw" "${_ui_checked[j]:-0}" "$i"
        lines+=("$REPLY")
        j=$((j + 1))
    done
}

# Alt bilgi (öneri kartı gibi) ayrı çizilip satır sayısı ölçülür -> footer
_ui_list_footer() {
    local -a saved=()
    [[ -n "$UI_FOOTER_FN" ]] || return 0
    saved=("${UI_FRAME[@]}") UI_FRAME=()
    ui_line ""
    "$UI_FOOTER_FN"
    footer=("${UI_FRAME[@]}") UI_FRAME=("${saved[@]}")
}

# Satırları çiz; sığmıyorsa seçili satırı ortada tutan bir pencere göster
# ve gizli satır sayısını yaz. _ui_list_window KULLANILABİLİR-SATIR
_ui_list_window() {
    local avail="$1" total=${#lines[@]} start=0 end i
    end=$total
    if ((total > avail)); then
        avail=$((avail - 2))
        ((avail < 3)) && avail=3
        start=$((sel_line - avail / 2))
        ((start > total - avail)) && start=$((total - avail))
        ((start < 0)) && start=0
        end=$((start + avail))
        if ((start > 0)); then
            _t "%s satır daha" "$start"
            ui_line "${U_MUTED}  ↑ $TR"
        else
            ui_line ""
        fi
    fi
    for ((i = start; i < end; i++)); do ui_line "${lines[i]}"; done
    if ((end < total)); then
        _t "%s satır daha" $((total - end))
        ui_line "${U_MUTED}  ↓ $TR"
    fi
    return 0
}

# Gezinme tuşları: seçili sırayı (_ui_pos) _UI_N içinde değiştirir
_ui_nav() {
    case "$1" in
        up|k) _ui_pos=$(((_ui_pos - 1 + _UI_N) % _UI_N)) ;;
        down|j|tab) _ui_pos=$(((_ui_pos + 1) % _UI_N)) ;;
        home|g) _ui_pos=0 ;;
        end|G) _ui_pos=$((_UI_N - 1)) ;;
        pgup) _ui_pos=$((_ui_pos > 8 ? _ui_pos - 8 : 0)) ;;
        pgdn) _ui_pos=$((_ui_pos + 8 < _UI_N ? _ui_pos + 8 : _UI_N - 1)) ;;
    esac
}

# ----------------------------------------------------------------------------
# Menü
# ----------------------------------------------------------------------------

# ui_menu [--subtitle METİN] [--footer FONKSİYON] [--hero] BAŞLIK ÖĞE...
# Seçim UI_CHOICE'a yazılır; vazgeçilirse (q, Esc) 1 döner.
ui_menu() {
    _ui_parse_opts "$@"
    shift "$_UI_OPT_SHIFT"
    local title="$1"
    shift
    if ! ui_is_tty; then
        _ui_menu_plain "$title" "$@"
        return
    fi
    local UI_SUBTITLE="$_UI_O_SUB" UI_FOOTER_FN="$_UI_O_FOOT" UI_HERO="$_UI_O_HERO"
    local -a _UI_KIND _UI_LABEL _UI_DESC _UI_EXTRA _ui_checked=()
    local _UI_N _ui_pos=0 _ui_title="$title"
    _ui_parse_items "$@"
    ((_UI_N > 0)) || return 1
    UI_HEADER_STALE=1
    ui_loop _ui_menu_draw _ui_menu_key
}

_ui_menu_draw() {
    ui_frame_begin
    _ui_list_render menu "$_ui_title" "$_ui_pos"
    ui_frame_end
}

_ui_menu_key() {
    case "$1" in
        enter|right|l) UI_CHOICE=$_ui_pos; return 10 ;;
        q|esc|left|h|eof|backspace) return 11 ;;
        [1-9]) if (($1 <= _UI_N)); then UI_CHOICE=$(($1 - 1)); return 10; fi ;;
        *) _ui_nav "$1" ;;
    esac
    return 0
}

_ui_menu_plain() {
    local title="$1" it answer n=0
    shift
    ui_title "$title"
    for it in "$@"; do
        [[ "$it" == "#"* ]] && continue
        n=$((n + 1))
        _t "${it%%|*}"
        printf '  %2d) %s\n' "$n" "$TR"
    done
    _t "Geri"
    printf '   0) %s\n' "$TR"
    _t "Seçiminiz:"
    printf '%s ' "$TR"
    IFS= read -r answer || return 1
    [[ "$answer" =~ ^[0-9]+$ ]] || return 1
    ((answer >= 1 && answer <= n)) || return 1
    UI_CHOICE=$((answer - 1))
}

# ----------------------------------------------------------------------------
# Çoklu seçim
# ----------------------------------------------------------------------------

# ui_checklist [--subtitle METİN] BAŞLIK "ön-seçili sıralar" ÖĞE...
# Sonuç UI_SELECTED dizisine yazılır; vazgeçilirse 1 döner.
ui_checklist() {
    _ui_parse_opts "$@"
    shift "$_UI_OPT_SHIFT"
    local title="$1" preset="$2" i
    shift 2
    if ! ui_is_tty; then
        _ui_checklist_plain "$title" "$@"
        return
    fi
    local UI_SUBTITLE="$_UI_O_SUB" UI_FOOTER_FN="" UI_HERO=0
    local -a _UI_KIND _UI_LABEL _UI_DESC _UI_EXTRA _ui_checked=()
    local _UI_N _ui_pos=0 _ui_title="$title"
    _ui_parse_items "$@"
    ((_UI_N > 0)) || return 1
    for ((i = 0; i < _UI_N; i++)); do _ui_checked[i]=0; done
    for i in $preset; do ((i < _UI_N)) && _ui_checked[i]=1; done
    UI_HEADER_STALE=1
    ui_loop _ui_check_draw _ui_check_key
}

_ui_check_draw() {
    ui_frame_begin
    _ui_list_render check "$_ui_title" "$_ui_pos"
    ui_frame_end
}

_ui_check_key() {
    local i all=1
    case "$1" in
        space|x) _ui_checked[_ui_pos]=$((1 - _ui_checked[_ui_pos])) ;;
        a)
            for ((i = 0; i < _UI_N; i++)); do ((_ui_checked[i])) || all=0; done
            for ((i = 0; i < _UI_N; i++)); do _ui_checked[i]=$((1 - all)); done ;;
        enter)
            UI_SELECTED=()
            for ((i = 0; i < _UI_N; i++)); do ((_ui_checked[i])) && UI_SELECTED+=("$i"); done
            return 10 ;;
        q|esc|eof|backspace) return 11 ;;
        *) _ui_nav "$1" ;;
    esac
    return 0
}

_ui_checklist_plain() {
    local title="$1" it answer num n=0
    shift
    ui_title "$title"
    for it in "$@"; do
        [[ "$it" == "#"* ]] && continue
        n=$((n + 1))
        _t "${it%%|*}"
        printf '  %2d) %s\n' "$n" "$TR"
    done
    _t "Numaraları boşlukla girin (örn. 1 3 4):"
    printf '%s ' "$TR"
    IFS= read -r answer || return 1
    UI_SELECTED=()
    for num in $answer; do
        [[ "$num" =~ ^[0-9]+$ ]] && ((num >= 1 && num <= n)) && UI_SELECTED+=("$((num - 1))")
    done
    ((${#UI_SELECTED[@]} > 0))
}
