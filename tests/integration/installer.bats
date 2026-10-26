#!/usr/bin/env bats
# install.sh: sürüm paketini indirir, SHA-256 doğrular, geçici dizinden çalıştırır

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

setup() {
    unset LC_ALL LC_MESSAGES
    REL="$BATS_TEST_TMPDIR/release"
    mkdir -p "$REL"
    VERSION=$(cat "$REPO_ROOT/VERSION")
    NAME="terminal-setup-$VERSION"
    # Çalışma dizinindeki dosyalarla paket (testler hariç, release'deki gibi)
    tar -czf "$REL/$NAME.tar.gz" -C "$REPO_ROOT/.." --exclude=.git --exclude=tests \
        --transform "s|^$(basename "$REPO_ROOT")|$NAME|" "$(basename "$REPO_ROOT")"
    (cd "$REL" && sha256sum "$NAME.tar.gz" > "$NAME.tar.gz.sha256")
    export HOME="$BATS_TEST_TMPDIR/home" TS_LANG=tr
    mkdir -p "$HOME"
}

@test "doğrulanan paket çalıştırılır ve geçici dizin silinir" {
    run env TS_RELEASE="v$VERSION" TS_RELEASE_BASE="file://$REL" TMPDIR="$BATS_TEST_TMPDIR" \
        bash "$REPO_ROOT/install.sh" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"SHA-256 doğrulandı"* ]]
    [[ "$output" == *"Terminal Setup $VERSION"* ]]
    [ -z "$(ls -d "$BATS_TEST_TMPDIR"/terminal-setup-install.* 2>/dev/null)" ]
}

@test "sağlama tutmazsa çalıştırılmaz" {
    echo "0000000000000000000000000000000000000000000000000000000000000000  x" > "$REL/$NAME.tar.gz.sha256"
    run env TS_RELEASE="v$VERSION" TS_RELEASE_BASE="file://$REL" bash "$REPO_ROOT/install.sh" --version
    [ "$status" -ne 0 ]
    [[ "$output" == *"SHA-256 doğrulaması başarısız"* ]]
    [[ "$output" != *"Terminal Setup $VERSION"* ]]
}

@test "olmayan sürüm anlaşılır hata verir" {
    run env TS_RELEASE="v0.0.0" TS_RELEASE_BASE="file://$REL" bash "$REPO_ROOT/install.sh" --version
    [ "$status" -ne 0 ]
    [[ "$output" == *"İndirilemedi"* ]]
}

@test "mesajlar programla aynı dil kuralına uyar" {
    run env TS_RELEASE="v$VERSION" TS_RELEASE_BASE="file://$REL" TMPDIR="$BATS_TEST_TMPDIR" \
        bash "$REPO_ROOT/install.sh" --lang en --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"SHA-256 verified"* ]]
    run env -u TS_LANG LANG=en_US.UTF-8 TS_RELEASE="v$VERSION" TS_RELEASE_BASE="file://$REL" \
        TMPDIR="$BATS_TEST_TMPDIR" bash "$REPO_ROOT/install.sh" --version
    [[ "$output" == *"Downloading Terminal Setup"* ]]
    run env -u TS_LANG LANG=tr_TR.UTF-8 TS_RELEASE="v$VERSION" TS_RELEASE_BASE="file://$REL" \
        TMPDIR="$BATS_TEST_TMPDIR" bash "$REPO_ROOT/install.sh" --version
    [[ "$output" == *"indiriliyor"* ]]
}
