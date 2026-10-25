#!/usr/bin/env bats
# Güncelleme eylemleri: tarif toplama ve klonlanmış depoların güncellenmesi
# (gerçek git ile, yerel depolar üzerinde; ağa çıkılmaz)

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
    REAL_GIT="$FAKE_ROOT/sysbin/git"
    ORIGIN="$BATS_TEST_TMPDIR/origin"
    DEST="$HOME/.oh-my-zsh"
    "$REAL_GIT" init -q "$ORIGIN"
    echo bir > "$ORIGIN/dosya"
    "$REAL_GIT" -C "$ORIGIN" add dosya
    "$REAL_GIT" -C "$ORIGIN" commit -qm bir
    "$REAL_GIT" clone -q --depth 1 "file://$ORIGIN" "$DEST"
    TS_CURRENT_COMPONENT=ohmyzsh
    ledger_add path "$DEST"
}

new_origin_commit() {
    echo iki > "$ORIGIN/dosya"
    "$REAL_GIT" -C "$ORIGIN" commit -qam iki
}

@test "bileşen tarifleri prova modunda toplanır, hiçbir şey değişmez" {
    upgrade_recipes zsh-plugins
    [ "${#ACT_RECIPES[@]}" -eq 2 ]
    [[ "${ACT_RECIPES[0]}" == git$'\t'https://github.com/zsh-users/zsh-autosuggestions.git$'\t'* ]]
    upgrade_recipes lazygit
    [ "${ACT_RECIPES[0]}" = $'gh\tjesseduffield/lazygit\t_[Ll]inux_x86_64\\.tar\\.gz$\t_[Ll]inux_arm64\\.tar\\.gz$\tlazygit\tlazygit' ]
    [ "$TS_DRY_RUN" = 0 ]
    [ "$ACT_RECIPE_CAPTURE" = 0 ]
    [ ! -e "$HOME/.local/bin/lazygit" ]
    [ "$(ledger_count)" -eq 1 ]
}

@test "klonlanmış depo son commit'e getirilir" {
    new_origin_commit
    act_upgrade_git "file://$ORIGIN" "$DEST"
    [ "$UPG_RESULT" = updated ]
    [ "$(cat "$DEST/dosya")" = iki ]
    [ "$("$REAL_GIT" -C "$DEST" rev-parse HEAD)" = "$("$REAL_GIT" -C "$ORIGIN" rev-parse HEAD)" ]
}

@test "depo güncelse dokunulmaz" {
    act_upgrade_git "file://$ORIGIN" "$DEST"
    [ "$UPG_RESULT" = current ]
}

@test "elle değiştirilmiş depo güncellenmez" {
    new_origin_commit
    echo benim > "$DEST/dosya"
    act_upgrade_git "file://$ORIGIN" "$DEST"
    [ "$UPG_RESULT" = skipped ]
    [ "$(cat "$DEST/dosya")" = benim ]
}

@test "script'e ait olmayan depoya dokunulmaz" {
    ledger_remove_line "$(ledger_find path "$DEST")"
    new_origin_commit
    act_upgrade_git "file://$ORIGIN" "$DEST"
    [ "$UPG_RESULT" = skipped ]
    [ "$(cat "$DEST/dosya")" = bir ]
}

@test "prova modunda depo değişmez" {
    new_origin_commit
    TS_DRY_RUN=1
    act_upgrade_git "file://$ORIGIN" "$DEST"
    [ "$UPG_RESULT" = planned ]
    [ "$(cat "$DEST/dosya")" = bir ]
}
