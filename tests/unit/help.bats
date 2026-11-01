#!/usr/bin/env bats
# Alt+H: yazılan komutun kısa yardımı (tldr), sistem dilinde

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
    ZSH=$(PATH=/usr/bin:/bin command -v zsh) || skip "gerçek zsh yok"
    FIX="$BATS_TEST_TMPDIR/fix"
    mkdir -p "$FIX" "$BATS_TEST_TMPDIR/bin"
    # tldr-hs biçimi (Ubuntu 22.04): başlık, renkli satırlar, " - " ile örnekler
    printf '%s\n' tar '' $'\e[0mArşivleme aracı.' 'Daha fazla bilgi için: https://www.gnu.org/software/tar.' '' \
        $' - \e[32mBir arşiv oluştur ve dosyaya yaz:' $'   \e[33mtar cf hedef.tar dosya1\e[0m' '' \
        ' - Arşivi aç:' '   tar xf kaynak.tar' > "$FIX/tr-tar"
    # tealdeer biçimi: girintili, örnekler ile komutlar arasında boş satır
    printf '%s\n' '' '  Archiving utility.' '  Often combined with gzip.' '  More information: <https://www.gnu.org/software/tar>.' '' \
        '  [c]reate an archive:' '' '      tar cf target.tar file1' '' \
        '  E[x]tract an archive:' '' '      tar xf source.tar' '' \
        '  List contents:' '' '      tar tf source.tar' '' \
        '  Append files:' '' '      tar rf target.tar file' '' \
        '  Fifth example:' '' '      tar --fifth' '' > "$FIX/en-tar"
    # Sahte tldr: -L dili ve komuta göre sayfa; yoksa 1
    cat > "$BATS_TEST_TMPDIR/bin/tldr" <<EOF
#!/bin/sh
lang=en
[ "\$1" = -L ] && { lang=\$2; shift 2; }
[ "\$1" = -- ] && shift
f="$FIX/\$lang-\$1"
[ -f "\$f" ] && exec cat "\$f"
exit 1
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/tldr"
}

# Yardımı çiz: help_for "KOMUT SATIRI" [DİL] -> output (renk kodsuz)
help_for() {
    i18n_init "${2:-tr}"
    _tldr_help_messages
    printf '%s\n' "$REPLY" > "$BATS_TEST_TMPDIR/msg.zsh"
    run env COLUMNS="${COLS:-80}" PATH="$BATS_TEST_TMPDIR/bin:/usr/bin:/bin" "$ZSH" -f -c "
        source '$BATS_TEST_TMPDIR/msg.zsh'; source '$REPO_ROOT/zsh/help.zsh'
        zle() { :; }; BUFFER=${1@Q}; _ts_help; print -r -- \"[\$BUFFER]\""
    output=$(sed 's/\x1b\[[0-9;]*m//g' <<< "$output")
    mapfile -t lines <<< "$output"
}

@test "sistem dilindeki sayfa: açıklama ve örnekler; satır olduğu gibi kalır" {
    help_for "tar -xf arşiv.tar"
    [ "${lines[0]}" = "  tar — Arşivleme aracı." ]
    [ "${lines[1]}" = "  • Bir arşiv oluştur ve dosyaya yaz" ]
    [ "${lines[2]}" = "    tar cf hedef.tar dosya1" ]
    [ "${lines[3]}" = "  • Arşivi aç" ]
    [ "${lines[-1]}" = "[tar -xf arşiv.tar]" ]
}

@test "sayfa sistem dilinde yoksa İngilizcesi; tealdeer biçimi; en çok dört örnek" {
    rm "$FIX/tr-tar"
    help_for "sudo tar"
    [ "${lines[0]}" = "  tar — Archiving utility. Often combined with gzip." ]
    [ "${lines[1]}" = "  • [c]reate an archive" ]
    [ "${lines[2]}" = "    tar cf target.tar file1" ]
    [ "$(grep -c '^  • ' <<< "$output")" -eq 4 ]
    [[ "$output" != *"--fifth"* && "$output" != *"https"* ]]
}

@test "İngilizce sistemde -L verilmez; sayfası olmayan komut için ileti" {
    help_for "olmayan-komut x" en
    [ "${lines[0]}" = "  No help page for olmayan-komut." ]
    help_for "olmayan-komut x"
    [ "${lines[0]}" = "  olmayan-komut için yardım sayfası yok." ]
}

@test "önekler atlanır; boş satırda hiçbir şey yazılmaz" {
    help_for "env FOO=1 nice tar"
    [ "${lines[0]}" = "  tar — Arşivleme aracı." ] || { echo "$output"; false; }
    help_for "   "
    [ "${#lines[@]}" -eq 1 ]
}

@test "dar terminalde açıklama kısaltılır" {
    printf '%s\n' tar '' "$(printf 'uzun%.0s ' {1..40})" '' ' - a:' '   b' > "$FIX/tr-tar"
    COLS=40 help_for tar
    local w
    w=$(LC_ALL=C.UTF-8 awk 'NR == 1 { print length($0) }' <<< "$output")
    ((w <= 40))
    [[ "${lines[0]}" == *"…" ]]
}

@test "C yerel ayarında da Türkçe sayfa bozulmadan kısaltılır" {
    printf '%s\n' tar '' "$(printf 'çğüşöı%.0s' {1..20})" '' ' - a:' '   b' > "$FIX/tr-tar"
    i18n_init tr
    _tldr_help_messages
    printf '%s\n' "$REPLY" > "$BATS_TEST_TMPDIR/msg.zsh"
    run env LC_ALL=C LANG=C COLUMNS=40 PATH="$BATS_TEST_TMPDIR/bin:/usr/bin:/bin" "$ZSH" -f -c "
        source '$BATS_TEST_TMPDIR/msg.zsh'; source '$REPO_ROOT/zsh/help.zsh'
        zle() { :; }; BUFFER=tar; _ts_help"
    output=$(sed 's/\x1b\[[0-9;]*m//g' <<< "$output")
    # Geçerli UTF-8 ve en çok 40 sütun
    ! LC_ALL=C.UTF-8 grep -axv ".*" <<< "$output"
    [ "$(LC_ALL=C.UTF-8 awk 'NR == 1 { print length($0) }' <<< "$output")" -le 40 ]
}

@test "Alt+H iki tuş düzeninde de bağlanır" {
    run "$ZSH" -f -c "typeset -A _ts_hmsg; source '$REPO_ROOT/zsh/help.zsh'; bindkey -M emacs '^[h'; bindkey -M viins '^[h'"
    [[ "${lines[0]}" == *"_ts_help" && "${lines[1]}" == *"_ts_help" ]]
}
