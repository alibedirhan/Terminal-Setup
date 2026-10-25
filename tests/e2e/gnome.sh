#!/usr/bin/env bash
# ============================================================================
# Gerçek GNOME ayar testi (CI'da temiz bir Ubuntu konteynerinde root olarak)
# ============================================================================
#   docker run --rm -v "$PWD:/src:ro" ubuntu:24.04 bash /src/tests/e2e/gnome.sh
#
# Birim testleri sahte dconf kullanır; bu test gerçek dconf + gsettings ile
# çalışır. GNOME Terminal (ve depoda varsa Ptyxis) kurulur, kullanıcının
# önceden kendi yaptığı bir ayar yazılır, sonra:
#   tema uygula -> başka tema uygula -> yazılan her anahtar şemaya uyuyor mu?
#   -> yazı tipi kur -> görünümü sıfırla + kaldır -> dconf kurulum öncesiyle aynı mı?
# gsettings, şemada olmayan anahtarı ya da yanlış tipte değeri reddeder; bu
# yüzden "dconf read == gsettings get" kontrolü sahte dconf'un yakalayamadığı
# hataları yakalar.
# ============================================================================
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
USER_NAME=tester
WORK=/opt/terminal-setup
TERM_PROFILES=/org/gnome/terminal/legacy/profiles:
TERM_SCHEMA=org.gnome.Terminal.Legacy.Profile
PTYXIS_UUID=0123456789abcdef0123456789abcdef

step() { printf '\n\033[1;36m=== %s ===\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31mBAŞARISIZ: %s\033[0m\n' "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Kullanıcı tarafı: dbus oturumu içinde çalışır
# ---------------------------------------------------------------------------

# Bir dconf dizinindeki her anahtar şemadaki tipiyle okunabiliyor mu?
#   check_schema /org/gnome/Ptyxis/ org.gnome.Ptyxis
#   check_schema /org/.../:UUID/ org.gnome.Terminal.Legacy.Profile relocatable
check_schema() {
    local dir="$1" schema="$2" mode="${3:-}" key raw typed
    [[ "$mode" == relocatable ]] && schema="$schema:$dir"
    for key in $(dconf list "$dir" | grep -v '/$'); do
        raw=$(dconf read "$dir$key")
        typed=$(gsettings get "$schema" "$key" 2>&1) || fail "$dir$key şemada yok: $typed"
        [[ "$raw" == "$typed" ]] || fail "$dir$key şemaya uymuyor: yazılan $raw, okunan $typed"
        printf '  ✓ %s\n' "$key"
    done
}

user_main() {
    local ptyxis=0 profile
    cd "$WORK"
    has() { command -v "$1" >/dev/null; }
    has ptyxis && ptyxis=1

    step "Kullanıcının kendi ayarları (dokunulmamalı)"
    profile="$TERM_PROFILES/:$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")/"
    dconf write "${profile}visible-name" "'Benim profilim'"
    dconf write "${profile}background-color" "'#101010'"
    dconf write "${profile}scrollback-lines" "50000"
    if ((ptyxis)); then
        # Ptyxis ilk açılışta profil oluşturur; konteynerde ekran yok, elle oluştur
        dconf write /org/gnome/Ptyxis/profile-uuids "['$PTYXIS_UUID']"
        dconf write /org/gnome/Ptyxis/default-profile-uuid "'$PTYXIS_UUID'"
        dconf write "/org/gnome/Ptyxis/Profiles/$PTYXIS_UUID/label" "'Benim profilim'"
    fi
    dconf dump / > /tmp/dconf-before

    step "Tema uygula: nord, sonra dracula"
    ./terminal-setup.sh --yes theme apply nord
    ./terminal-setup.sh --yes theme apply dracula
    [[ "$(dconf read "${profile}background-color")" == "'#282A36'" ]] || fail "GNOME Terminal arka planı dracula olmadı"

    step "GNOME Terminal anahtarları şemaya uyuyor mu?"
    check_schema "$profile" "$TERM_SCHEMA" relocatable
    if ((ptyxis)); then
        step "Ptyxis anahtarları şemaya uyuyor mu?"
        [[ -f "$HOME/.local/share/org.gnome.Ptyxis/palettes/terminal-setup.palette" ]] || fail "Ptyxis paleti yazılmadı"
        [[ "$(dconf read "/org/gnome/Ptyxis/Profiles/$PTYXIS_UUID/palette")" == "'terminal-setup'" ]] || fail "Ptyxis paleti seçilmedi"
        check_schema "/org/gnome/Ptyxis/Profiles/$PTYXIS_UUID/" org.gnome.Ptyxis.Profile relocatable
    fi

    step "Yazı tipi bileşeni (dconf font anahtarları)"
    ./terminal-setup.sh --yes install --components fonts
    [[ "$(dconf read "${profile}font")" == "'MesloLGS NF 11'" ]] || fail "GNOME Terminal yazı tipi ayarlanmadı: $(dconf read "${profile}font")"
    check_schema "$profile" "$TERM_SCHEMA" relocatable
    ((ptyxis)) && check_schema /org/gnome/Ptyxis/ org.gnome.Ptyxis

    step "Görünümü sıfırla"
    ./terminal-setup.sh --yes theme reset
    [[ "$(dconf read "${profile}background-color")" == "'#101010'" ]] || fail "kullanıcının arka plan rengi geri gelmedi"

    step "Tamamen kaldır"
    ./terminal-setup.sh --yes uninstall | tee /tmp/uninstall.log
    grep -q "Sonuç: kalıntı yok." /tmp/uninstall.log || fail "kaldırma raporu kalıntı buldu"

    step "dconf kurulum öncesiyle aynı mı?"
    dconf dump / > /tmp/dconf-after
    diff /tmp/dconf-before /tmp/dconf-after || fail "dconf ayarları farklı"
    [[ ! -e "$HOME/.local/share/org.gnome.Ptyxis/palettes/terminal-setup.palette" ]] || fail "Ptyxis paleti kaldı"
}

if [[ "${1:-}" == --user ]]; then
    user_main
    exit 0
fi

# ---------------------------------------------------------------------------
# Root tarafı: hazırlık
# ---------------------------------------------------------------------------
step "Hazırlık"
apt-get update -qq
apt-get install -y -qq --no-install-recommends sudo gnome-terminal dconf-cli libglib2.0-bin dbus dbus-user-session > /dev/null
if apt-cache show ptyxis > /dev/null 2>&1; then
    apt-get install -y -qq --no-install-recommends ptyxis > /dev/null
    echo "Ptyxis kuruldu"
else
    echo "Ptyxis bu sürümün deposunda yok; yalnızca GNOME Terminal sınanacak"
fi
. /etc/os-release
echo "$PRETTY_NAME"
if dpkg --compare-versions "$VERSION_ID" ge 25.10 && ! command -v ptyxis > /dev/null; then
    fail "Ubuntu $VERSION_ID'de Ptyxis bekleniyordu"
fi

useradd -m -s /bin/bash "$USER_NAME"
echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-tester
cp -r /src "$WORK"
chown -R "$USER_NAME:$USER_NAME" "$WORK"

su - "$USER_NAME" -c "dbus-run-session -- bash $WORK/tests/e2e/gnome.sh --user"

printf '\n\033[1;32mGNOME TESTİ BAŞARILI: tema gerçek dconf üzerinde uygulandı ve iz bırakmadan geri alındı.\033[0m\n'
