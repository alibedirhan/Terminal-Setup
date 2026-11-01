#!/usr/bin/env bats
# İngilizce arayüz: tüm akış İngilizce çalışır, Türkçe metin sızmaz,
# çevirisi eksik metin kalmaz.

load '../helpers/common'

setup() {
    setup_fakesys
    export TS_LANG=en TS_I18N_MISSING="$BATS_TEST_TMPDIR/missing"
    OUT="$BATS_TEST_TMPDIR/out"
}

# Katalogdaki Türkçe metinlerin parçaları (%s'ler arası, en az 8 karakter ve
# bir boşluk; çevirisinde de geçenler hariç) -> grep -F desen dosyası
turkish_fragments() {
    bash -c '
        for f in "$1"/locale/en*.sh; do source "$f"; done
        for k in "${!I18N_EN[@]}"; do
            v="${I18N_EN[$k]}"
            while IFS= read -r f; do
                ((${#f} >= 8)) && [[ "$f" == *" "* && "$v" != *"$f"* ]] && printf "%s\n" "$f"
            done <<< "${k//%s/$'"'"'\n'"'"'}"
        done' _ "$REPO_ROOT" | sort -u
}

# Çıktıda Türkçe metin var mı: Türkçeye özgü harf ya da katalogdaki bir cümle
# (yol adları ASCII'dir)
assert_no_turkish() {
    if grep -nE '[çğıöşüÇĞİÖŞÜ]' "$OUT"; then
        echo "Türkçe metin sızdı"
        return 1
    fi
    turkish_fragments > "$BATS_TEST_TMPDIR/fragments"
    [ -s "$BATS_TEST_TMPDIR/fragments" ]
    if grep -nFf "$BATS_TEST_TMPDIR/fragments" "$OUT"; then
        echo "Türkçe metin sızdı"
        return 1
    fi
}

assert_nothing_missing() {
    if [[ -s "$TS_I18N_MISSING" ]]; then
        echo "Çevirisi eksik metinler:"
        sort -u "$TS_I18N_MISSING"
        return 1
    fi
}

@test "kur, durum, teşhis, güncelle, kaldır: hepsi İngilizce" {
    {
        ts --help
        ts list
        ts list profiles
        ts theme list
        ts --dry-run install --profile full --theme nord
        ts install --profile full --theme nord
        ts status
        ts doctor
        ts update
        ts --dry-run update
        ts remove delta
        ts theme reset
        ts --dry-run uninstall
        ts uninstall
        ts update olmayan
        ts bilinmeyen
    } > "$OUT" 2>&1 || true
    grep -q "Installing Zsh" "$OUT"
    grep -q "Nord theme applied" "$OUT"
    grep -q "Result: no leftovers." "$OUT"
    assert_no_turkish
    assert_nothing_missing
}

# Ev dizininde Türkçe harf içeren dosya var mı? Dışarıda kalanlar: durum
# dizini (defter ve log), sahte sistemin indirdiği yazı tipleri, ikililer ve
# klonlanan depolar (bizim yazdığımız dosyalar değil). İkili dosyalar (-I)
# taranmaz: git nesnelerinin sıkıştırılmış baytları rastlantıyla bir Türkçe
# harfin baytlarını içerebilir.
assert_files_english() {
    if (cd "$HOME" && grep -rnIE '[çğıöşüÇĞİÖŞÜ]' . --exclude-dir={.terminal-setup,fonts,bin,.oh-my-zsh,.git}); then
        echo "Üretilen dosyada Türkçe metin kaldı"
        return 1
    fi
}

@test "kurulumun ürettiği dosyalar ve arşiv klasörü de İngilizce" {
    local t
    # Diğer terminaller de kuruluymuş gibi: renk ve ayar dosyaları yazılsın
    for t in kitty wezterm alacritty ghostty; do
        printf '#!/bin/sh\nexit 0\n' > "$FAKE_ROOT/pkgbin/$t" && chmod +x "$FAKE_ROOT/pkgbin/$t"
    done
    {
        ts install --profile full --theme nord
        ts style set retro
        ts install --components tmux,btop,lazygit
    } > "$OUT" 2>&1
    assert_files_english
    # Powerlevel10k Starship'le birlikte kurulamaz
    { ts remove starship; ts install --components p10k; } >> "$OUT" 2>&1
    assert_files_english
    assert_nothing_missing
    ts uninstall >> "$OUT" 2>&1
    [ -f "$HOME"/terminal-setup-removed-*/removal-report.txt ]
    [ -z "$(cd "$HOME" && find . -mindepth 1 ! -path './terminal-setup-removed-*')" ]
}

@test "--lang ortam değişkeninden önce gelir" {
    TS_LANG=tr run ts --lang en --help
    [[ "$output" == *"Usage: terminal-setup.sh"* ]]
    run ts --lang tr --help
    [[ "$output" == *"Kullanım: terminal-setup.sh"* ]]
}

@test "dil ayarı kalıcıdır" {
    mkdir -p "$HOME/.terminal-setup"
    echo "language=en" > "$HOME/.terminal-setup/settings"
    unset TS_LANG
    LANG=tr_TR.UTF-8 run ts --help
    [[ "$output" == *"Usage:"* ]]
}
