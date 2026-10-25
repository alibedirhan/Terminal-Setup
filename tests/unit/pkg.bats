#!/usr/bin/env bats
# Paket eylemleri: fark tabanlı kayıt ve güvenli kaldırma

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
    TS_CURRENT_COMPONENT=bat
}

@test "act_pkg istenen paketi ve bağımlılığını kaydeder" {
    act_pkg bat
    pkg_is_installed bat
    pkg_is_installed libgit2
    ledger_has pkg bat
    ledger_has pkg libgit2
}

@test "önceden kurulu paket kaydedilmez ve apt çağrılmaz" {
    echo bat >> "$FAKE_ROOT/dpkg.txt"
    act_pkg bat
    ! ledger_has pkg bat
    [ ! -f "$FAKE_ROOT/apt.log" ]
}

@test "apt hatası başarısız döner" {
    touch "$FAKE_ROOT/apt-fail"
    run act_pkg bat
    [ "$status" -ne 0 ]
}

@test "pkg_purge_owned yalnızca verilen paketleri siler" {
    echo vim >> "$FAKE_ROOT/dpkg.txt"
    act_pkg bat
    pkg_purge_owned bat libgit2
    ! pkg_is_installed bat
    ! pkg_is_installed libgit2
    pkg_is_installed vim
}

@test "başka bir pakete gerekli bağımlılık silinmez" {
    act_pkg bat
    # Kullanıcı sonradan libgit2'ye bağlı bir paket kuruyor
    echo "userapp: libgit2" >> "$FAKE_ROOT/deps"
    echo userapp >> "$FAKE_ROOT/dpkg.txt"
    pkg_purge_owned bat libgit2
    ! pkg_is_installed bat
    pkg_is_installed libgit2
    pkg_is_installed userapp
    [ "${PKG_SKIPPED[*]}" = "libgit2" ]
}

@test "prova modunda apt çağrılmaz" {
    TS_DRY_RUN=1
    run act_pkg bat
    [ "$status" -eq 0 ]
    [[ "$output" == *"[plan] apt-get install bat"* ]]
    [ ! -f "$FAKE_ROOT/apt.log" ]
}
