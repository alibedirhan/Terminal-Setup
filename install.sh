#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Hızlı başlatıcı
# ============================================================================
# Belirli bir GitHub sürümünü (tag) indirir, SHA-256 ile doğrular ve geçici
# bir dizinden çalıştırır. Programın kendisi diske kurulmaz; iş bitince
# geçici dizin silinir. Sonradan kaldırmak için aynı betiği tekrar çalıştırın.
#
# Kullanım:
#   wget https://raw.githubusercontent.com/alibedirhan/Terminal-Setup/main/install.sh
#   bash install.sh                 # menüyü aç
#   bash install.sh uninstall       # her şeyi geri al
#   TS_RELEASE=v6.0.0 bash install.sh   # belirli bir sürüm
# ============================================================================
set -euo pipefail

REPO="alibedirhan/Terminal-Setup"

die() { printf '\033[0;31m✗\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[0;34mℹ\033[0m %s\n' "$*"; }
ok() { printf '\033[0;32m✓\033[0m %s\n' "$*"; }

[[ $EUID -ne 0 ]] || die "Root olarak değil, normal kullanıcıyla çalıştırın."
for cmd in tar sha256sum; do
    command -v "$cmd" >/dev/null || die "'$cmd' bulunamadı."
done

if command -v curl >/dev/null; then
    fetch() { curl -fsSL --retry 3 --connect-timeout 15 -o "$2" "$1"; }
    final_url() { curl -fsSLI -o /dev/null -w '%{url_effective}' "$1"; }
elif command -v wget >/dev/null; then
    fetch() { wget -q --tries=3 --timeout=15 -O "$2" "$1"; }
    final_url() { wget -q --max-redirect=5 -S --spider "$1" 2>&1 | awk '/^  Location: /{ u=$2 } END { print u }'; }
else
    die "curl ya da wget gerekli: sudo apt install wget"
fi

tag="${TS_RELEASE:-}"
if [[ -z "$tag" ]]; then
    url=$(final_url "https://github.com/$REPO/releases/latest" || true)
    tag="${url##*/tag/}"
    [[ -n "$tag" && "$tag" != "$url" ]] || die "Yayınlanmış sürüm bulunamadı. Depoyu klonlayarak kurabilirsiniz:
  git clone https://github.com/$REPO.git && cd Terminal-Setup && ./terminal-setup.sh"
fi
version="${tag#v}"
asset="terminal-setup-$version.tar.gz"

work=$(mktemp -d "${TMPDIR:-/tmp}/terminal-setup-install.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT

info "Terminal Setup $tag indiriliyor"
base="https://github.com/$REPO/releases/download/$tag"
fetch "$base/$asset" "$work/$asset" || die "İndirilemedi: $base/$asset"
fetch "$base/$asset.sha256" "$work/$asset.sha256" || die "Sağlama dosyası indirilemedi"

expected=$(awk '{ print $1 }' "$work/$asset.sha256")
actual=$(sha256sum "$work/$asset" | awk '{ print $1 }')
[[ -n "$expected" && "$expected" == "$actual" ]] || die "SHA-256 doğrulaması başarısız; dosya bozuk ya da değiştirilmiş."
ok "SHA-256 doğrulandı"

tar -xzf "$work/$asset" -C "$work"
root="$work/terminal-setup-$version"
[[ -x "$root/terminal-setup.sh" ]] || die "Arşiv beklenen yapıda değil"

# Menü ya da verilen komut; çıkışta geçici dizin silinir
"$root/terminal-setup.sh" "$@"
