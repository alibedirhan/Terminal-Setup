#!/usr/bin/env bats
# Karşılama kartı: yalnızca dikkat isteyenler, kişiliğe göre biçim, dış komutsuz çizim

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
    ZSH=$(PATH=/usr/bin:/bin command -v zsh) || skip "gerçek zsh yok"
    CACHE="$HOME/.cache/terminal-setup"
    mkdir -p "$CACHE"
    PROJ="$HOME/kod/proje"
    mkdir -p "$PROJ"
    git -C "$PROJ" init -q -b ana-dal
    # Bu makinenin gerçek durumu testi etkilemesin
    export TS_REBOOT_FILE="$BATS_TEST_TMPDIR/reboot-required"
}

# Kartın zsh dosyalarını üret: card_files [TEMA] (tema yoksa varsayılan biçim)
card_files() {
    _welcome_messages
    printf '%s\n' "$REPLY" > "$BATS_TEST_TMPDIR/msg.zsh"
    : > "$BATS_TEST_TMPDIR/card.zsh"
    if [[ -n "${1:-}" ]]; then
        theme_load "$1"
        welcome_theme_zsh
        printf '%s\n' "$REPLY" > "$BATS_TEST_TMPDIR/card.zsh"
    fi
}

# Kartı gerçek zsh'te çiz (ev dizininden): card [KOMUTLAR] -> output (renk kodsuz)
card() {
    run env -u TMUX COLUMNS="${COLS:-80}" HOME="$HOME" XDG_CACHE_HOME="$HOME/.cache" "$ZSH" -f -c "
        source '$BATS_TEST_TMPDIR/msg.zsh'; source '$BATS_TEST_TMPDIR/card.zsh'
        cd ~; source '$REPO_ROOT/zsh/welcome.zsh'; ${1:-} _ts_welcome"
    output=$(sed 's/\x1b\[[0-9;]*m//g' <<< "$output")
    mapfile -t lines <<< "$output"
}

full_cache() {
    printf '%s\n' "$PROJ" > "$CACHE/projects"
    printf 'updates=12\ndisk=93\ndirty=proje/notlar/web\n' > "$CACHE/welcome"
}

# Her satırın ekrandaki genişliği -> satır başına bir sayı
widths() { LC_ALL=C.UTF-8 awk '{ print length($0) }' <<< "$output" | sort -u; }

@test "söylenecek bir şey yoksa kart çıkmaz; tmux içinde ve TS_WELCOME=off iken de" {
    card_files
    card
    [ -z "$output" ]
    full_cache
    card
    [ -n "$output" ]
    card "TS_WELCOME=off;"
    [ -z "$output" ]
    card "TMUX=/tmp/x;"
    [ -z "$output" ]
}

@test "kart dikkat isteyenleri ve kaldığınız projeyi gösterir" {
    card_files
    full_cache
    touch "$TS_REBOOT_FILE"
    card
    [[ "$output" == *"12 güncelleme bekliyor"* ]]
    [[ "$output" == *"Yeniden başlatma gerekli"* ]]
    [[ "$output" == *"Disk %93 dolu"* ]]
    [[ "$output" == *"Kaydedilmemiş iş: proje, notlar +1"* ]]
    [[ "$output" == *"Kaldığınız yer: proje (ana-dal) — resume"* ]]
    # Eşik altındaki disk ve sıfır güncelleme gösterilmez
    printf 'updates=0\ndisk=40\ndirty=\n' > "$CACHE/welcome"
    card
    [[ "$output" != *"güncelleme"* && "$output" != *"Disk"* && "$output" != *"Kaydedilmemiş"* ]]
    [[ "$output" == *"Kaldığınız yer"* ]]
}

@test "her kişilikte kart aynı genişlikte, kendi kenarı ve başlık biçimiyle çizilir" {
    full_cache
    local t
    for t in one-dark dracula gruvbox catppuccin tokyo-night; do
        card_files "$t"
        card
        [ "$status" -eq 0 ]
        [ "$(widths)" = 72 ] || { echo "$t:"; echo "$output"; false; }
    done
    card_files one-dark; card
    [[ "${lines[0]}" == "╭─ "* && "${lines[-1]}" == "╰"*"╯" ]]
    card_files gruvbox; card
    [[ "${lines[0]}" == "┌─ [ "* && "$output" == *"[!] 12 GÜNCELLEME BEKLİYOR"* && "$output" == *"— resume"* ]]
    card_files dracula; card
    [[ "${lines[0]}" == "┏━ "* && "$output" == *"➜ Kaldığınız yer"* ]]
    card_files tokyo-night; card
    [[ "${lines[0]}" == "╔═ ▸ "* ]]
    # Kenarsız kişilik: kutu yok, sol çizgi, küçük harf
    card_files nord; card
    [[ "${lines[0]}" == "▏ "* && "$output" == *"▏ · 12 güncelleme bekliyor"* && "$output" != *"╭"* ]]
    full_cache; printf 'dirty=Proje-A\n' > "$CACHE/welcome"; card
    [[ "$output" == *"kaydedilmemiş iş: Proje-A"* ]]
}

@test "dar terminalde satırlar kısaltılır, kart taşmaz; çok darsa çizilmez" {
    full_cache
    local proj="$HOME/kod/cok-uzun-bir-proje-adi-ki-karti-tasirabilir"
    mkdir -p "$proj"
    git -C "$proj" init -q -b ozellik/cok-uzun-bir-dal-adi-ile-gelen-is
    printf '%s\n' "$proj" > "$CACHE/projects"
    card_files catppuccin
    COLS=40 card
    [ "$(widths)" = 38 ]
    [[ "$output" == *"…"* && "$output" == *"— resume"* ]]
    COLS=20 card
    [ -z "$output" ]
}

