#!/usr/bin/env bats
# Uçtan uca: kur -> kullan -> kaldır -> başlangıç fotoğrafıyla aynı mı?

load '../helpers/common'

setup() {
    setup_fakesys
}

home_listing() {
    (cd "$HOME" && find . -mindepth 1 | grep -v '^./terminal-setup-kaldirilan-' | sort)
}

@test "tam kurulum + tema, kaldırınca kalıntı bırakmaz" {
    cp "$FAKE_ROOT/dpkg.txt" "$BATS_TEST_TMPDIR/pkgs-before"
    run ts install --profile full --theme nord
    [ "$status" -eq 0 ]
    [ "$(login_shell)" = "$FAKE_ROOT/pkgbin/zsh" ]
    [ -n "$(ls "$FAKE_ROOT/dconf")" ]

    run ts uninstall
    [ "$status" -eq 0 ]
    [[ "$output" == *"Sonuç: kalıntı yok."* ]]
    [ -z "$(home_listing)" ]
    cmp "$FAKE_ROOT/dpkg.txt" "$BATS_TEST_TMPDIR/pkgs-before"
    [ "$(login_shell)" = "/bin/bash" ]
    [ -z "$(ls "$FAKE_ROOT/dconf")" ]
    [ -f "$HOME"/terminal-setup-kaldirilan-*/kaldirma-raporu.txt ]
}

@test "kullanıcının önceden var olan dosyaları ve ayarları aynen korunur" {
    printf 'export EDITOR=vim\nalias ll="ls -l"\n' > "$HOME/.zshrc"
    git config --global user.name "Ali"
    cp "$HOME/.zshrc" "$BATS_TEST_TMPDIR/zshrc"
    cp "$HOME/.gitconfig" "$BATS_TEST_TMPDIR/gitconfig"
    ts install --profile developer
    grep -q "export EDITOR=vim" "$HOME/.zshrc"
    ts uninstall
    cmp "$HOME/.zshrc" "$BATS_TEST_TMPDIR/zshrc"
    cmp "$HOME/.gitconfig" "$BATS_TEST_TMPDIR/gitconfig"
}

@test "kurulumdan sonra oluşan geçmiş ve elle yapılan değişiklikler arşivlenir" {
    ts install --components zsh,p10k
    echo "ls -la" > "$HOME/.zsh_history"
    echo "# p10k ayarı" > "$HOME/.p10k.zsh"
    echo 'alias benim="echo kendi"' >> "$HOME/.zshrc"
    run ts uninstall
    [ "$status" -eq 0 ]
    local arc
    arc=$(echo "$HOME"/terminal-setup-kaldirilan-*)
    [ "$(cat "$arc/.zsh_history")" = "ls -la" ]
    [ -f "$arc/.p10k.zsh" ]
    grep -q 'alias benim' "$arc/.zshrc"
    [ ! -e "$HOME/.zshrc" ]
}

@test "önceden kurulu paket kaldırmada silinmez" {
    echo tmux >> "$FAKE_ROOT/dpkg.txt"
    echo libevent >> "$FAKE_ROOT/dpkg.txt"
    printf '#!/bin/sh\n' > "$FAKE_ROOT/pkgbin/tmux"; chmod +x "$FAKE_ROOT/pkgbin/tmux"
    ts install --components tmux
    ts uninstall
    pkg_is_installed tmux
    pkg_is_installed libevent
}

@test "prova modunda kurulum hiçbir şey değiştirmez" {
    run "$REPO_ROOT/terminal-setup.sh" --dry-run --yes install --profile full --theme dracula
    [ "$status" -eq 0 ]
    [[ "$output" == *"[plan]"* ]]
    [ -z "$(home_listing)" ]
    [ ! -f "$FAKE_ROOT/apt.log" ]
}

@test "prova modunda kaldırma plan gösterir, hiçbir şey değiştirmez" {
    ts install --components bat,delta
    local before
    before=$(home_listing; cat "$FAKE_ROOT/dpkg.txt")
    run "$REPO_ROOT/terminal-setup.sh" --dry-run uninstall
    [ "$status" -eq 0 ]
    [[ "$output" == *"apt-get purge"* ]]
    [[ "$output" == *"git config geri al: core.pager"* ]]
    [ "$(home_listing; cat "$FAKE_ROOT/dpkg.txt")" = "$before" ]
}

@test "görünümü sıfırlamak temayı geri alır, araçlara dokunmaz" {
    ts install --components zsh,bat --theme gruvbox
    run ts theme reset
    [ "$status" -eq 0 ]
    [ -z "$(ls "$FAKE_ROOT/dconf")" ]
    pkg_is_installed bat
    [ -z "$("$REPO_ROOT/terminal-setup.sh" theme list | grep '^\*')" ]
}

@test "tek bileşen kaldırılır, diğerleri kalır" {
    ts install --components bat,ripgrep
    run ts remove bat
    [ "$status" -eq 0 ]
    ! pkg_is_installed bat
    pkg_is_installed ripgrep
    [ -f "$HOME/.config/terminal-setup/zsh.d/60-ripgrep.zsh" ]
}

