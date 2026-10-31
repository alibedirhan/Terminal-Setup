#!/usr/bin/env bats
# Starship: varsayılan prompt; ayar dosyası tema ve kişilikle güncellenir

load '../helpers/common'

setup() {
    setup_fakesys
    CFG="$HOME/.config/terminal-setup/starship.toml"
    SNIP="$HOME/.config/terminal-setup/zsh.d/90-starship.zsh"
}

@test "profillerin hepsinde prompt Starship; Powerlevel10k isteğe bağlı" {
    local p
    for p in minimal developer full; do
        grep -qx starship "$REPO_ROOT/profiles/$p.profile"
        ! grep -qx p10k "$REPO_ROOT/profiles/$p.profile"
    done
}

@test "kurulumda ayar yazılır; tema ve kişilik değişince güncellenir; kaldırınca silinir" {
    run ts install --components starship
    [ "$status" -eq 0 ]
    [ -f "$CFG" ]
    grep -q "export STARSHIP_CONFIG=\"$CFG\"" "$SNIP"
    ! grep -q 'palette =' "$CFG"                       # tema yok: terminalin renkleri
    run ts theme apply nord
    [ "$status" -eq 0 ]
    grep -q 'palette = "terminal_setup"' "$CFG"
    grep -q '# Kişilik: arctic  Tema: Nord' "$CFG"
    ts style set neon
    grep -q '# Kişilik: neon' "$CFG"
    run ts uninstall
    [ "$status" -eq 0 ]
    [ ! -e "$CFG" ]
    [[ "$output" == *"Sonuç: kalıntı yok."* ]]
}

@test "önce tema, sonra Starship: ayar baştan temaya uygun yazılır" {
    ts install --components zsh --theme dracula
    ts install --components starship
    grep -q '# Kişilik: vivid  Tema: Dracula' "$CFG"
}

@test "kullanıcının kendi starship.toml dosyasına dokunulmaz" {
    mkdir -p "$HOME/.config"
    echo '# benim ayarım' > "$HOME/.config/starship.toml"
    ts install --components starship --theme nord
    [ "$(cat "$HOME/.config/starship.toml")" = "# benim ayarım" ]
    ts uninstall
    [ "$(cat "$HOME/.config/starship.toml")" = "# benim ayarım" ]
}
