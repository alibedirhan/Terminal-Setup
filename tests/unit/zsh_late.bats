#!/usr/bin/env bats
# Oh My Zsh'i ~/.zshrc kendisi yüklediğinde (yönetilen bloktan sonra) eksik
# kalan eklentiler ve ezilen Ctrl+R ilk istemde tamamlanır.

load '../helpers/common'

setup() {
    ZSH_BIN=$(PATH=/usr/bin:/bin command -v zsh) || skip "gerçek zsh yok"
    setup_fakesys
    load_lib
    PLUGIN="$HOME/eklenti dizini/demo.plugin.zsh"
    mkdir -p "${PLUGIN%/*}"
    printf 'echo yuklendi >> %q\ndemo_marker() { :; }\ntypeset -ga DEMO_ARR=(a b)\n' "$HOME/flag" > "$PLUGIN"
}

# Üretilen kodu yükle, sonra ilk istemdeki gibi precmd kancalarını çalıştır
run_zsh() {
    local code="$1" before="${2:-}" after="${3:-}"
    printf '%s\n' "$code" > "$HOME/late.zsh"
    run "$ZSH_BIN" -f -c "zmodload zsh/zle zsh/zleparameter
$before
source ${HOME@Q}/late.zsh
$after
for f in \$precmd_functions; do \$f; done
print -r -- \"marker=\$+functions[demo_marker] arr=\$DEMO_ARR hooks=\${#precmd_functions}\"
bindkey -M emacs '^R'"
}

@test "üretilen zsh kodu sözdizimine uygun" {
    { zsh_late_load demo '$+functions[demo_marker]' "$PLUGIN" demo_after
      zsh_late_rebind demo demo-search fzf-history-widget; } > "$HOME/late.zsh"
    "$ZSH_BIN" -n "$HOME/late.zsh"
}

@test "plugins listesinden düşen eklenti ilk istemde yüklenir; kanca kendini siler" {
    run_zsh "$(zsh_late_load demo '$+functions[demo_marker]' "$PLUGIN" 'print sonra')"
    [ "$status" -eq 0 ]
    [[ "$output" == *"sonra"* ]]
    [[ "$output" == *"marker=1 arr=a b hooks=0"* ]]
    [ "$(cat "$HOME/flag")" = "yuklendi" ]
}

@test "Oh My Zsh eklentiyi zaten yüklediyse ikinci kez yüklenmez" {
    run_zsh "$(zsh_late_load demo '$+functions[demo_marker]' "$PLUGIN")" "demo_marker() { :; }"
    [ "$status" -eq 0 ]
    [ ! -e "$HOME/flag" ]
}

@test "Oh My Zsh'in düz aramaya bağladığı Ctrl+R geri alınır, fzf'inki devralınır" {
    run_zsh "$(zsh_late_rebind atuin demo-search fzf-history-widget)" \
        "demo-search() { :; }; zle -N demo-search; fzf-history-widget() { :; }; zle -N fzf-history-widget" \
        "bindkey -M emacs '^R' history-incremental-search-backward"
    [[ "$output" == *'"^R" demo-search'* ]]

    run_zsh "$(zsh_late_rebind atuin demo-search fzf-history-widget)" \
        "demo-search() { :; }; zle -N demo-search; fzf-history-widget() { :; }; zle -N fzf-history-widget" \
        "bindkey -M emacs '^R' fzf-history-widget"
    [[ "$output" == *'"^R" demo-search'* ]]
}

@test "kullanıcının kendi Ctrl+R widget'ına dokunulmaz" {
    run_zsh "$(zsh_late_rebind fzf demo-search)" \
        "demo-search() { :; }; zle -N demo-search; benim() { :; }; zle -N benim" \
        "bindkey -M emacs '^R' benim"
    [[ "$output" == *'"^R" benim'* ]]
}

@test "widget tanımlı değilse Ctrl+R değişmez" {
    run_zsh "$(zsh_late_rebind fzf demo-search)" "" \
        "bindkey -M emacs '^R' history-incremental-search-backward"
    [[ "$output" == *'"^R" history-incremental-search-backward'* ]]
}
