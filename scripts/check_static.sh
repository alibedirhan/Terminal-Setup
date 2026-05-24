#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

echo "[1/10] Zorunlu dosyalar"
required=(
  VERSION
  README.md
  INSTALL.md
  LICENSE
  install.sh
  terminal-setup.sh
  terminal-ui.sh
  terminal-router.sh
  terminal-assistant.sh
  core/terminal-base.sh
  core/terminal-tools.sh
  core/terminal-config.sh
  utils/helpers.sh
  utils/system.sh
  utils/config.sh
  aliases/.aliases
)
for file in "${required[@]}"; do
  [[ -f "$file" ]] || fail "Eksik dosya: $file"
done

echo "[2/10] Bash sözdizimi"
while IFS= read -r -d '' file; do
  bash -n "$file" || fail "Bash syntax hatası: $file"
done < <(find . -path './.git' -prune -o -path './release' -prune -o -path './dist' -prune -o -name '*.sh' -print0)

echo "[3/10] Repository linkleri"
bash scripts/check_repo_links.sh

echo "[4/10] VERSION tutarlılığı"
version="$(tr -d '[:space:]' < VERSION)"
[[ -n "$version" ]] || fail "VERSION boş"
grep -q "version-${version}" README.md || fail "README badge VERSION ile uyumlu değil: $version"
grep -q "readonly VERSION=\"${version}\"" install.sh || fail "install.sh VERSION ile uyumlu değil: $version"

echo "[5/10] Installer required file kontrolü"
for file in "${required[@]}"; do
  case "$file" in
    README.md|INSTALL.md|LICENSE|install.sh) continue ;;
  esac
  grep -q "\"$file\"" install.sh || fail "install.sh REQUIRED_FILES içinde eksik: $file"
done

echo "[6/10] Menü/route kontrolü"
grep -q '1) do_full_install ;;' terminal-router.sh || fail "Route 1 Tam Kurulum yanlış"
grep -q '2) do_modular_install ;;' terminal-router.sh || fail "Route 2 Modüler Kurulum yanlış"
grep -q '3) do_change_theme ;;' terminal-router.sh || fail "Route 3 Tema Değiştir yanlış"
grep -q '4) do_tools ;;' terminal-router.sh || fail "Route 4 Terminal Araçları yanlış"
grep -q '5) do_tmux ;;' terminal-router.sh || fail "Route 5 Tmux yanlış"
grep -q '6) do_health_and_diagnostics ;;' terminal-router.sh || fail "Route 6 Sağlık & Teşhis yanlış"
grep -q '7) do_backups ;;' terminal-router.sh || fail "Route 7 Yedekler yanlış"
grep -q '8) do_settings ;;' terminal-router.sh || fail "Route 8 Ayarlar yanlış"
grep -q '9) do_uninstall ;;' terminal-router.sh || fail "Route 9 Kaldır yanlış"
grep -q '0)' terminal-router.sh || fail "Route 0 Çıkış yok"
grep -q "Seçiminiz (0-9)" terminal-ui.sh || fail "Ana menü seçim aralığı 0-9 değil"
grep -q "do_backups" terminal-router.sh || fail "Yedek route fonksiyonu yok"
grep -q "restore_backup_snapshot" core/terminal-base.sh || fail "Yedek geri yükleme fonksiyonu yok"
grep -q 'create_backup "before_restore" "no_cleanup"' core/terminal-base.sh || fail "Geri yükleme öncesi yedek eski seçimi silebilir"
grep -q "terminal-router.sh" terminal-setup.sh || fail "Ana script router modülünü yüklemiyor"

echo "[7/10] 71x45 terminal UI kontrolü"
grep -q 'TERMINAL_TARGET_COLS=71' terminal-ui.sh || fail "Terminal hedef genişliği 71 değil"
grep -q 'TERMINAL_TARGET_ROWS=45' terminal-ui.sh || fail "Terminal hedef yüksekliği 45 değil"
grep -q '\033\[8;%s;%st' terminal-ui.sh || fail "Terminal resize kaçış dizisi yok"

echo "[8/10] Riskli release dosyası kontrolü"
if find . -path './.git' -prune -o -path './release' -prune -o -path './dist' -prune -o -type f \( -name '*.zip' -o -name '*.sha256' -o -name '*.log' \) -print | grep -q .; then
  fail "Repo içinde release/log artığı var"
fi

echo "[9/10] Doğrudan curl/wget pipe kontrolü"
if grep -RIn --exclude-dir=.git --exclude-dir=release --exclude-dir=dist --exclude='*.md' --exclude='check_static.sh' -E 'curl .*[|] *(bash|sh)|wget .*[|] *(bash|sh)' .; then
  fail "Kod içinde doğrudan curl/wget pipe kurulumu bulundu"
fi

echo "[10/10] Paket scripti hızlı kontrol"
bash -n scripts/package_release.sh

echo "Statik kontrol tamamlandı."
