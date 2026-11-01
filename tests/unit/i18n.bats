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

@test "üretilen dosyanın açıklamaları çevrilir; kod ve bilinmeyen metin aynen kalır" {
    i18n_init en
    I18N_EN["Deneme açıklaması"]="Sample comment"
    I18N_EN["Bölüm"]="Section"
    I18N_EN["sondaki açıklama"]="trailing comment"
    local src
    src=$'#!/usr/bin/env zsh\n# Deneme açıklaması\n    # Deneme açıklaması\n# --- Bölüm ----------------\n'
    src+=$'set -g status-style "bg=#2E3440,fg=#D8DEE9"  # sondaki açıklama\n'
    src+=$'set -g status-left "#[bold] #S "\n# Bilinmeyen metin\n#\nalias x=\'echo # Deneme açıklaması\''
    i18n_comments '#' "$src"
    [ "$REPLY" = $'#!/usr/bin/env zsh\n# Sample comment\n    # Sample comment\n# --- Section --------------\n''set -g status-style "bg=#2E3440,fg=#D8DEE9"  # trailing comment'$'\nset -g status-left "#[bold] #S "\n# Bilinmeyen metin\n#\nalias x=\'echo # Deneme açıklaması\'' ]
    # Bölüm çizgisi aynı genişlikte kalır
    [ "$(sed -n 4p <<< "$REPLY" | LC_ALL=C.UTF-8 wc -m)" -eq "$(sed -n 4p <<< "$src" | LC_ALL=C.UTF-8 wc -m)" ]
    # Lua açıklaması
    i18n_file_comments "$HOME/x.lua" "-- Deneme açıklaması"
    [ "$REPLY" = "-- Sample comment" ]
}

@test "Türkçede üretilen dosya değişmez; İngilizcede yalnızca Türkçe kalan açıklama eksik sayılır" {
    local src=$'# Kişilik: retro  Tema: Nord\n# Bilinmeyen metin\n# Çevrilmemiş açıklama'
    i18n_init tr
    i18n_comments '#' "$src"
    [ "$REPLY" = "$src" ]
    i18n_init en
    TS_I18N_MISSING="$BATS_TEST_TMPDIR/missing"
    i18n_comments '#' $'# Personality: retro  Theme: Nord\n# Bilinmeyen metin\n# Çevrilmemiş açıklama'
    [ "$(cat "$TS_I18N_MISSING")" = "Çevrilmemiş açıklama" ]
}

@test "zsh parçası ve tema başlığı sistem dilinde yazılır" {
    i18n_init en
    TS_CURRENT_COMPONENT=demo
    act_zsh_snippet 60 demo $'# Geçmiş\necho x'
    [ "$(cat "$TS_CONFIG_DIR/zsh.d/60-demo.zsh")" = $'# demo — managed by Terminal Setup\n# History\necho x' ]
    theme_load nord
    style_file_header
    [ "$REPLY" = $'# Terminal Setup tarafından temadan ve kişilikten üretilir; elle düzenlemeyin.\n# Personality: arctic  Theme: Nord' ]
    act_write_file "$TS_CONFIG_DIR/demo.conf" "$REPLY"
    [ "$(head -1 "$TS_CONFIG_DIR/demo.conf")" = "# Generated by Terminal Setup from the theme and personality; do not edit." ]
}

@test "arşiv klasörünün ve raporun adı sistem dilinde" {
    i18n_init en
    undo_archive_init
    [[ "$TS_ARCHIVE_DIR" == "$HOME"/terminal-setup-removed-* ]]
    TS_ARCHIVE_DIR=""
    i18n_init tr
    undo_archive_init
    [[ "$TS_ARCHIVE_DIR" == "$HOME"/terminal-setup-kaldirilan-* ]]
    # İki dildeki arşiv de fotoğrafa girmez
    mkdir -p "$HOME/terminal-setup-removed-x" "$HOME/terminal-setup-kaldirilan-y"
    ! baseline_list_paths | grep -q "terminal-setup-"
}
