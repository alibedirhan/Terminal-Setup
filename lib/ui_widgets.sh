#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Menü ve çoklu seçim listesi
# ============================================================================
# Öğe biçimi: "Etiket|Açıklama|Ek". Menüde Ek bir simgedir (✦ gibi),
# listede sağa yaslanan durum rozetidir. "#Başlık" biçimindeki öğe
# seçilemeyen bir bölüm başlığıdır; sıra numaralarına dahil edilmez.
#
# Liste ekrana sığmazsa seçili satırı izleyerek kayar. Terminal (TTY) yoksa
# numaralı düz menüye düşer; böylece testlerde ve borulu girdide de çalışır.
# ============================================================================

UI_HEADER_STALE=1     # 1 ise başlık fonksiyonu durumu yeniden okur
UI_FOOTER_FN=""       # listenin altında gösterilecek fonksiyon (öneri kartı)

_UI_KIND=() _UI_LABEL=() _UI_DESC=() _UI_EXTRA=()

_ui_parse_items() {
    local it rest
    _UI_KIND=() _UI_LABEL=() _UI_DESC=() _UI_EXTRA=()
    for it in "$@"; do
        if [[ "$it" == "#"* ]]; then
            _UI_KIND+=(section) _UI_LABEL+=("${it#\#}") _UI_DESC+=("") _UI_EXTRA+=("")
            continue
        fi
        _UI_KIND+=(item)
        _UI_LABEL+=("${it%%|*}")
        rest="${it#*|}"
        [[ "$rest" == "$it" ]] && rest=""
        _UI_DESC+=("${rest%%|*}")
        if [[ "$rest" == *"|"* ]]; then _UI_EXTRA+=("${rest#*|}"); else _UI_EXTRA+=(""); fi
    done
}

_ui_count_items() {
    local k n=0
    for k in "${_UI_KIND[@]}"; do [[ "$k" == item ]] && n=$((n + 1)); done
    echo "$n"
}

