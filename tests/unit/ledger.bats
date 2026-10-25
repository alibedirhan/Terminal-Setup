#!/usr/bin/env bats
# Defter: kayıt ekleme, tekillik, silme, sürüm başlığı

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
}

@test "ledger_init sürüm başlığıyla dosya oluşturur" {
    ledger_init
    [ "$(head -1 "$TS_LEDGER")" = "# terminal-setup ledger v1" ]
}

@test "tanınmayan defter sürümü reddedilir" {
    mkdir -p "$TS_STATE_DIR"
    echo "# terminal-setup ledger v9" > "$TS_LEDGER"
    run ledger_init
    [ "$status" -ne 0 ]
}

@test "kayıt eklenir ve bulunur" {
    TS_CURRENT_COMPONENT=bat
    ledger_add pkg bat
    run ledger_find pkg bat
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf 'bat\tpkg\tbat')" ]
}

@test "tekil türlerde ilk kayıt korunur (önceki değer ezilmez)" {
    TS_CURRENT_COMPONENT=delta
    ledger_add gitcfg core.pager NONE
    ledger_add gitcfg core.pager "$(ledger_encode less)"
    [ "$(ledger_count)" -eq 1 ]
    [[ "$(ledger_find gitcfg core.pager)" == *NONE ]]
}

@test "dir kaydı farklı bileşenler için ayrı ayrı tutulur" {
    TS_CURRENT_COMPONENT=a; ledger_add dir "$HOME/x"
    TS_CURRENT_COMPONENT=b; ledger_add dir "$HOME/x"
    [ "$(ledger_count)" -eq 2 ]
}

@test "ledger_lines bileşene göre süzer, ledger_components sırayı korur" {
    TS_CURRENT_COMPONENT=zsh; ledger_add pkg zsh
    TS_CURRENT_COMPONENT=bat; ledger_add pkg bat
    TS_CURRENT_COMPONENT=zsh; ledger_add path "$HOME/a"
    [ "$(ledger_lines zsh | wc -l)" -eq 2 ]
    [ "$(ledger_components | tr '\n' ' ')" = "zsh bat " ]
}

@test "ledger_remove_line yalnızca ilk eşleşmeyi siler" {
    TS_CURRENT_COMPONENT=a
    ledger_add dir "$HOME/x"
    ledger_add dir "$HOME/x"
    ledger_remove_line "$(printf 'a\tdir\t%s' "$HOME/x")"
    [ "$(ledger_count)" -eq 1 ]
}

@test "kodlama sekme ve yeni satırı korur" {
    local v=$'a\tb\nc'
    [ "$(ledger_decode "$(ledger_encode "$v")")" = "$v" ]
}

@test "prova modunda deftere yazılmaz" {
    TS_DRY_RUN=1
    ledger_add pkg bat
    [ ! -f "$TS_LEDGER" ]
}
