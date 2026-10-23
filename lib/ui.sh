#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Arayüz yapı taşları
# ============================================================================
# Bağımlılıksız terminal arayüzü: ok tuşlarıyla gezilen menü, çoklu seçim
# listesi, onay soruları. Terminal (TTY) yoksa numaralı düz menüye düşer;
# böylece testlerde ve borulu girdide de çalışır.
#
# Tasarım kararı: kutuların sağ kenarı çizilmez. Türkçe karakterler ve
# emojiler genişlik hesabını bozduğu için sağ kenar hep kayıyordu.
# ============================================================================

UI_CHOICE=""          # ui_menu sonucu (0'dan başlayan sıra)
UI_SELECTED=()        # ui_checklist sonucu (seçilen sıralar)
UI_HEADER_FN=""       # her çizimde üstte gösterilecek fonksiyon (durum çubuğu)

ui_width() {
    local w="${COLUMNS:-}"
    [[ -z "$w" ]] && has_cmd tput && w=$(tput cols 2>/dev/null)
    [[ "$w" =~ ^[0-9]+$ ]] || w=80
    (( w > 100 )) && w=100
    (( w < 50 )) && w=50
    echo "$w"
}

ui_is_tty() { [[ -t 0 && -t 1 ]]; }

# Karakter sayarak sağa boşluk doldur (printf %-Ns baytı sayar; Türkçe
# karakterlerde hizalama kayar). ui_pad "metin" genişlik
ui_pad() {
    local s="$1" w="$2" n
    n=$((w - ${#s}))
    ((n < 1)) && n=1
    printf '%s%*s' "$s" "$n" ''
}

ui_rule() {
    local w line
    w=$(ui_width)
    printf -v line '%*s' "$w" ''
    printf '%s\n' "${C_DIM}${line// /─}${C_RESET}"
}

ui_title() {
    printf '\n%s\n' "${C_BOLD}$*${C_RESET}"
    ui_rule
}

ui_clear() { ui_is_tty && printf '\033[H\033[2J'; return 0; }

ui_pause() {
    [[ "$TS_ASSUME_YES" == "1" ]] && return 0
    ui_is_tty || return 0
    printf '\n%s' "${C_DIM}Devam etmek için Enter'a basın...${C_RESET}"
    read -r _ || true
}

# Evet/hayır sorusu. ui_confirm "Soru" [e|h varsayılan]
ui_confirm() {
    local question="$1" default="${2:-h}" answer hint
    [[ "$TS_ASSUME_YES" == "1" ]] && return 0
    [[ "$default" == "e" ]] && hint="[E/h]" || hint="[e/H]"
    while true; do
        printf '%s %s ' "${C_YELLOW}?${C_RESET} $question" "$hint"
        IFS= read -r answer || return 1
        answer="${answer:-$default}"
        case "${answer,,}" in
            e|evet|y|yes) return 0 ;;
            h|hayır|hayir|n|no) return 1 ;;
        esac
        echo "Lütfen 'e' veya 'h' girin."
    done
}

# Tehlikeli işlem için kelime yazdırarak onay: ui_type_confirm "kaldır"
ui_type_confirm() {
    local word="$1" answer
    [[ "$TS_ASSUME_YES" == "1" ]] && return 0
    printf '%s ' "${C_RED}!${C_RESET} Onaylamak için ${C_BOLD}$word${C_RESET} yazın:"
    IFS= read -r answer || return 1
    [[ "$answer" == "$word" ]]
}

_ui_read_key() {
    local k rest=""
    IFS= read -rsn1 k || { echo eof; return 0; }
    if [[ "$k" == $'\e' ]]; then
        IFS= read -rsn2 -t 0.05 rest || true
        case "$rest" in
            '[A') echo up ;; '[B') echo down ;;
            '[C') echo right ;; '[D') echo left ;;
            *) echo esc ;;
        esac
    elif [[ -z "$k" ]]; then
        echo enter
    elif [[ "$k" == " " ]]; then
        echo space
    else
        echo "$k"
    fi
}

_ui_cursor_hide() { ui_is_tty && printf '\033[?25l'; return 0; }
_ui_cursor_show() { ui_is_tty && printf '\033[?25h'; return 0; }