@test "kart çizilirken dış komut çalışmaz" {
    full_cache
    card_files dracula
    # PATH boşken de çizilir ve hata yazmaz
    run env -u TMUX COLUMNS=80 HOME="$HOME" XDG_CACHE_HOME="$HOME/.cache" "$ZSH" -f -c "
        source '$BATS_TEST_TMPDIR/msg.zsh'; source '$BATS_TEST_TMPDIR/card.zsh'
        cd ~; source '$REPO_ROOT/zsh/welcome.zsh'; path=(); _ts_welcome 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Kaldığınız yer"* ]]
    [[ "$output" != *"not found"* && "$output" != *"bulunamadı"* ]]
}

@test "önbellekteki sayı olmayan değer aritmetiğe girmez" {
    card_files
    printf 'updates=a[$(touch %s/izinsiz)]\ndisk=1+99\n' "$HOME" > "$CACHE/welcome"
    card
    [ ! -e "$HOME/izinsiz" ]
    [[ "$output" != *"güncelleme"* && "$output" != *"Disk"* ]]
}

@test "proje kaydı: en yenisi başta, tekrarsız, en çok 10; resume oraya götürür" {
    local i
    for i in 1 2 3 4 5 6 7 8 9 10 11; do mkdir -p "$HOME/p$i" && git -C "$HOME/p$i" init -q; done
    run "$ZSH" -f -c "HOME='$HOME' XDG_CACHE_HOME='$HOME/.cache'; cd ~; source '$REPO_ROOT/zsh/welcome.zsh'
        for i in {1..11}; do cd ~/p\$i; done; cd ~/p3/; mkdir -p alt; cd alt; cd ~
        print -rl -- \"\${(@f)\$(<$CACHE/projects)}\"; resume; print -r -- \"cwd=\$PWD\""
    [ "${lines[0]}" = "$HOME/p3" ]
    [ "${lines[1]}" = "$HOME/p11" ]
    [ "${#lines[@]}" -eq 11 ]
    [ "${lines[10]}" = "cwd=$HOME/p3" ]
}

@test "kullanıcının kendi resume komutu varsa kart ts-resume önerir" {
    card_files
    full_cache
    card "resume() { :; };"
    [[ "$output" == *"Kaldığınız yer: proje (ana-dal) — resume"* ]]
    # resume tanımı welcome.zsh'ten önce gelirse ona dokunulmaz
    run env -u TMUX COLUMNS=80 HOME="$HOME" XDG_CACHE_HOME="$HOME/.cache" "$ZSH" -f -c "
        resume() { print kendi; }; source '$BATS_TEST_TMPDIR/msg.zsh'
        cd ~; source '$REPO_ROOT/zsh/welcome.zsh'; _ts_welcome; resume"
    output=$(sed 's/\x1b\[[0-9;]*m//g' <<< "$output")
    [[ "$output" == *"— ts-resume"* ]]
    [ "${lines[-1]}" = kendi ]
}

@test "arka plan yenilemesi güncelleme, disk ve kaydedilmemiş işi önbelleğe yazar" {
    printf '#!/bin/sh\necho "7;2" >&2\n' > "$BATS_TEST_TMPDIR/apt-check" && chmod +x "$BATS_TEST_TMPDIR/apt-check"
    # Sahte sistemin git'i commit yapmaz; depolar gerçek git ile hazırlanır
    local temiz="$HOME/kod/temiz" git
    git=$(PATH=/usr/bin:/bin command -v git) || skip "gerçek git yok"
    mkdir -p "$temiz" && "$git" -C "$temiz" init -q
    echo a > "$PROJ/dosya" && "$git" -C "$PROJ" add dosya
    "$git" -C "$PROJ" -c user.name=t -c user.email=t@t commit -qm ilk
    echo b > "$PROJ/dosya"
    printf '%s\n' "$PROJ" "$temiz" > "$CACHE/projects"
    # Gerçek df ve git
    run env PATH=/usr/bin:/bin "$ZSH" -f -c "HOME='$HOME' XDG_CACHE_HOME='$HOME/.cache' TS_APT_CHECK='$BATS_TEST_TMPDIR/apt-check'
        cd ~; source '$REPO_ROOT/zsh/welcome.zsh'; _ts_welcome_refresh"
    [ "$status" -eq 0 ]
    grep -qx "updates=7" "$CACHE/welcome"
    grep -qx "disk=[0-9]*" "$CACHE/welcome"
    grep -qx "dirty=proje" "$CACHE/welcome"
}

@test "iletiler kurulumun dilinde; İngilizcede büyük harf i'yi İ yapmaz" {
    i18n_init en
    full_cache
    card_files gruvbox
    card
    [[ "$output" == *"[!] 12 UPDATES WAITING"* && "$output" == *"DISK 93% FULL"* ]]
    # Proje ve dal adları büyütülmez
    [[ "$output" == *"LAST PROJECT: proje (ana-dal) — resume"* ]]
    [[ "$output" != *"İ"* ]]
}

@test "tema dosyası kişiliği ve rolleri taşır; ham Nerd Font karakteri yok" {
    theme_load dracula
    welcome_theme_zsh
    [[ "$REPLY" == *"border heavy seg powerline"* && "$REPLY" == *"marks '● ● ➜'"* ]]
    [[ "$REPLY" == *"38;2;$(theme_rgb "${ROLE[accent]}")m"* ]]
    ! LC_ALL=C grep -q $'[\xee\xef]' <<< "$REPLY"
    ! LC_ALL=C grep -q $'[\xee\xef]' "$REPO_ROOT/zsh/welcome.zsh"
    "$ZSH" -n <<< "$REPLY"
}
