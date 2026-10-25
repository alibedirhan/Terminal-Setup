#!/usr/bin/env bats
# Dil desteği: katalog tutarlılığı, çeviri, dil seçimi

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
    unset TS_LANG LANG LC_ALL LC_MESSAGES
    MISSING="$BATS_TEST_TMPDIR/missing"
}

@test "katalog yüklenir; her çeviride %s sayısı aynı, sıralı yer tutucu yok" {
    i18n_init en
    [ "${#I18N_EN[@]}" -gt 300 ]
    local k v bad=0
    for k in "${!I18N_EN[@]}"; do
        v="${I18N_EN[$k]}"
        if [[ "$(grep -o '%[^%]' <<< "$k" | tr -d '\n')" != "$(grep -o '%[^%]' <<< "$v" | tr -d '\n')" ]]; then
            echo "yer tutucular farklı: $k -> $v"
            bad=1
        fi
        [[ "$v" == *'%'[0-9]'$'* ]] && { echo "sıralı yer tutucu: $v"; bad=1; }
        [[ -n "$v" ]] || { echo "boş çeviri: $k"; bad=1; }
    done
    [ "$bad" -eq 0 ]
}

@test "Türkçede metin aynen, İngilizcede çevrilerek biçimlenir" {
    i18n_init tr
    _t "Bilinmeyen bileşen: %s" "x"
    [ "$TR" = "Bilinmeyen bileşen: x" ]
    i18n_init en
    _t "Bilinmeyen bileşen: %s" "x"
    [ "$TR" = "Unknown component: x" ]
    _t ""
    [ "$TR" = "" ]
}

@test "yüzde işareti içeren argüman biçimi bozmaz" {
    i18n_init en
    _t "Bilinmeyen bileşen: %s" "%s%d"
    [ "$TR" = "Unknown component: %s%d" ]
    _t "%100 hazır"
    [ "$TR" = "%100 hazır" ]
}

@test "çevrilmiş metne tekrar uygulanan _t onu değiştirmez ve eksik saymaz" {
    TS_I18N_MISSING="$MISSING"
    i18n_init en
    _t "Kaldır"
    _t "$TR"
    [ "$TR" = "Remove" ]
    _t "Şu an: %s" "developer"
    _t "$TR"
    [ "$TR" = "Current: developer" ]
    [ ! -s "$MISSING" ]
}

@test "karşılığı olmayan metin raporlanır; kısa ve renkli metinler raporlanmaz" {
    TS_I18N_MISSING="$MISSING"
    i18n_init en
    _t "Çevrilmemiş bir cümle"
    [ "$TR" = "Çevrilmemiş bir cümle" ]
    _t "q"
    _t $'\033[1mKalın\033[0m'
    [ "$(cat "$MISSING")" = "Çevrilmemiş bir cümle" ]
}

# Dili sıfırdan belirle: detect_with LANG [LC_ALL] [i18n_init argümanı]
detect_with() {
    TS_LANG=""
    LANG="$1" LC_ALL="${2:-}"
    i18n_init "${3:-}"
}

@test "dil sistemden algılanır: tr* Türkçe, diğerleri İngilizce" {
    detect_with tr_TR.UTF-8
    [ "$TS_LANG" = tr ]
    detect_with en_US.UTF-8
    [ "$TS_LANG" = en ]
    detect_with C.UTF-8
    [ "$TS_LANG" = en ]
    detect_with en_US.UTF-8 tr_TR.UTF-8
    [ "$TS_LANG" = tr ]
}

@test "ayar sistem dilinden, açık seçim ayardan önce gelir" {
    settings_set language en
    detect_with tr_TR.UTF-8
    [ "$TS_LANG" = en ]
    detect_with tr_TR.UTF-8 "" tr
    [ "$TS_LANG" = tr ]
    settings_set language auto
    detect_with tr_TR.UTF-8
    [ "$TS_LANG" = tr ]
}

@test "evet/hayır sorusu dilin kısaltmasını gösterir, iki dilde de yanıt kabul eder" {
    i18n_init en
    run ui_confirm "Uygulansın mı?" e <<< "y"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Apply?"*"(Y/n)"* ]]
    run ui_confirm "Uygulansın mı?" h <<< "evet"
    [ "$status" -eq 0 ]
    i18n_init tr
    run ui_confirm "Uygulansın mı?" h <<< ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Uygulansın mı?"*"(e/H)"* ]]
}
