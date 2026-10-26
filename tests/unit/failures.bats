#!/usr/bin/env bats
# Hata yolları: başarısız işlemler başarı sayılmamalı, kullanıcı verisi korunmalı.

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
    TS_CURRENT_COMPONENT=bat
}

@test "tek bileşen kaldırma hatayı çağırana döndürür ve kaydı korur" {
    mkdir -p "$HOME/.config"
    ledger_add path "$HOME/.config"
    run runner_remove_component bat
    [ "$status" -ne 0 ]
    ledger_has path "$HOME/.config"
    [ -d "$HOME/.config" ]
}

@test "bileşen kaldırmada arşiv konumu ve taşınanlar ana kabukta tutulur" {
    act_userdata "$HOME/veri"
    echo "kullanici verisi" > "$HOME/veri"
    undo_component bat
    [ -n "$TS_ARCHIVE_DIR" ]
    [ "$(cat "$TS_ARCHIVE_DIR/veri")" = "kullanici verisi" ]
    [ "${UNDO_ARCHIVED[*]}" = "~/veri" ]
}

@test "arşive taşıma başarısızsa kullanıcı verisi ve defter kaydı korunur" {
    act_userdata "$HOME/veri"
    echo "kullanici verisi" > "$HOME/veri"
    TS_ARCHIVE_DIR="$HOME/arsiv"
    echo "dizin degil" > "$TS_ARCHIVE_DIR"
    run runner_remove_component bat
    [ "$status" -ne 0 ]
    [ "$(cat "$HOME/veri")" = "kullanici verisi" ]
    ledger_has userdata "$HOME/veri"
}

@test "arşive kopyalama başarısızsa son kullanıcı ayarı üzerine yazılmaz" {
    local rc="$HOME/.examplerc" saved
    echo "orijinal" > "$rc"
    act_rc_block "$rc" demo "x=1"
    echo "son kullanici ayari" >> "$rc"
    saved=$(ledger_find rcfile "$rc" | cut -f4)
    TS_ARCHIVE_DIR="$HOME/arsiv"
    echo "dizin degil" > "$TS_ARCHIVE_DIR"
    run undo_rcfile "$rc" "$saved"
    [ "$status" -ne 0 ]
    grep -qx "son kullanici ayari" "$rc"
    [ -f "$TS_FILES_DIR/$saved" ]
}

@test "orijinal dosya kopyalanamazsa ayar değiştirilmez" {
    local rc="$HOME/.examplerc"
    echo "orijinal" > "$rc"
    cp() { return 1; }
    run act_rc_block "$rc" demo "x=1"
    [ "$status" -ne 0 ]
    [ "$(cat "$rc")" = "orijinal" ]
    ! ledger_has rcfile "$rc"
}

@test "blok yazımı başarısızsa işlem başarısız döner" {
    local rc="$HOME/.examplerc"
    echo "orijinal" > "$rc"
    mkdir "$rc.ts-tmp"
    run act_rc_block "$rc" demo "x=1"
    [ "$status" -ne 0 ]
    [ "$(cat "$rc")" = "orijinal" ]
    ! ledger_file_has_blocks "$rc"
}

@test "paket kaldırma simülasyonu başarısızsa hiçbir paket kaldırılmaz" {
    act_pkg bat
    _pkg_simulate_purge() { return 1; }
    run pkg_purge_owned bat libgit2
    [ "$status" -ne 0 ]
    pkg_is_installed bat
    pkg_is_installed libgit2
}

@test "yarım kalan apt kurulumunun getirdiği bağımlılıklar da kaydedilir" {
    PKG_APT_UPDATED=1
    _pkg_apt() {
        printf 'bat\nlibgit2\n' >> "$FAKE_ROOT/dpkg.txt"
        return 1
    }
    run act_pkg bat
    [ "$status" -ne 0 ]
    ledger_has pkg bat
    ledger_has pkg libgit2
}

@test "tema sıfırlama başarısızsa seçili tema ve defter kaydı korunur" {
    TS_CURRENT_COMPONENT=theme
    mkdir -p "$HOME/.config"
    ledger_add path "$HOME/.config"
    settings_set theme nord
    run appearance_reset
    [ "$status" -ne 0 ]
    [ "$(settings_get theme)" = nord ]
    ledger_has path "$HOME/.config"
}

