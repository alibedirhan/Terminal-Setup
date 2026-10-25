#!/usr/bin/env bats
# update: script'in kurduğu araçlar son sürüme yükselir; defter değişmez,
# kullanıcının kendi araçlarına dokunulmaz, kaldırınca iz kalmaz.

load '../helpers/common'

setup() {
    setup_fakesys
}

# Sahte lazygit release'ini yeni bir etikete taşı: new_lazygit_release v0.2.0
new_lazygit_release() {
    local tag="$1" dir="$FAKE_ROOT/releases/jesseduffield__lazygit"
    local work="$BATS_TEST_TMPDIR/build-new/pkg-lazygit"
    mkdir -p "$work"
    printf '#!/bin/sh\necho "lazygit %s (taklit)"\n' "$tag" > "$work/lazygit"
    chmod +x "$work/lazygit"
    rm -f "$dir"/assets/*
    tar -czf "$dir/assets/lazygit_${tag#v}_linux_x86_64.tar.gz" -C "$(dirname "$work")" pkg-lazygit
    echo "$tag" > "$dir/tag"
}

@test "yeni release kurulur, sürüm kaydedilir, defter değişmez" {
    ts install --components lazygit
    [ "$(lazygit)" = "lazygit v0.1.0 (taklit)" ]
    grep -qx $'lazygit\tv0.1.0' "$HOME/.terminal-setup/versions"
    cp "$HOME/.terminal-setup/ledger" "$BATS_TEST_TMPDIR/ledger-before"

    new_lazygit_release v0.2.0
    run ts update
    [ "$status" -eq 0 ]
    [[ "$output" == *"lazygit: v0.1.0 -> v0.2.0"* ]]
    [ "$(lazygit)" = "lazygit v0.2.0 (taklit)" ]
    grep -qx $'lazygit\tv0.2.0' "$HOME/.terminal-setup/versions"
    cmp "$HOME/.terminal-setup/ledger" "$BATS_TEST_TMPDIR/ledger-before"
}

@test "güncellenen araç kaldırınca iz bırakmaz" {
    ts install --components lazygit
    new_lazygit_release v0.2.0
    ts update
    run ts uninstall
    [ "$status" -eq 0 ]
    [[ "$output" == *"Sonuç: kalıntı yok."* ]]
    [ -z "$(cd "$HOME" && find . -mindepth 1 | grep -v '^./terminal-setup-kaldirilan-')" ]
}

@test "her şey güncelse hiçbir şey değişmez" {
    ts install --components lazygit
    cp "$HOME/.local/bin/lazygit" "$BATS_TEST_TMPDIR/bin-before"
    run ts update
    [ "$status" -eq 0 ]
    [[ "$output" == *"lazygit güncel (v0.1.0)"* ]]
    [[ "$output" == *"Her şey güncel."* ]]
    cmp "$HOME/.local/bin/lazygit" "$BATS_TEST_TMPDIR/bin-before"
}

@test "prova modunda yalnızca plan gösterilir" {
    ts install --components lazygit
    new_lazygit_release v0.2.0
    run ts --dry-run update
    [ "$status" -eq 0 ]
    [[ "$output" == *"lazygit v0.1.0 -> v0.2.0"* ]]
    [[ "$output" == *"Güncellenecek: lazygit"* ]]
    [ "$(lazygit)" = "lazygit v0.1.0 (taklit)" ]
    grep -qx $'lazygit\tv0.1.0' "$HOME/.terminal-setup/versions"
}

@test "kullanıcının kendi kurduğu araca dokunulmaz" {
    mkdir -p "$HOME/.local/bin"
    printf '#!/bin/sh\necho benim lazygit\n' > "$HOME/.local/bin/lazygit"
    chmod +x "$HOME/.local/bin/lazygit"
    ts install --components lazygit
    new_lazygit_release v0.2.0

    run ts update lazygit
    [ "$status" -eq 0 ]
    [[ "$output" == *"Terminal Setup ile kurulmadı"* ]]
    [ "$(lazygit)" = "benim lazygit" ]
}

@test "sürüm kaydı olmayan eski kurulum da güncellenir" {
    ts install --components lazygit
    rm "$HOME/.terminal-setup/versions"
    run ts update
    [ "$status" -eq 0 ]
    [[ "$output" == *"lazygit: bilinmiyor -> v0.1.0"* ]]
    grep -qx $'lazygit\tv0.1.0' "$HOME/.terminal-setup/versions"
}

@test "kurulu bir şey yoksa ya da bileşen bilinmiyorsa anlaşılır mesaj" {
    run ts update
    [ "$status" -eq 0 ]
    [[ "$output" == *"kurulmuş bir şey yok"* ]]

    ts install --components lazygit
    run ts update olmayan
    [ "$status" -eq 2 ]
    [[ "$output" == *"Bilinmeyen bileşen: olmayan"* ]]
}
