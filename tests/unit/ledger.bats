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

@test "yalnızca paket ve giriş kabuğu kayıtları yönetici yetkisi ister" {
    TS_CURRENT_COMPONENT=fzf
    ledger_add path "$HOME/.local/bin/fzf"
    ledger_add dconf /org/demo NONE
    run ledger_needs_root
    [ "$status" -ne 0 ]
    TS_CURRENT_COMPONENT=zsh
    ledger_add shell /bin/bash
    ledger_needs_root
}

@test "kullanıcı verisi kaydı bileşen başına tekildir" {
    TS_CURRENT_COMPONENT=btop
    ledger_add userdata "$HOME/.config/btop/btop.conf"
    ledger_add userdata "$HOME/.config/btop/btop.conf"
    TS_CURRENT_COMPONENT=theme
    ledger_add userdata "$HOME/.config/btop/btop.conf"
    [ "$(ledger_count)" -eq 2 ]
    [ "$(ledger_lines theme | wc -l)" -eq 1 ]
}

# Defter satırı: row bileşen tür yol
row() { local IFS=$'\t'; printf '%s\n' "$*"; }

@test "6.x'in ayar dizini kayıtları bugünkü kayıtlara çevrilir, gerisi aynen kalır" {
    local h="$HOME"
    mkdir -p "$TS_STATE_DIR"
    {
        echo "# terminal-setup ledger v1"
        row lazygit glob "$h/.config/lazygit"; row lazygit glob "$h/.local/state/lazygit"
        row btop pkg btop; row btop glob "$h/.config/btop"
        row atuin glob "$h/.config/atuin"; row bat glob "$h/.cache/bat"
    } > "$TS_LEDGER"
    ledger_upgrade
    [ "$(cat "$TS_LEDGER")" = "$(
        echo "# terminal-setup ledger v1"
        row lazygit dir "$h/.config/lazygit"; row lazygit userdata "$h/.config/lazygit/config.yml"
        row lazygit glob "$h/.local/state/lazygit"; row btop pkg btop
        row btop dir "$h/.config/btop"; row btop glob "$h/.config/btop/btop.log"
        row btop userdata "$h/.config/btop/btop.conf"
        row atuin dir "$h/.config/atuin"; row atuin userdata "$h/.config/atuin/config.toml"
        row bat glob "$h/.cache/bat")" ]
    # İkinci kez çalışınca dosyaya dokunulmaz
    touch -d '2020-01-01' "$TS_LEDGER"
    ledger_upgrade
    [ "$(stat -c %Y "$TS_LEDGER")" = "$(date -d '2020-01-01' +%s)" ]
}

@test "provada defter çevrilmez" {
    mkdir -p "$TS_STATE_DIR"
    { echo "# terminal-setup ledger v1"; row lazygit glob "$HOME/.config/lazygit"; } > "$TS_LEDGER"
    cp "$TS_LEDGER" "$BATS_TEST_TMPDIR/before"
    TS_DRY_RUN=1 ledger_upgrade
    cmp "$TS_LEDGER" "$BATS_TEST_TMPDIR/before"
}