@test "başarısız kurulumdan sonra CLI tema uygulamaz" {
    runner_prepare() { return 1; }
    theme_apply() { touch "$FAKE_ROOT/tema-uygulandi"; }
    run cli_install --components bat --theme nord
    [ "$status" -ne 0 ]
    [ ! -e "$FAKE_ROOT/tema-uygulandi" ]
}

@test "başarısız kurulumdan sonra sihirbaz tema uygulamaz" {
    runner_prepare() { return 1; }
    theme_apply() { touch "$FAKE_ROOT/tema-uygulandi"; }
    TS_ASSUME_YES=1
    run tui_install_confirmed nord bat
    [ "$status" -ne 0 ]
    [ ! -e "$FAKE_ROOT/tema-uygulandi" ]
}

@test "CLI tema hatasını başarı olarak döndürmez" {
    runner_install() { return 0; }
    theme_apply() { return 1; }
    run cli_install --components bat --theme nord
    [ "$status" -ne 0 ]
}

@test "gerçek apt simülasyonu hatası paket kaldırmayı durdurur" {
    act_pkg bat
    apt-get() { return 100; }
    run pkg_purge_owned bat libgit2
    [ "$status" -ne 0 ]
    pkg_is_installed bat
    pkg_is_installed libgit2
    ! grep -q 'apt-get .*purge' "$FAKE_ROOT/apt.log"
}

@test "kullanıcının bozuk sembolik bağlantısı yönetilen dosyayla değiştirilmez" {
    ln -s "$HOME/olmayan" "$HOME/ayar"
    run act_write_file "$HOME/ayar" "yeni"
    [ "$status" -ne 0 ]
    [ -L "$HOME/ayar" ]
    [ ! -e "$HOME/olmayan" ]
}

@test "başlangıç dosyası kullanıcının bozuk sembolik bağlantısını izlemez" {
    ln -s "$HOME/olmayan" "$HOME/ayar"
    act_seed_file "$HOME/ayar" "yeni"
    [ -L "$HOME/ayar" ]
    [ ! -e "$HOME/olmayan" ]
    ! ledger_has userdata "$HOME/ayar"
}

@test "ikili kurulum kullanıcının bozuk sembolik bağlantısını değiştirmez" {
    mkdir -p "$TS_BIN_DIR"
    ln -s "$HOME/olmayan" "$TS_BIN_DIR/arac"
    echo "ikili" > "$BATS_TEST_TMPDIR/ikili"
    run act_install_bin "$BATS_TEST_TMPDIR/ikili" arac
    [ "$status" -ne 0 ]
    [ -L "$TS_BIN_DIR/arac" ]
}

@test "kullanıcının mevcut boş klasörüne depo klonlanmaz" {
    mkdir "$HOME/depo"
    run act_clone https://example.invalid/repo.git "$HOME/depo"
    [ "$status" -ne 0 ]
    [ -d "$HOME/depo" ]
    [ -z "$(ls -A "$HOME/depo")" ]
}

@test "noktalı yol korunan kullanıcı dizinini silemez" {
    mkdir -p "$HOME/.config" "$HOME/.local"
    echo "kullanici verisi" > "$HOME/.local/koru"
    run undo_path "$HOME/.config/../.local"
    [ "$status" -ne 0 ]
    [ "$(cat "$HOME/.local/koru")" = "kullanici verisi" ]
}

@test "aynı saniyedeki iki arşiv önceki kullanıcı verisinin üzerine yazmaz" {
    local first
    ts_stamp() { echo sabit; }
    echo "ilk veri" > "$HOME/veri"
    undo_userdata "$HOME/veri"
    first="$TS_ARCHIVE_DIR"
    TS_ARCHIVE_DIR=""
    echo "ikinci veri" > "$HOME/veri"
    undo_userdata "$HOME/veri"
    [ "$first" != "$TS_ARCHIVE_DIR" ]
    [ "$(cat "$first/veri")" = "ilk veri" ]
    [ "$(cat "$TS_ARCHIVE_DIR/veri")" = "ikinci veri" ]
}
