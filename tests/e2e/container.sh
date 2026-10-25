#!/usr/bin/env bash
# ============================================================================
# Gerçek gidiş-dönüş testi (CI'da temiz bir Ubuntu konteynerinde root olarak)
# ============================================================================
#   docker run --rm -v "$PWD:/src:ro" ubuntu:24.04 bash /src/tests/e2e/container.sh
#
# Adımlar: normal kullanıcı oluştur -> sistemin fotoğrafını al -> tam profil
# + tema kur -> zsh'i etkileşimli başlat (önbellekler, geçmiş oluşsun) ->
# tekrar kur (değişiklik olmamalı) -> kaldır -> sistem fotoğrafla aynı mı?
# Fark varsa test başarısız olur.
# ============================================================================
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
USER_NAME=tester
WORK=/opt/terminal-setup
SNAP=/tmp/e2e-snap

step() { printf '\n\033[1;36m=== %s ===\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31mBAŞARISIZ: %s\033[0m\n' "$*"; exit 1; }

# Çıktı Türkçe metinlerle denetlenir; konteynerin dili ne olursa olsun Türkçe
as_user() { su - "$USER_NAME" -c "export TS_LANG=tr; cd $WORK && $*"; }

step "Hazırlık"
apt-get update -qq
apt-get install -y -qq sudo locales > /dev/null
locale-gen tr_TR.UTF-8 > /dev/null 2>&1 || true
useradd -m -s /bin/bash "$USER_NAME"
echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-tester
cp -r /src "$WORK"
chown -R "$USER_NAME:$USER_NAME" "$WORK"
cat /etc/os-release | grep PRETTY_NAME

snapshot() {
    local dir="$SNAP/$1"
    mkdir -p "$dir"
    dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' | awk '$1 == "ii" { print $2 }' | sort > "$dir/packages"
    (cd "/home/$USER_NAME" && find . -mindepth 1 | grep -v '^./terminal-setup-kaldirilan-' | sort) > "$dir/home"
    getent passwd "$USER_NAME" | cut -d: -f7 > "$dir/shell"
    sort /etc/shells > "$dir/shells"
}

step "Kurulum öncesi fotoğraf"
snapshot before
wc -l "$SNAP/before/packages"

step "Prova modu hiçbir şey değiştirmemeli"
as_user "./terminal-setup.sh --dry-run --yes install --profile full --theme nord" > /tmp/dry.log
snapshot dry
diff -r "$SNAP/before" "$SNAP/dry" || fail "prova modu sistemi değiştirdi"

step "Tam kurulum + tema"
as_user "./terminal-setup.sh --yes install --profile full --theme nord" || fail "kurulum başarısız"
[[ "$(getent passwd "$USER_NAME" | cut -d: -f7)" == */zsh ]] || fail "varsayılan kabuk zsh olmadı"

step "Araçlar çalışıyor mu?"
for cmd in zsh fzf zoxide eza batcat rg fdfind delta lazygit btop dust duf procs atuin tldr tmux; do
    as_user "export PATH=\$HOME/.local/bin:\$PATH; command -v $cmd >/dev/null" || fail "$cmd bulunamadı"
    printf '  ✓ %s\n' "$cmd"
done
[[ "$(as_user 'git config --global --get core.pager')" == "delta" ]] || fail "delta git'e bağlanmadı"

step "Tema araçlara uygulandı mı?"
snippet="/home/$USER_NAME/.config/terminal-setup/zsh.d/65-theme-tools.zsh"
grep -qx "export BAT_THEME='Nord'" "$snippet" || fail "BAT_THEME yazılmadı"
[[ -f "/home/$USER_NAME/.config/btop/themes/terminal-setup.theme" ]] || fail "btop teması yazılmadı"
# Her temanın bat teması bu Ubuntu'nun bat sürümünde gerçekten var mı?
batcat --list-themes --color=never > /tmp/bat-themes
for f in "$WORK"/themes/*.theme; do
    t=$(sed -n 's/^BAT_THEME="\(.*\)"$/\1/p' "$f")
    grep -qxF "$t" /tmp/bat-themes || fail "$(basename "$f"): bat teması yok: $t"
    printf '  ✓ %s → %s\n' "$(basename "$f" .theme)" "$t"
done

step "Açılış ipucu ve kısayollar"
as_user "./terminal-setup.sh --yes tips --shell on" || fail "açılış ipucu açılamadı"
as_user "zsh -n \$HOME/.config/terminal-setup/zsh.d/95-tips.zsh" || fail "ipucu parçası zsh sözdizimine uymuyor"
as_user "./terminal-setup.sh tips" | grep -q "Ctrl+T" || fail "kısayollar listelenmedi"

step "Etkileşimli zsh oturumu (önbellek ve geçmiş dosyaları oluşsun)"
as_user "TERM=xterm-256color POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true script -qec 'zsh -i -c \"z --help >/dev/null; ls >/dev/null; exit\"' /dev/null" \
    > /tmp/zsh.log 2>&1 || { cat /tmp/zsh.log; fail "zsh başlangıcı hata verdi"; }
if grep -iE "command not found|no such file|error" /tmp/zsh.log; then
    fail "zsh başlangıcında hata mesajı var"
fi
echo "echo merhaba" | as_user "cat >> \$HOME/.zsh_history"

step "İkinci kurulum hiçbir şeyi değiştirmemeli"
cp "/home/$USER_NAME/.terminal-setup/ledger" /tmp/ledger1
as_user "./terminal-setup.sh --yes install --profile full --theme nord" > /tmp/install2.log
diff /tmp/ledger1 "/home/$USER_NAME/.terminal-setup/ledger" || fail "ikinci kurulum deftere yeni kayıt ekledi"

step "Durum ve teşhis"
as_user "./terminal-setup.sh status"
as_user "./terminal-setup.sh doctor < /dev/null" || true

step "Tek bileşen kaldırma (delta)"
as_user "./terminal-setup.sh --yes remove delta"
as_user "git config --global --get core.pager" && fail "delta kaldırıldı ama core.pager duruyor"

step "Tamamen kaldır"
as_user "./terminal-setup.sh --yes uninstall" | tee /tmp/uninstall.log
grep -q "Sonuç: kalıntı yok." /tmp/uninstall.log || fail "kaldırma raporu kalıntı buldu"

step "Kurulum öncesiyle karşılaştır"
snapshot after
diff "$SNAP/before/packages" "$SNAP/after/packages" || fail "paket listesi farklı"
diff "$SNAP/before/home" "$SNAP/after/home" || fail "ev dizini farklı"
diff "$SNAP/before/shell" "$SNAP/after/shell" || fail "giriş kabuğu farklı"
diff "$SNAP/before/shells" "$SNAP/after/shells" || fail "/etc/shells farklı"

arc=$(ls -d /home/$USER_NAME/terminal-setup-kaldirilan-*)
[[ -f "$arc/.zsh_history" ]] || fail "komut geçmişi arşive taşınmadı"
echo "Arşiv içeriği:"
(cd "$arc" && find . -mindepth 1 | sort)

printf '\n\033[1;32mGİDİŞ-DÖNÜŞ TESTİ BAŞARILI: sistem kurulum öncesiyle aynı.\033[0m\n'
