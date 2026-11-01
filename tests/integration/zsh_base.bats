#!/usr/bin/env bats
# Oh My Zsh'siz zsh temeli: geçmiş, tamamlama, tuşlar, başlık, OSC 7; eklentiler doğrudan

load '../helpers/common'

setup() {
    setup_fakesys
    D="$HOME/.config/terminal-setup/zsh.d"
    PLUG="$HOME/.local/share/terminal-setup/plugins"
}

real_zsh() { PATH=/usr/bin:/bin command -v zsh; }

@test "profiller Oh My Zsh kurmaz; eklentiler veri klasöründen doğrudan yüklenir" {
    local p
    for p in minimal developer full; do ! grep -qx ohmyzsh "$REPO_ROOT/profiles/$p.profile"; done
    run ts install --profile developer
    [ "$status" -eq 0 ]
    [ ! -e "$HOME/.oh-my-zsh" ]
    [ -d "$PLUG/zsh-autosuggestions" ] && [ -d "$PLUG/zsh-syntax-highlighting" ] && [ -d "$PLUG/fzf-tab" ]
    [ -f "$D/10-base.zsh" ]
    grep -q "source \"$PLUG/zsh-autosuggestions/zsh-autosuggestions.zsh\"" "$D/20-zsh-plugins.zsh"
    grep -q "source \"$PLUG/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\"" "$D/98-zsh-highlight.zsh"
    grep -q "source \"$PLUG/fzf-tab/fzf-tab.plugin.zsh\"" "$D/18-fzf-tab.zsh"
    ! grep -q 'plugins+=' "$D"/*.zsh || false
    local zsh f
    zsh=$(real_zsh) || skip "gerçek zsh yok"
    for f in "$D"/*.zsh "$HOME/.config/terminal-setup/init.zsh"; do "$zsh" -n "$f" || { echo "$f"; false; }; done
}

@test "Oh My Zsh'i script kurduysa eklentiler onun listesine eklenir" {
    ts install --components ohmyzsh
    ts install --components zsh-plugins,fzf-tab
    [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]
    [ -d "$HOME/.oh-my-zsh/custom/plugins/fzf-tab" ]
    grep -q 'plugins+=(zsh-autosuggestions zsh-syntax-highlighting)' "$D/20-zsh-plugins.zsh"
    grep -q 'plugins+=(fzf-tab)' "$D/18-fzf-tab.zsh"
    [ ! -e "$D/98-zsh-highlight.zsh" ]
    [ ! -e "$PLUG" ]
}

@test "kullanıcının kendi Oh My Zsh'i varsa eklentiler onun klasörüne gider" {
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
    echo '# kullanıcının' > "$HOME/.oh-my-zsh/oh-my-zsh.sh"
    printf 'export ZSH="$HOME/.oh-my-zsh"\nsource $ZSH/oh-my-zsh.sh\n' > "$HOME/.zshrc"
    ts install --components zsh,zsh-plugins
    [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]
    grep -q 'plugins+=' "$D/20-zsh-plugins.zsh"
}

@test "kaldırınca eklenti, veri ve önbellek klasörleri kalmaz" {
    ts install --profile minimal
    mkdir -p "$HOME/.cache/terminal-setup" && echo x > "$HOME/.cache/terminal-setup/zcompdump-5.9"
    run ts uninstall
    [[ "$output" == *"Sonuç: kalıntı yok."* ]]
    [ ! -e "$HOME/.local/share/terminal-setup" ]
    [ ! -e "$HOME/.cache/terminal-setup" ]
}

@test "temel: OSC 7 Türkçe karakterli yolu kodlar; tamamlama önbelleği yazılır; hata yok" {
    local zsh
    zsh=$(real_zsh) || skip "gerçek zsh yok"
    mkdir -p "$HOME/GIT PROJELERİM"
    run env TERM=xterm-256color HOST=pc XDG_CACHE_HOME="$HOME/.cache" "$zsh" -f -i -c \
        "source '$REPO_ROOT/zsh/base.zsh'; cd \"\$HOME/GIT PROJELERİM\"" < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" == *$'\e]7;file://pc'*'/GIT%20PROJELER%C4%B0M'$'\a'* ]]
    [[ "$output" != *"command not found"* && "$output" != *"no such"* ]]
    [ -f "$HOME/.cache/terminal-setup/zcompdump-$("$zsh" -c 'print $ZSH_VERSION')" ]
}
