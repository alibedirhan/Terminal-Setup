#!/usr/bin/env bats
# Komut paleti bileşeni: profiller, kurulum, kaldırma

load '../helpers/common'

setup() {
    setup_fakesys
    D="$HOME/.config/terminal-setup/zsh.d"
}

@test "geliştirici profili paleti kurar; kaldırılınca parçası kalmaz" {
    grep -qx palette "$REPO_ROOT/profiles/developer.profile"
    grep -qx palette "$REPO_ROOT/profiles/full.profile"
    run ts install --components zsh,fzf,palette
    [ "$status" -eq 0 ]
    grep -q "^    header 'Enter: komut satırına yaz · Esc: kapat'$" "$D/97-palette.zsh"
    grep -q "bindkey -M emacs '^@' _ts_palette" "$D/97-palette.zsh"
    ts remove palette
    [ ! -e "$D/97-palette.zsh" ]
    [ -f "$D/60-fzf.zsh" ]
}

@test "palet fzf'e bağlıdır: fzf olmadan istenirse fzf de kurulur" {
    run ts install --components zsh,palette
    [ "$status" -eq 0 ]
    [ -f "$D/60-fzf.zsh" ] && [ -f "$D/97-palette.zsh" ]
}