@test "tek bileşen kaldırıldıktan sonra tam kaldırma ortak dizinleri de siler" {
    ts install --components lazygit,atuin
    # ~/.local/bin'i lazygit oluşturdu; atuin hâlâ kullandığı için core'a devredilir
    ts remove lazygit
    [ -d "$HOME/.local/bin" ]
    run ts uninstall
    [ "$status" -eq 0 ]
    [ -z "$(home_listing)" ]
    [ ! -e "$HOME/.terminal-setup" ]
}

@test "kurulmamış bileşeni kaldırma isteği zararsızdır" {
    run ts remove btop
    [[ "$output" == *"kurulmamış"* ]]
}

@test "başarısız bileşen hata kodu verir ve iz bırakmaz" {
    ts install --components zsh
    touch "$FAKE_ROOT/apt-fail"
    run ts install --components tmux
    [ "$status" -ne 0 ]
    [ ! -e "$HOME/.tmux.conf" ]
    rm "$FAKE_ROOT/apt-fail"
    run ts uninstall
    [[ "$output" == *"Sonuç: kalıntı yok."* ]]
}

@test "status, list ve doctor hiçbir dosya oluşturmaz" {
    run "$REPO_ROOT/terminal-setup.sh" status
    [ "$status" -eq 0 ]
    run "$REPO_ROOT/terminal-setup.sh" list profiles
    run "$REPO_ROOT/terminal-setup.sh" doctor < /dev/null
    [ -z "$(home_listing)" ]
}

@test "verify kurulumdan sonra farkları gösterir" {
    ts install --components bat
    run "$REPO_ROOT/terminal-setup.sh" verify
    [[ "$output" == *"Defterde"* ]]
    [ "$status" -ne 0 ]
}

@test "komut satırı: yardım, sürüm, bilinmeyen komut" {
    run "$REPO_ROOT/terminal-setup.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Kullanım"* ]]
    run "$REPO_ROOT/terminal-setup.sh" --version
    [ "$output" = "Terminal Setup $(cat "$REPO_ROOT/VERSION")" ]
    run "$REPO_ROOT/terminal-setup.sh" uçuş
    [ "$status" -eq 2 ]
    run "$REPO_ROOT/terminal-setup.sh" install --theme olmayan
    [ "$status" -eq 2 ]
}

@test "kaldırılacak bir şey yoksa zararsız mesaj verir" {
    run ts uninstall
    [ "$status" -eq 0 ]
    [[ "$output" == *"Kaldırılacak bir şey yok"* ]]
}

@test "v5 kurulumu algılanır ve prova modunda listelenir" {
    mkdir -p "$HOME/.terminal-setup/backups" "$HOME/.oh-my-zsh"
    run "$REPO_ROOT/terminal-setup.sh" --dry-run uninstall
    [ "$status" -eq 0 ]
    [[ "$output" == *"v5 kurulumu temizliği"* ]]
    [ -d "$HOME/.oh-my-zsh" ]
}

@test "root olarak çalıştırma reddedilir" {
    run bash -c "EUID=0; source '$REPO_ROOT/lib/core.sh'; ts_load; runner_prepare" 2>&1
    [ "$status" -ne 0 ] || [[ "$output" == *root* ]]
}

@test "tldr paketi Ubuntu sürümüne göre seçilir" {
    run ts --dry-run install --components tldr
    [[ "$output" == *"apt-get install tealdeer"* ]]
    printf 'ID=ubuntu\nVERSION_ID="26.04"\n' > "$TS_OS_RELEASE"
    run ts --dry-run install --components tldr
    [[ "$output" == *"apt-get install tealdeer"* ]]
    printf 'ID=ubuntu\nVERSION_ID="22.04"\n' > "$TS_OS_RELEASE"
    run ts --dry-run install --components tldr
    [[ "$output" == *"apt-get install tldr"* ]]
}

@test "paket kurmayan kurulum sudo istemeden kaldırılır" {
    # Gereken paketler zaten kurulu: kurulum yalnızca kullanıcı dosyalarına dokunur
    printf 'git\ncurl\nca-certificates\ngit-man\n' >> "$FAKE_ROOT/dpkg.txt"
    run ts install --components fzf
    [ "$status" -eq 0 ]
    run grep -P '\t(pkg|shell)\t' "$HOME/.terminal-setup/ledger"
    [ "$status" -ne 0 ]
    mkdir -p "$FAKE_ROOT/nosudo"
    printf '#!/bin/sh\necho "sudo $*" >> "%s"\nexit 1\n' "$FAKE_ROOT/sudo.log" > "$FAKE_ROOT/nosudo/sudo"
    chmod +x "$FAKE_ROOT/nosudo/sudo"
    PATH="$FAKE_ROOT/nosudo:$PATH" run ts uninstall
    [ "$status" -eq 0 ]
    [[ "$output" == *"Sonuç: kalıntı yok."* ]]
    [ ! -e "$FAKE_ROOT/sudo.log" ]
}
