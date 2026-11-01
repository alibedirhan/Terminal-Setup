#!/usr/bin/env bats
# Araçların ayar dosyaları kullanıcınındır: kaldırmada silinmez, arşive taşınır

load '../helpers/common'

setup() {
    setup_fakesys
}

home_listing() {
    (cd "$HOME" && find . -mindepth 1 | grep -v '^./terminal-setup-kaldirilan-' | sort)
}

@test "lazygit, btop ve atuin ayarları arşive taşınır; günlük ve boş dizin kalmaz" {
    ts install --components lazygit,btop,atuin
    # Bileşenler ayar dosyasını kullanıcı verisi, dizini paylaşılan dizin olarak yazar
    local f d
    for f in lazygit/config.yml btop/btop.conf atuin/config.toml; do
        cut -f2,3 "$HOME/.terminal-setup/ledger" | grep -qx "userdata"$'\t'"$HOME/.config/$f"
    done
    for d in lazygit btop atuin; do
        ! cut -f2,3 "$HOME/.terminal-setup/ledger" | grep -qx "glob"$'\t'"$HOME/.config/$d"
    done
    # Araçların ilk çalışmada ve kullanıcının sonradan yazdıkları
    mkdir -p "$HOME/.config/lazygit" "$HOME/.config/btop" "$HOME/.config/atuin" "$HOME/.local/state/lazygit"
    echo "gui: { showIcons: true }" > "$HOME/.config/lazygit/config.yml"
    echo "update_ms = 1000" > "$HOME/.config/btop/btop.conf"
    echo "günlük" > "$HOME/.config/btop/btop.log"
    echo "style = \"compact\"" > "$HOME/.config/atuin/config.toml"
    echo "recentRepos: []" > "$HOME/.local/state/lazygit/state.yml"
    run ts uninstall
    [ "$status" -eq 0 ]
    [[ "$output" == *"Sonuç: kalıntı yok."* ]]
    [ -z "$(home_listing)" ]
    local arc
    arc=$(echo "$HOME"/terminal-setup-kaldirilan-*)
    grep -q showIcons "$arc/.config/lazygit/config.yml"
    grep -q update_ms "$arc/.config/btop/btop.conf"
    grep -q compact "$arc/.config/atuin/config.toml"
    [ ! -e "$arc/.config/btop/btop.log" ]
    [ ! -e "$arc/.local/state/lazygit" ]
}

@test "lazygit'in kendi yazdığı boş ayar dosyası arşive gitmez" {
    ts install --components lazygit
    mkdir -p "$HOME/.config/lazygit"
    : > "$HOME/.config/lazygit/config.yml"
    run ts uninstall
    [ "$status" -eq 0 ]
    [ -z "$(home_listing)" ]
    [ ! -e "$(echo "$HOME"/terminal-setup-kaldirilan-*)/.config/lazygit" ]
}

@test "kullanıcının ayar dizinine kendi koyduğu dosyalar yerinde kalır" {
    ts install --components btop
    mkdir -p "$HOME/.config/btop/themes"
    echo "theme[main_bg]=\"#000000\"" > "$HOME/.config/btop/themes/benim.theme"
    run ts uninstall
    [ "$status" -eq 0 ]
    [ -f "$HOME/.config/btop/themes/benim.theme" ]
}

# 6.x kurulumunun defteri: ayar dizini önbellek gibi (glob) kayıtlı
v6_ledger() {
    local h="$HOME" t=$'\t'
    sed -i -e "\\|${t}userdata${t}$h/.config/lazygit/config.yml\$|d" \
        -e "s|${t}dir${t}$h/.config/lazygit\$|${t}glob${t}$h/.config/lazygit|" "$HOME/.terminal-setup/ledger"
    grep -q "${t}glob${t}$h/.config/lazygit\$" "$HOME/.terminal-setup/ledger"
}

@test "6.x defteriyle kurulmuş lazygit kaldırılınca kullanıcının ayarı korunur" {
    ts install --components lazygit
    v6_ledger
    mkdir -p "$HOME/.config/lazygit"
    echo "gui: { border: single }" > "$HOME/.config/lazygit/config.yml"

    # Prova planı defteri değiştirmeden çevrilmiş kayıtları gösterir
    cp "$HOME/.terminal-setup/ledger" "$BATS_TEST_TMPDIR/ledger-v6"
    run "$REPO_ROOT/terminal-setup.sh" --dry-run uninstall
    [ "$status" -eq 0 ]
    [[ "$output" == *"arşive taşı: ~/.config/lazygit/config.yml"* ]]
    [[ "$output" != *"sil ~/.config/lazygit"$'\n'* ]]
    cmp "$HOME/.terminal-setup/ledger" "$BATS_TEST_TMPDIR/ledger-v6"

    run ts uninstall
    [ "$status" -eq 0 ]
    [[ "$output" == *"Sonuç: kalıntı yok."* ]]
    grep -q "border: single" "$(echo "$HOME"/terminal-setup-kaldirilan-*)/.config/lazygit/config.yml"
}
