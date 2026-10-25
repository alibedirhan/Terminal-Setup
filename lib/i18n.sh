#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Dil desteği (Türkçe / English)
# ============================================================================
# Kaynak dil Türkçedir: metinler kodda Türkçe yazılır ve çeviri anahtarı
# olarak kullanılır (gettext'teki msgid gibi). İngilizce karşılıklar
# locale/en.sh içindeki I18N_EN dizisindedir. Karşılığı olmayan metin
# Türkçe gösterilir; TS_I18N_MISSING tanımlıysa o dosyaya yazılır (testler
# eksik çeviriyi böyle yakalar).
#
# Dil sırası: --lang, TS_LANG ortam değişkeni, "language" ayarı (tr|en|auto),
# sistem dili (LC_ALL, LC_MESSAGES, LANG: tr* ise Türkçe, değilse English).
#
# Değişken içeren metinler printf biçimindedir; anahtar biçimin kendisidir:
#   log_err "Bilinmeyen bileşen: %s" "$id"
# _t alt kabuk açmaz, sonucu TR değişkenine yazar (REPLY'yi bozmaz).
# ============================================================================

declare -gA I18N_EN=()
declare -gA I18N_DONE=()   # çevrilmiş metinler: _t ikinci kez uygulanırsa dokunmaz
TS_LANG="${TS_LANG:-}"
I18N_LOADED=""

# Sistem dilinden: i18n_detect -> tr | en
i18n_detect() {
    local loc="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
    [[ "$loc" == tr* ]] && echo tr || echo en
}

# Dili belirle ve gerekirse katalogu yükle: i18n_init [tr|en|auto]
i18n_init() {
    local want="${1:-${TS_LANG:-}}"
    [[ -z "$want" ]] && want=$(settings_get language auto)
    case "$want" in
        tr|en) TS_LANG="$want" ;;
        *) TS_LANG=$(i18n_detect) ;;
    esac
    if [[ "$TS_LANG" == en && "$I18N_LOADED" != en ]]; then
        local k
        # shellcheck source=locale/en.sh
        source "$TS_ROOT/locale/en.sh" || return 0
        for k in "${!I18N_EN[@]}"; do I18N_DONE[${I18N_EN[$k]}]=1; done
        I18N_LOADED=en
    fi
}

# Eksik çeviri raporuna girmeyecekler: tuş adları gibi çok kısa metinler ve
# renk kodu içeren, önceden çevrilip birleştirilmiş satırlar.
_i18n_should_report() {
    ((${#1} >= 4)) && [[ "$1" != *$'\033'* ]]
}

# Çevir ve biçimlendir: _t "Biçim %s" arg... -> TR
# Zaten çevrilmiş bir metne uygulanırsa metni olduğu gibi bırakır; böylece
# çevrilmiş bir değer, kendisi çeviri yapan bir arayüz fonksiyonuna verilebilir.
_t() {
    local fmt="${1:-}"
    (($#)) && shift
    if [[ -z "$fmt" ]]; then
        TR=""
        return 0
    fi
    if [[ "$TS_LANG" == en ]]; then
        if [[ -n "${I18N_EN[$fmt]+x}" ]]; then
            fmt="${I18N_EN[$fmt]}"
        elif [[ -z "${I18N_DONE[$fmt]+x}" && -n "${TS_I18N_MISSING:-}" ]] && _i18n_should_report "$fmt"; then
            printf '%s\n' "$fmt" >> "$TS_I18N_MISSING"
        fi
    fi
    if (($#)); then
        # shellcheck disable=SC2059  # biçim katalogdan gelir
        printf -v TR "$fmt" "$@"
        [[ "$TS_LANG" == en && -n "$TR" ]] && I18N_DONE[$TR]=1
    else
        TR="$fmt"
    fi
    return 0
}

# Çeviriyi yazdır: t "Biçim %s" arg...
t() { _t "$@"; printf '%s' "$TR"; }
