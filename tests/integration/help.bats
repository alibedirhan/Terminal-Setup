#!/usr/bin/env bats
# Alt+H yardımı tldr bileşeniyle gelir

load '../helpers/common'

setup() {
    setup_fakesys
    D="$HOME/.config/terminal-setup/zsh.d"
}

@test "tldr bileşeni Alt+H parçasını sistem dilinde yazar; kaldırılınca gider" {
    run ts install --components zsh,tldr
    [ "$status" -eq 0 ]
    grep -q "^    none '%s için yardım sayfası yok.'$" "$D/61-tldr-help.zsh"
    grep -q "^    lang tr$" "$D/61-tldr-help.zsh"
    grep -q "bindkey -M emacs '^\[h' _ts_help" "$D/61-tldr-help.zsh"
    ts remove tldr
    [ ! -e "$D/61-tldr-help.zsh" ]
}

@test "İngilizce kurulumda ileti ve sayfa dili İngilizce" {
    TS_LANG=en ts install --components zsh,tldr
    grep -q "^    none 'No help page for %s.'$" "$D/61-tldr-help.zsh"
    grep -q "^    lang en$" "$D/61-tldr-help.zsh"
}
