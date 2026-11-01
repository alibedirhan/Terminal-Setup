#!/usr/bin/env bats
# Komut paleti (Ctrl+Space): projenin komutları tek listede, seçilen satıra yazılır

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
    ZSH=$(PATH=/usr/bin:/bin command -v zsh) || skip "gerçek zsh yok"
    _palette_messages
    printf '%s\n' "$REPLY" > "$BATS_TEST_TMPDIR/msg.zsh"
    P="$HOME/proje"
    mkdir -p "$P/alt/dizin"
    git -C "$P" init -q
}

# Paletin komut sütunu (bulunulan dizinden): items DİZİN [ÖNCE] -> output
items() {
    run "$ZSH" -f -c "source '$BATS_TEST_TMPDIR/msg.zsh'; source '$REPO_ROOT/zsh/palette.zsh'
        ${2:-} cd '$1'; _ts_palette_items; print -rl -- \"\${reply[@]#*\$'\\t'}\""
}

@test "package.json betikleri kilit dosyasına göre paket yöneticisiyle" {
    cat > "$P/package.json" <<'JSON'
{
  "name": "demo",
  "scripts": {
    "dev": "vite",
    "test": "vitest run",
    "build:prod": "vite build --mode production"
  },
  "dependencies": { "vite": "^5" }
}
JSON
    items "$P"
    [[ "$output" == *$'npm run dev\nnpm run test\nnpm run build:prod'* ]]
    [[ "$output" != *"npm run name"* && "$output" != *"npm run vite"* ]]
    touch "$P/pnpm-lock.yaml"
    items "$P/alt/dizin"
    [[ "$output" == *"pnpm run dev"* ]]
}

@test "Makefile hedefleri: değişken atamaları ve özel hedefler hariç, tekrarsız" {
    printf '%s\n' 'CC := gcc' 'X=1' '.PHONY: test build' 'build: main.o' $'\t$(CC) -o x' \
        'test:' 'build: extra' 'lint:  ' > "$P/Makefile"
    items "$P"
    [[ "$output" == *$'make build\nmake test\nmake lint'* ]]
    [[ "$output" != *"make CC"* && "$output" != *"make X"* && "$output" != *"make .PHONY"* ]]
    [ "$(grep -c '^make build$' <<< "$output")" -eq 1 ]
}

@test "justfile, Cargo, Go ve pytest" {
    printf '%s\n' 'set shell := ["bash", "-c"]' 'default:' 'serve port:' '    echo hi' > "$P/justfile"
    : > "$P/Cargo.toml"; : > "$P/go.mod"; : > "$P/pytest.ini"
    items "$P"
    [[ "$output" == *"just default"* && "$output" == *"just serve"* && "$output" != *"just set"* ]]
    [[ "$output" == *"cargo test"* && "$output" == *"cargo run"* ]]
    [[ "$output" == *"go test ./..."* && "$output" == *"python3 -m pytest"* ]]
}

@test "sanal ortam: kapalıysa açma, açıksa kapatma önerilir; git komutları depoda" {
    mkdir -p "$P/.venv/bin" && : > "$P/.venv/bin/activate"
    items "$P"
    [[ "$output" == *"source .venv/bin/activate"* && "$output" == *"git status"* ]]
    items "$P/alt" "VIRTUAL_ENV=$P/.venv;"
    [[ "$output" == *"deactivate"* && "$output" != *"source "* ]]
    items "$HOME"
    [[ "$output" != *"git status"* ]]
}

@test "son komutlar geçmişten: tekrarsız, en yenisi önce" {
    printf '%s\n' ": 1:0;ls -la" ": 2:0;make build" ": 3:0;ls -la" ": 4:0;git log" > "$HOME/.zsh_history"
    items "$HOME" "HISTFILE=$HOME/.zsh_history; setopt extended_history; fc -R;"
    [[ "$output" == *$'git log\nls -la\nmake build'* ]]
    [ "$(grep -c '^ls -la$' <<< "$output")" -eq 1 ]
}

@test "görünen satır tür ve kaynağı gösterir; komut satırına yalnızca komut yazılır" {
    printf 'test:\n' > "$P/Makefile"
    # Sahte fzf "make test" satırını seçer
    printf '#!/bin/sh\ngrep -m1 "make test"\n' > "$BATS_TEST_TMPDIR/fzf" && chmod +x "$BATS_TEST_TMPDIR/fzf"
    run "$ZSH" -f -c "source '$BATS_TEST_TMPDIR/msg.zsh'; source '$REPO_ROOT/zsh/palette.zsh'
        cd '$P'; _ts_palette_items; print -r -- \"\${reply[1]}\"
        path=('$BATS_TEST_TMPDIR' \$path); zle() { :; }; BUFFER=eski; CURSOR=0
        _ts_palette; print -r -- \"[\$BUFFER] \$CURSOR\""
    [[ "${lines[0]}" == "betik    make test  · Makefile"$'\t'"make test" ]]
    [ "${lines[1]}" = "[make test] 9" ]
}

@test "C yerel ayarında da tür sütunu hizalı" {
    printf 'test:\n' > "$P/Makefile"
    run env LC_ALL=C LANG=C "$ZSH" -f -c "source '$BATS_TEST_TMPDIR/msg.zsh'; source '$REPO_ROOT/zsh/palette.zsh'
        fc -p; print -s 'ls -la'; cd '$P'; _ts_palette_items; print -rl -- \"\${reply[@]%%\$'\\t'*}\""
    [ "$status" -eq 0 ]
    [[ "$output" == *"betik    make test"* ]]
    [[ "$output" == *"geçmiş   ls -la"* ]]
}

@test "boş dizinde ileti gösterilir, komut satırı değişmez" {
    run "$ZSH" -f -c "source '$BATS_TEST_TMPDIR/msg.zsh'; source '$REPO_ROOT/zsh/palette.zsh'
        cd '$HOME'; fc -p; zle() { print -r -- \"zle \$*\"; }; BUFFER=eski; _ts_palette; print -r -- \"[\$BUFFER]\""
    [ "${lines[0]}" = "zle -M Bu dizinde önerilecek komut yok." ]
    [ "${lines[1]}" = "[eski]" ]
}

@test "Ctrl+Space bağlanır; parça sözdizimi geçerli" {
    run "$ZSH" -f -c "source '$BATS_TEST_TMPDIR/msg.zsh'; source '$REPO_ROOT/zsh/palette.zsh'
        bindkey -M emacs '^@'; bindkey -M viins '^@'"
    [[ "${lines[0]}" == *"_ts_palette" && "${lines[1]}" == *"_ts_palette" ]]
}
