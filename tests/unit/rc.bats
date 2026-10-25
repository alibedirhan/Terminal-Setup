#!/usr/bin/env bats
# Yönetilen bloklar ve ayar dosyalarının geri yüklenmesi

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
    TS_CURRENT_COMPONENT=test
    RC="$HOME/.examplerc"
}

@test "olmayan dosyaya blok eklenir; orijinal 'yok' olarak kaydedilir" {
    act_rc_block "$RC" demo "echo merhaba"
    grep -qxF "# >>> terminal-setup:demo >>>" "$RC"
    grep -qxF "echo merhaba" "$RC"
    [[ "$(ledger_find rcfile "$RC")" == *NONE ]]
}

@test "top bloğu mevcut içeriğin önüne eklenir" {
    printf 'kullanici satiri\n' > "$RC"
    act_rc_block "$RC" demo "x=1" top
    [ "$(head -1 "$RC")" = "# >>> terminal-setup:demo >>>" ]
    [ "$(tail -1 "$RC")" = "kullanici satiri" ]
}

@test "aynı blok iki kez eklenince tek blok ve tek kayıt olur" {
    act_rc_block "$RC" demo "x=1"
    act_rc_block "$RC" demo "x=1"
    [ "$(grep -c 'terminal-setup:demo >>>' "$RC")" -eq 1 ]
    [ "$(ledger_lines | awk -F'\t' '$2 == "rcblock"' | wc -l)" -eq 1 ]
}

@test "içerik değişince blok güncellenir" {
    act_rc_block "$RC" demo "x=1"
    act_rc_block "$RC" demo "x=2"
    [ "$(rc_block_content "$RC" demo)" = "x=2" ]
    [ "$(grep -c 'terminal-setup:demo >>>' "$RC")" -eq 1 ]
}

@test "blok çıkarılınca dosya bayt bayt eski haline döner" {
    printf 'a\nb\n' > "$RC"
    cp "$RC" "$BATS_TEST_TMPDIR/orig"
    act_rc_block "$RC" demo "x=1"
    rc_strip_block "$RC" demo
    cmp "$RC" "$BATS_TEST_TMPDIR/orig"
}

@test "yeni satırla bitmeyen dosyada blok ayrı satırda başlar" {
    printf 'son satir' > "$RC"
    act_rc_block "$RC" demo "x=1"
    grep -qxF "son satir" "$RC"
    grep -qxF "# >>> terminal-setup:demo >>>" "$RC"
}

@test "undo_rcfile: değişiklik yoksa orijinal arşivlenmeden geri konur" {
    printf 'orijinal\n' > "$RC"
    act_rc_block "$RC" demo "x=1"
    rc_strip_block "$RC" demo
    local saved
    saved=$(ledger_find rcfile "$RC" | cut -f4)
    undo_rcfile "$RC" "$saved"
    [ "$(cat "$RC")" = "orijinal" ]
    [ -z "$TS_ARCHIVE_DIR" ] || [ ! -e "$TS_ARCHIVE_DIR/.examplerc" ]
}

@test "undo_rcfile: kurulumdan sonraki kullanıcı değişikliği arşivlenir" {
    printf 'orijinal\n' > "$RC"
    act_rc_block "$RC" demo "x=1"
    echo "kullanicinin yeni satiri" >> "$RC"
    local saved
    saved=$(ledger_find rcfile "$RC" | cut -f4)
    undo_rcfile "$RC" "$saved"
    [ "$(cat "$RC")" = "orijinal" ]
    grep -q "kullanicinin yeni satiri" "$TS_ARCHIVE_DIR/.examplerc"
}

@test "undo_rcfile: kurulumdan önce olmayan dosya silinir" {
    act_rc_block "$RC" demo "x=1"
    undo_rcfile "$RC" NONE
    [ ! -e "$RC" ]
}

@test "act_zsh_snippet zsh.d altına sıra numaralı dosya yazar" {
    act_zsh_snippet 60 demo 'alias x=y'
    grep -qxF "alias x=y" "$TS_CONFIG_DIR/zsh.d/60-demo.zsh"
    ledger_has path "$TS_CONFIG_DIR/zsh.d/60-demo.zsh"
}

@test "act_write_file kullanıcının dosyasının üzerine yazmaz" {
    echo "benim" > "$HOME/dosya"
    run act_write_file "$HOME/dosya" "yeni"
    [ "$status" -ne 0 ]
    [ "$(cat "$HOME/dosya")" = "benim" ]
}