# Bölüm satırı metni: "KABUK ─────"
_ui_section_str() {
    local label="${1^^}" line n
    n=$((UI_W - ${#label} - 1))
    ((n < 1)) && n=1
    printf -v line '%*s' "$n" ''
    printf '%s' "${U_MUTED}${U_BOLD}${label}${U_RST} ${U_FAINT}${line// /─}${U_RST}"
}

# Bir öğe satırını oluştur. _ui_row MOD SEÇİLİ ETİKET-GENİŞLİĞİ İŞARETLİ i
_ui_row() {
    local mode="$1" active="$2" lw="$3" checked="$4" i="$5"
    local label="${_UI_LABEL[i]}" desc="${_UI_DESC[i]}" extra="${_UI_EXTRA[i]}"
    local lead mark badge="" blen=0 room row base="" pad

    if [[ "$mode" == menu ]]; then
        mark="${extra:-·}"
        if ((active)); then lead="${U_ACC}▌${U_SEL} ${U_ACC}${mark}"; else lead="  ${U_ACC2}${mark}"; fi
        room=$((UI_W - 5 - lw - 3))
    else
        if ((checked)); then mark="${U_OK}◉"; else mark="${U_MUTED}○"; fi
        if ((active)); then lead="${U_ACC}▌${U_SEL} ${mark}"; else lead="  ${mark}"; fi
        badge="$extra"
        ui_vlen "$badge"
        blen=$UI_LEN
        room=$((UI_W - 5 - lw - 3 - blen - 2))
    fi
    ((active)) && base="$U_SEL"
    desc=$(ui_trunc "$desc" "$room")
    row="${lead}${U_RST}${base}  ${U_BOLD}$(ui_pad "$label" "$lw")${U_RST}${base}  ${U_MUTED}${desc}${U_RST}${base}"
    ui_vlen "$row"
    pad=$((UI_W - UI_LEN - blen - (blen ? 1 : 0)))
    ((pad < 0)) && pad=0
    row+="$(printf '%*s' "$pad" '')"
    ((blen)) && row+="${badge}${U_RST}${base} "
    printf '%s%s' "$row" "$U_RST"
}

# Listeyi çiz. _ui_draw MOD BAŞLIK SEÇİLİ-SIRA [işaret dizisi...]
_ui_draw() {
    local mode="$1" title="$2" pos="$3"
    shift 3
    local -a checks=("$@") lines=()
    local i j=0 lw=12 sel_line=0 head avail total start end nchecked=0 more
    local saved footer="" flines=0

    for ((i = 0; i < ${#_UI_KIND[@]}; i++)); do
        [[ "${_UI_KIND[i]}" == item ]] && ((${#_UI_LABEL[i]} > lw)) && lw=${#_UI_LABEL[i]}
    done
    lw=$((lw + 2))

    ui_frame_begin
    if [[ -n "$UI_HEADER_FN" ]]; then "$UI_HEADER_FN"; fi
    ui_line ""
    ui_line "${U_ACC}◆${U_RST} ${U_BOLD}${title}"
    [[ -n "$UI_SUBTITLE" ]] && ui_line "  ${U_MUTED}${UI_SUBTITLE}"
    ui_line ""
    head=$(ui_frame_lines)

    for ((i = 0; i < ${#_UI_KIND[@]}; i++)); do
        if [[ "${_UI_KIND[i]}" == section ]]; then
            ((${#lines[@]})) && lines+=("")
            lines+=("$(_ui_section_str "${_UI_LABEL[i]}")")
            continue
        fi
        ((j == pos)) && sel_line=${#lines[@]}
        ((${checks[j]:-0})) && nchecked=$((nchecked + 1))
        lines+=("$(_ui_row "$mode" $((j == pos)) "$lw" "${checks[j]:-0}" "$i")")
        j=$((j + 1))
    done

    # Sığmıyorsa seçili satırı ortada tutan bir pencere göster; üstte ve
    # altta kaç satırın gizli olduğu yazılır.
    # Alt bilgi (öneri kartı gibi) ayrı çizilip satır sayısı ölçülür
    if [[ -n "$UI_FOOTER_FN" ]]; then
        saved="$UI_BUF" UI_BUF=""
        ui_line ""
        "$UI_FOOTER_FN"
        footer="$UI_BUF" flines=$(ui_frame_lines)
        UI_BUF="$saved"
    fi

    total=${#lines[@]}
    avail=$((UI_ROWS - head - 3 - flines))
    start=0 end=$total
    if ((total > avail)); then
        avail=$((avail - 2))
        ((avail < 3)) && avail=3
        start=$((sel_line - avail / 2))
        ((start > total - avail)) && start=$((total - avail))
        ((start < 0)) && start=0
        end=$((start + avail))
        more=""
        ((start > 0)) && more="${U_MUTED}  ↑ ${start} satır daha"
        ui_line "$more"
    fi
    for ((i = start; i < end; i++)); do ui_line "${lines[i]}"; done
    if ((end < total)); then
        ui_line "${U_MUTED}  ↓ $((total - end)) satır daha"
    elif ((start > 0)); then
        ui_line ""
    fi
    UI_BUF+="$footer"

    ui_line ""
    if [[ "$mode" == menu ]]; then
        ui_keys "↑↓" "gez" "enter" "seç" "1-9" "kısayol" "q" "geri"
    else
        ui_keys "↑↓" "gez" "boşluk" "işaretle" "a" "hepsi" "enter" "onayla" "q" "vazgeç"
        UI_BUF="${UI_BUF%$'\033[K\n'}  ${U_ACC}${nchecked}${U_RST}${U_MUTED} seçili${U_RST}"$'\033[K\n'
    fi
    ui_frame_end
}

# Gezinme tuşlarını uygula: _ui_nav TUŞ SIRA TOPLAM -> yeni sıra (değişmezse aynı)
_ui_nav() {
    local key="$1" pos="$2" n="$3"
    case "$key" in
        up|k) pos=$(((pos - 1 + n) % n)) ;;
        down|j) pos=$(((pos + 1) % n)) ;;
        home|g) pos=0 ;;
        end|G) pos=$((n - 1)) ;;
        pgup) pos=$((pos - 8)); ((pos < 0)) && pos=0 ;;
        pgdn) pos=$((pos + 8)); ((pos >= n)) && pos=$((n - 1)) ;;
    esac
    echo "$pos"
}

# Menü. ui_menu "Başlık" "#Bölüm" "Kur|Profil seç|✦" "Çık|"
# Seçim UI_CHOICE'a yazılır; vazgeçilirse (q, Esc) 1 döner.
ui_menu() {
    local title="$1"
    shift
    local items=("$@") pos=0 n

    if ! ui_is_tty; then
        _ui_menu_plain "$title" "${items[@]}"
        return $?
    fi
    _ui_parse_items "${items[@]}"
    n=$(_ui_count_items)
    ((n > 0)) || return 1
    UI_HEADER_STALE=1
    _ui_cursor_hide
    while true; do
        _ui_draw menu "$title" "$pos"
        ui_read_key
        case "$UI_KEY" in
            enter|right|l) UI_CHOICE=$pos; _ui_cursor_show; return 0 ;;
            q|esc|left|eof) _ui_cursor_show; return 1 ;;
            [1-9])
                if ((UI_KEY <= n)); then
                    UI_CHOICE=$((UI_KEY - 1)); _ui_cursor_show; return 0
                fi ;;
            *) pos=$(_ui_nav "$UI_KEY" "$pos" "$n") ;;
        esac
    done
}

_ui_menu_plain() {
    local title="$1" it answer n=0
    shift
    ui_title "$title"
    for it in "$@"; do
        [[ "$it" == "#"* ]] && continue
        n=$((n + 1))
        printf '  %2d) %s\n' "$n" "${it%%|*}"
    done
    printf '   0) Geri\n'
    printf 'Seçiminiz: '
    IFS= read -r answer || return 1
    [[ "$answer" =~ ^[0-9]+$ ]] || return 1
    ((answer >= 1 && answer <= n)) || return 1
    UI_CHOICE=$((answer - 1))
}

# Çoklu seçim. ui_checklist "Başlık" "ön-seçili-sıralar(boşlukla)" öğe...
# Sonuç UI_SELECTED dizisine yazılır.
ui_checklist() {
    local title="$1" preset="$2"
    shift 2
    local items=("$@") pos=0 n i all
    local -a checked=()

    if ! ui_is_tty; then
        _ui_checklist_plain "$title" "${items[@]}"
        return $?
    fi
    _ui_parse_items "${items[@]}"
    n=$(_ui_count_items)
    ((n > 0)) || return 1
    for ((i = 0; i < n; i++)); do checked[i]=0; done
    for i in $preset; do checked[i]=1; done
    UI_HEADER_STALE=1
    _ui_cursor_hide
    while true; do
        _ui_draw check "$title" "$pos" "${checked[@]}"
        ui_read_key
        case "$UI_KEY" in
            space|x) checked[pos]=$((1 - checked[pos])) ;;
            a)
                all=1
                for ((i = 0; i < n; i++)); do ((checked[i])) || all=0; done
                for ((i = 0; i < n; i++)); do checked[i]=$((1 - all)); done ;;
            enter)
                UI_SELECTED=()
                for ((i = 0; i < n; i++)); do ((checked[i])) && UI_SELECTED+=("$i"); done
                _ui_cursor_show
                return 0 ;;
            q|esc|eof) _ui_cursor_show; return 1 ;;
            *) pos=$(_ui_nav "$UI_KEY" "$pos" "$n") ;;
        esac
    done
}

_ui_checklist_plain() {
    local title="$1" it answer num n=0
    shift
    ui_title "$title"
    for it in "$@"; do
        [[ "$it" == "#"* ]] && continue
        n=$((n + 1))
        printf '  %2d) %s\n' "$n" "${it%%|*}"
    done
    printf 'Numaraları boşlukla girin (örn. 1 3 4): '
    IFS= read -r answer || return 1
    UI_SELECTED=()
    for num in $answer; do
        [[ "$num" =~ ^[0-9]+$ ]] && ((num >= 1 && num <= n)) && UI_SELECTED+=("$((num - 1))")
    done
    ((${#UI_SELECTED[@]} > 0))
}
