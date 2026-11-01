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
for cmd in zsh starship fzf zoxide eza batcat rg fdfind delta lazygit btop dust duf procs atuin tldr tmux; do
    as_user "export PATH=\$HOME/.local/bin:\$PATH; command -v $cmd >/dev/null" || fail "$cmd bulunamadı"
    printf '  ✓ %s\n' "$cmd"
done
[[ "$(as_user 'git config --global --get core.pager')" == "delta" ]] || fail "delta git'e bağlanmadı"

step "Starship ve araç ayarları her kişilikte geçerli mi? (gerçek araçlar)"
cfg="/home/$USER_NAME/.config/terminal-setup/starship.toml"
grep -q 'palette = "terminal_setup"' "$cfg" || fail "Starship ayarı temadan üretilmedi"
for s in $(ls "$WORK"/styles | sed 's/\.style$//') auto; do
    as_user "./terminal-setup.sh --yes style set $s" > /dev/null || fail "kişilik seçilemedi: $s"
    as_user "export PATH=\$HOME/.local/bin:\$PATH; cd $WORK; STARSHIP_CONFIG=$cfg starship prompt --status=1 --cmd-duration=3000" \
        > /tmp/prompt.out 2> /tmp/prompt.err || fail "starship prompt hata verdi: $s"
    [[ -s /tmp/prompt.err ]] && { cat /tmp/prompt.err; fail "starship ayarında uyarı: $s"; }
    [[ -s /tmp/prompt.out ]] || fail "starship boş prompt çizdi: $s"
    # eza 11, bat 12, tmux 13, lazygit 14-15, karşılama kartı 16-17, komut paleti 18 (tests/e2e/tool_styles.zsh)
    as_user "zsh -f $WORK/tests/e2e/tool_styles.zsh" || fail "araç ayarı gerçek araçta hata verdi ($s, kod $?)"
    printf '  ✓ %s\n' "$s"
done

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

step "Yazı tipi seçimi (Fira Code Nerd Font)"
as_user "./terminal-setup.sh --yes install --components font-firacode" || fail "Fira Code kurulamadı"
as_user "fc-list : family" > /tmp/fonts.log
grep -q "FiraCode Nerd Font" /tmp/fonts.log || fail "Fira Code fontconfig'te görünmüyor"
as_user "./terminal-setup.sh font list" > /tmp/fontlist.log
grep -q "^\* firacode" /tmp/fontlist.log || fail "Fira Code seçilmedi"
as_user "./terminal-setup.sh --yes font set meslo" || fail "MesloLGS NF'ye dönülemedi"

step "Açılış ipucu ve kısayollar"
as_user "./terminal-setup.sh --yes tips --shell on" || fail "açılış ipucu açılamadı"
as_user "zsh -n \$HOME/.config/terminal-setup/zsh.d/95-tips.zsh" || fail "ipucu parçası zsh sözdizimine uymuyor"
as_user "./terminal-setup.sh tips" > /tmp/tips.log || fail "kısayollar ekranı hata verdi"
grep -q "Ctrl+T" /tmp/tips.log || fail "kısayollar listelenmedi"

step "Etkileşimli zsh oturumu (önbellek ve geçmiş dosyaları oluşsun)"
as_user "TERM=xterm-256color POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true script -qec 'zsh -i -c \"z --help >/dev/null; ls >/dev/null; exit\"' /dev/null" \
    > /tmp/zsh.log 2>&1 || { cat /tmp/zsh.log; fail "zsh başlangıcı hata verdi"; }
if grep -iE "command not found|no such file|error" /tmp/zsh.log; then
    fail "zsh başlangıcında hata mesajı var"
fi
# Oh My Zsh'siz temel: OSC 7 gönderilir (yeni sekme aynı dizinde), Oh My Zsh kurulmaz
grep -q $'\e]7;file://' /tmp/zsh.log || fail "zsh OSC 7 göndermedi (yeni sekme aynı dizinde açılmaz)"
[[ ! -e "/home/$USER_NAME/.oh-my-zsh" ]] || fail "varsayılan profil Oh My Zsh kurdu"
[[ -f "/home/$USER_NAME/.local/share/terminal-setup/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] ||
    fail "eklentiler veri klasörüne kurulmadı"
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
