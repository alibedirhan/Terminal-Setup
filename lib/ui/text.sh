#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Arayüz: metin ölçüsü
# ============================================================================
# Kural: bu dosyadaki fonksiyonlar alt kabuk açmaz; sonucu REPLY'ye
# (uzunluğu UI_LEN'e) yazar. Ekran her tuşta yeniden çizildiği için
# $(...) ile çağrılan her yardımcı gecikme demektir.
#
# Genişlik, kaçış kodları ayıklanıp karakter sayılarak bulunur. Bu yüzden
# arayüzde yalnızca tek hücre genişliğinde simgeler kullanılır (emoji yok).
# ============================================================================

UI_LEN=0

# Bash karakter sayarken yerel ayarı kullanır; UTF-8 değilse Türkçe harfler
# iki bayt sayılır ve hizalama kayar.
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *[Uu][Tt][Ff]-8* | *[Uu][Tt][Ff]8*) ;;
    *) [[ -z "${LC_ALL:-}" ]] && LC_CTYPE=C.UTF-8 ;;
esac

# Görünen uzunluk (renk kodları sayılmaz) -> UI_LEN
ui_vlen() {
    local s="$1" out=""
    while [[ "$s" == *$'\033['* ]]; do
        out+="${s%%$'\033['*}"
        s="${s#*$'\033['}"
        s="${s#*m}"
    done
    out+="$s"
    UI_LEN=${#out}
}

# N tane karakter -> REPLY. ui_repeat "─" 10
ui_repeat() {
    printf -v REPLY '%*s' "$2" ''
    REPLY="${REPLY// /$1}"
}

# Görünen genişliği W olacak şekilde sağa boşluk ekle -> REPLY
ui_padr() {
    local n
    ui_vlen "$1"
    n=$(($2 - UI_LEN))
    ((n < 0)) && n=0
    printf -v REPLY '%s%*s' "$1" "$n" ''
}

# Düz metni en fazla N karaktere kısalt (sonuna …) -> REPLY
ui_trunc() {
    local s="$1" n="$2"
    if ((n < 1)); then REPLY=""
    elif ((${#s} > n)); then REPLY="${s:0:n-1}…"
    else REPLY="$s"; fi
}

# Renkli metni görünen N karakterde kes; renk kodları korunur -> REPLY
ui_clip() {
    local s="$1" n="$2" out="" vis=0 seg room
    while [[ -n "$s" ]]; do
        if [[ "$s" == $'\033['* ]]; then
            [[ "$s" == *m* ]] || break
            seg="${s%%m*}m"
            out+="$seg"
            s="${s:${#seg}}"
            continue
        fi
        seg="${s%%$'\033['*}"
        room=$((n - vis))
        if ((${#seg} > room)); then
            REPLY="$out${seg:0:room}"$'\033[0m'
            return 0
        fi
        out+="$seg"
        vis=$((vis + ${#seg}))
        s="${s:${#seg}}"
    done
    REPLY="$out"
}

# Uyumluluk: $(ui_pad "metin" genişlik) biçiminde kullanılan yazdıran sürüm.
# Satır başına bir kez çağrılan yerlerde (durum, teşhis) kullanılır.
ui_pad() {
    local n
    ui_vlen "$1"
    n=$(($2 - UI_LEN))
    ((n < 1)) && n=1
    printf '%s%*s' "$1" "$n" ''
}
