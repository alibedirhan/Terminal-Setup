#!/usr/bin/env bats
# git ayarları, dconf anahtarları, giriş kabuğu ve geri alınmaları

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
    TS_CURRENT_COMPONENT=test
}

@test "gitcfg: önceden olmayan ayar silinir, boş bölüm kalmaz" {
    act_gitcfg delta.navigate true
    [ "$(git config --global --get delta.navigate)" = "true" ]
    undo_gitcfg delta.navigate NONE
    ! git config --global --get delta.navigate || false
    ! grep -q '\[delta\]' "$HOME/.gitconfig"
}

@test "gitcfg: önceki değere dönülür" {
    git config --global core.pager less
    act_gitcfg core.pager delta
    local prev
    prev=$(ledger_find gitcfg core.pager | cut -f4)
    undo_gitcfg core.pager "$prev"
    [ "$(git config --global --get core.pager)" = "less" ]
}

@test "gitcfg: ikinci değişiklik ilk önceki değeri ezmez" {
    git config --global core.pager less
    act_gitcfg core.pager delta
    act_gitcfg core.pager bat
    [ "$(ledger_decode "$(ledger_find gitcfg core.pager | cut -f4)")" = "less" ]
}

@test "prova modunda git kurulu olmasa da plan gösterilir" {
    rm -f "$FAKE_ROOT/sysbin/git"
    export PATH="${PATH//$REPO_ROOT\/tests\/helpers\/bin:/}"
    ! has_cmd git || false
    TS_DRY_RUN=1
    run act_gitcfg core.pager delta
    [ "$status" -eq 0 ]
    [[ "$output" == *"[plan] git config --global core.pager"* ]]
}

@test "dconf: önceden olmayan anahtar sıfırlanır" {
    act_dconf_key /org/test/key "'x'"
    [ "$(dconf read /org/test/key)" = "'x'" ]
    undo_dconf /org/test/key NONE
    [ -z "$(dconf read /org/test/key)" ]
}

@test "dconf: önceki değere dönülür" {
    dconf write /org/test/key "'eski'"
    act_dconf_key /org/test/key "'yeni'"
    undo_dconf /org/test/key "$(ledger_find dconf /org/test/key | cut -f4)"
    [ "$(dconf read /org/test/key)" = "'eski'" ]
}

@test "giriş kabuğu değişir ve geri alınır" {
    touch "$FAKE_ROOT/pkgbin/zsh"
    act_login_shell "$FAKE_ROOT/pkgbin/zsh"
    [ "$(login_shell)" = "$FAKE_ROOT/pkgbin/zsh" ]
    undo_shell /bin/bash
    [ "$(login_shell)" = "/bin/bash" ]
}

@test "/etc/shells içinde olmayan kabuk reddedilir" {
    run act_login_shell /usr/bin/olmayan
    [ "$status" -ne 0 ]
    [ "$(login_shell)" = "/bin/bash" ]
}

@test "korunan yollar asla silinmez" {
    run undo_path "$HOME"
    [ "$status" -ne 0 ]
    [ -d "$HOME" ]
    run undo_path /etc
    [ "$status" -ne 0 ]
}

@test "dolu ortak dizin silinmez, boş olan silinir" {
    mkdir -p "$HOME/ortak" "$HOME/bos"
    touch "$HOME/ortak/kullanici-dosyasi"
    undo_dir "$HOME/ortak"
    undo_dir "$HOME/bos"
    [ -d "$HOME/ortak" ]
    [ ! -d "$HOME/bos" ]
}

@test "boş kullanıcı verisi dosyası arşive gitmez, silinir" {
    mkdir -p "$HOME/.config/lazygit"
    : > "$HOME/.config/lazygit/config.yml"
    undo_userdata "$HOME/.config/lazygit/config.yml"
    [ ! -e "$HOME/.config/lazygit/config.yml" ]
    [ -z "$TS_ARCHIVE_DIR" ] || [ ! -e "$TS_ARCHIVE_DIR/.config/lazygit" ]
}

@test "kullanıcı verisi silinmez, arşive taşınır" {
    mkdir -p "$HOME/.local/share/zoxide"
    echo veri > "$HOME/.local/share/zoxide/db"
    undo_userdata "$HOME/.local/share/zoxide"
    [ ! -e "$HOME/.local/share/zoxide" ]
    [ "$(cat "$TS_ARCHIVE_DIR/.local/share/zoxide/db")" = "veri" ]
}
