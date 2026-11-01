#!/usr/bin/env bats
# Karşılama kartı bileşeni: kurulum, tema ve kişilik, sıfırlama, kaldırma

load '../helpers/common'

setup() {
    setup_fakesys
    D="$HOME/.config/terminal-setup/zsh.d"
}

home_listing() {
    (cd "$HOME" && find . -mindepth 1 | grep -v '^./terminal-setup-kaldirilan-' | sort)
}

@test "geliştirici profili kartı kurar; biçim temadan ve kişilikten gelir" {
    grep -qx welcome "$REPO_ROOT/profiles/developer.profile"
    grep -qx welcome "$REPO_ROOT/profiles/full.profile"
    ! grep -qx welcome "$REPO_ROOT/profiles/minimal.profile"
    run ts install --profile developer --theme nord
    [ "$status" -eq 0 ]
    grep -q "^    morning 'Günaydın'$" "$D/96-welcome.zsh"
    grep -q "border none seg minimal" "$D/65-theme-welcome.zsh"
    ts style set retro
    grep -q "border sharp seg brackets" "$D/65-theme-welcome.zsh"
    grep -q "marks '\[!\] \[X\] \[>\]'" "$D/65-theme-welcome.zsh"
    local zsh f
    zsh=$(PATH=/usr/bin:/bin command -v zsh) || skip "gerçek zsh yok"
    for f in "$D/96-welcome.zsh" "$D/65-theme-welcome.zsh"; do "$zsh" -n "$f"; done
}

@test "tema uygulandıktan sonra kurulan kart temayı hemen alır; sıfırlayınca varsayılana döner" {
    ts install --components zsh --theme dracula
    ts install --components welcome
    grep -q "border heavy seg powerline" "$D/65-theme-welcome.zsh"
    ts theme reset
    [ ! -e "$D/65-theme-welcome.zsh" ]
    [ -f "$D/96-welcome.zsh" ]
}

@test "kart kaldırılınca parçası ve önbelleği kalmaz" {
    ts install --components zsh,welcome --theme gruvbox
    mkdir -p "$HOME/.cache/terminal-setup"
    echo "$HOME/kod" > "$HOME/.cache/terminal-setup/projects"
    echo "updates=3" > "$HOME/.cache/terminal-setup/welcome"
    ts remove welcome
    [ ! -e "$D/96-welcome.zsh" ]
    [ ! -e "$HOME/.cache/terminal-setup/projects" ] && [ ! -e "$HOME/.cache/terminal-setup/welcome" ]
    # Kartın tema parçası temaya aittir; görünüm sıfırlanınca ya da kaldırmada gider
    run ts uninstall
    [ "$status" -eq 0 ]
    [ -z "$(home_listing)" ]
}
