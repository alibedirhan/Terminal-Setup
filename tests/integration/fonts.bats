#!/usr/bin/env bats
# Yazı tipi seçimi: JetBrains Mono ve Fira Code Nerd Font bileşenleri

load '../helpers/common'

setup() {
    setup_fakesys
    P="/org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/"
}

@test "JetBrains Mono kurulur, seçilir ve terminale uygulanır" {
    run ts install --components font-jetbrains
    [ "$status" -eq 0 ]
    local dir="$HOME/.local/share/fonts/terminal-setup-JetBrainsMono"
    [ -f "$dir/JetBrainsMonoNerdFont-Regular.ttf" ]
    [ ! -e "$dir/JetBrainsMonoNLNerdFont-Regular.ttf" ]
    [ "$(dconf read "${P}font")" = "'JetBrainsMono Nerd Font 11'" ]
    run ts font list
    [[ "$output" == *"* jetbrains"* ]]
}

@test "kurulu olmayan yazı tipi seçilemez" {
    run ts font set firacode
    [ "$status" -ne 0 ]
    [[ "$output" == *"kurulu değil"* ]]
    run ts font set olmayan
    [ "$status" -eq 2 ]
}

@test "yazı tipleri arasında geçilir; seçili olan kaldırılınca MesloLGS NF'ye dönülür" {
    ts install --components fonts,font-firacode
    [ "$(dconf read "${P}font")" = "'FiraCode Nerd Font 11'" ]
    ts font set meslo
    [ "$(dconf read "${P}font")" = "'MesloLGS NF 11'" ]
    ts font set firacode
    ts remove font-firacode
    [ "$(dconf read "${P}font")" = "'MesloLGS NF 11'" ]
    [ ! -e "$HOME/.local/share/fonts/terminal-setup-FiraCode" ]
    run ts uninstall
    [[ "$output" == *"Sonuç: kalıntı yok."* ]]
    [ -z "$(ls "$FAKE_ROOT/dconf")" ]
}

@test "prova modunda yazı tipi kurulmaz" {
    run ts --dry-run install --components font-jetbrains
    [ "$status" -eq 0 ]
    [ ! -e "$HOME/.local/share/fonts" ]
}

@test "doctor, uzun yazı tipi listesinde MesloLGS NF'yi bulur (pipefail + SIGPIPE)" {
    mkdir -p "$FAKE_ROOT/manyfonts"
    # Gerçek sistemlerdeki gibi yüzlerce yazı tipi: grep -q erken çıkınca
    # fc-list SIGPIPE alır ve pipefail hattı başarısız sayardı.
    cat > "$FAKE_ROOT/manyfonts/fc-list" <<'EOF'
#!/bin/sh
echo "/f/MesloLGS NF Regular.ttf: MesloLGS NF:style=Regular"
awk 'BEGIN { for (i = 0; i < 200000; i++) print "/usr/share/fonts/f" i ".ttf: F" i }'
EOF
    chmod +x "$FAKE_ROOT/manyfonts/fc-list"
    PATH="$FAKE_ROOT/manyfonts:$PATH" run ts doctor < /dev/null
    [[ "$output" == *"MesloLGS NF kurulu"* ]]
}