# Menü. Öğeler "Etiket|Açıklama" biçiminde.
#   ui_menu "Başlık" "Kur|Profil seç" "Çık|"
# Seçim UI_CHOICE'a yazılır; vazgeçilirse (q, Esc) 1 döner.
ui_menu() {
    local title="$1"
    shift
    local items=("$@") count=$# pos=0 key i label desc marker

    if ! ui_is_tty; then
        _ui_menu_plain "$title" "${items[@]}"
        return $?
    fi

    _ui_cursor_hide
    while true; do
        ui_clear
        [[ -n "$UI_HEADER_FN" ]] && "$UI_HEADER_FN"
        ui_title "$title"
        for ((i = 0; i < count; i++)); do
            label="${items[i]%%|*}"
            desc="${items[i]#*|}"
            [[ "$desc" == "${items[i]}" ]] && desc=""
            if ((i == pos)); then
                marker="${C_CYAN}❯${C_RESET}"
                printf ' %s %s%s%s%s\n' "$marker" "$C_BOLD" "$(ui_pad "$label" 24)" "$C_RESET" "${C_DIM}$desc${C_RESET}"
            else
                printf '   %s%s\n' "$(ui_pad "$label" 24)" "${C_DIM}$desc${C_RESET}"
            fi
        done
        printf '\n%s\n' "${C_DIM} ↑↓ gez   enter seç   1-9 kısayol   q geri${C_RESET}"
        key=$(_ui_read_key)
        case "$key" in
            up|k) pos=$(((pos - 1 + count) % count)) ;;
            down|j) pos=$(((pos + 1) % count)) ;;
            enter|right) UI_CHOICE=$pos; _ui_cursor_show; return 0 ;;
            q|esc|left|eof) _ui_cursor_show; return 1 ;;
            [1-9])
                if ((key <= count)); then
                    UI_CHOICE=$((key - 1)); _ui_cursor_show; return 0
                fi
                ;;
        esac
    done
}

_ui_menu_plain() {
    local title="$1" i answer
    shift
    ui_title "$title"
    for ((i = 1; i <= $#; i++)); do
        printf '  %2d) %s\n' "$i" "${!i%%|*}"
    done
    printf '   0) Geri\n'
    printf 'Seçiminiz: '
    IFS= read -r answer || return 1
    [[ "$answer" =~ ^[0-9]+$ ]] || return 1
    ((answer >= 1 && answer <= $#)) || return 1
    UI_CHOICE=$((answer - 1))
}

# Çoklu seçim. ui_checklist "Başlık" "ön-seçili-sıralar(boşlukla)" öğe...
# Öğeler "Etiket|Açıklama". Sonuç UI_SELECTED dizisine yazılır.
ui_checklist() {
    local title="$1" preset="$2"
    shift 2
    local items=("$@") count=$# pos=0 key i mark label desc
    local -a checked=()
    for ((i = 0; i < count; i++)); do checked[i]=0; done
    for i in $preset; do checked[i]=1; done

    if ! ui_is_tty; then
        _ui_checklist_plain "$title" "${items[@]}"
        return $?
    fi

    _ui_cursor_hide
    while true; do
        ui_clear
        [[ -n "$UI_HEADER_FN" ]] && "$UI_HEADER_FN"
        ui_title "$title"
        for ((i = 0; i < count; i++)); do
            label="${items[i]%%|*}"
            desc="${items[i]#*|}"
            [[ "$desc" == "${items[i]}" ]] && desc=""
            ((checked[i])) && mark="${C_GREEN}[x]${C_RESET}" || mark="[ ]"
            if ((i == pos)); then
                printf ' %s %s %s%s%s%s\n' "${C_CYAN}❯${C_RESET}" "$mark" "$C_BOLD" "$(ui_pad "$label" 18)" "$C_RESET" "${C_DIM}$desc${C_RESET}"
            else
                printf '   %s %s%s\n' "$mark" "$(ui_pad "$label" 18)" "${C_DIM}$desc${C_RESET}"
            fi
        done
        printf '\n%s\n' "${C_DIM} ↑↓ gez   boşluk seç   a hepsi   enter onayla   q vazgeç${C_RESET}"
        key=$(_ui_read_key)
        case "$key" in
            up|k) pos=$(((pos - 1 + count) % count)) ;;
            down|j) pos=$(((pos + 1) % count)) ;;
            space) checked[pos]=$((1 - checked[pos])) ;;
            a)
                local all=1
                for ((i = 0; i < count; i++)); do ((checked[i])) || all=0; done
                for ((i = 0; i < count; i++)); do checked[i]=$((1 - all)); done
                ;;
            enter)
                UI_SELECTED=()
                for ((i = 0; i < count; i++)); do ((checked[i])) && UI_SELECTED+=("$i"); done
                _ui_cursor_show
                return 0
                ;;
            q|esc|eof) _ui_cursor_show; return 1 ;;
        esac
    done
}

_ui_checklist_plain() {
    local title="$1" i answer n
    shift
    ui_title "$title"
    for ((i = 1; i <= $#; i++)); do
        printf '  %2d) %s\n' "$i" "${!i%%|*}"
    done
    printf 'Numaraları boşlukla girin (örn. 1 3 4): '
    IFS= read -r answer || return 1
    UI_SELECTED=()
    for n in $answer; do
        [[ "$n" =~ ^[0-9]+$ ]] && ((n >= 1 && n <= $#)) && UI_SELECTED+=("$((n - 1))")
    done
    ((${#UI_SELECTED[@]} > 0))
}
