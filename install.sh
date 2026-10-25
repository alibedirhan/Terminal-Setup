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
#   TS_RELEASE=v6.1.1 bash install.sh   # belirli bir sürüm
# ============================================================================
set -euo pipefail

REPO="alibedirhan/Terminal-Setup"

# Dil: programla aynı sıra (--lang, TS_LANG, kayıtlı ayar, sistem dili)
ts_lang() {
    local prev="" a lang="${TS_LANG:-}"
    for a in "$@"; do
        [[ "$prev" == --lang ]] && lang="$a"
        [[ "$a" == --lang=* ]] && lang="${a#--lang=}"
        prev="$a"
    done
    if [[ -z "$lang" && -r "$HOME/.terminal-setup/settings" ]]; then
        lang=$(sed -n 's/^language=//p' "$HOME/.terminal-setup/settings" | head -1)
    fi
    case "$lang" in
        tr|en) echo "$lang" ;;
        *) [[ "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" == tr* ]] && echo tr || echo en ;;
    esac
}
LANG_UI=$(ts_lang "$@")

# Dile göre metin: m "Türkçe" "English"
m() { [[ "$LANG_UI" == tr ]] && printf '%s' "$1" || printf '%s' "$2"; }

die() { printf '\033[0;31m✗\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[0;34mℹ\033[0m %s\n' "$*"; }
ok() { printf '\033[0;32m✓\033[0m %s\n' "$*"; }

[[ $EUID -ne 0 ]] || die "$(m "Root olarak değil, normal kullanıcıyla çalıştırın." "Run as a regular user, not as root.")"
for cmd in tar sha256sum; do
    command -v "$cmd" >/dev/null || die "$(m "'$cmd' bulunamadı." "'$cmd' not found.")"
done

if command -v curl >/dev/null; then
    fetch() { curl -fsSL --retry 3 --connect-timeout 15 -o "$2" "$1"; }
    final_url() { curl -fsSLI -o /dev/null -w '%{url_effective}' "$1"; }
elif command -v wget >/dev/null; then
    fetch() { wget -q --tries=3 --timeout=15 -O "$2" "$1"; }
    final_url() { wget -q --max-redirect=5 -S --spider "$1" 2>&1 | awk '/^  Location: /{ u=$2 } END { print u }'; }
else
    die "$(m "curl ya da wget gerekli" "curl or wget is required"): sudo apt install wget"
fi

tag="${TS_RELEASE:-}"
if [[ -z "$tag" ]]; then
    url=$(final_url "https://github.com/$REPO/releases/latest" || true)
    tag="${url##*/tag/}"
    [[ -n "$tag" && "$tag" != "$url" ]] || die "$(m "Yayınlanmış sürüm bulunamadı. Depoyu klonlayarak kurabilirsiniz:" "No published release found. You can install by cloning the repository:")
  git clone https://github.com/$REPO.git && cd Terminal-Setup && ./terminal-setup.sh"
fi
version="${tag#v}"
asset="terminal-setup-$version.tar.gz"

work=$(mktemp -d "${TMPDIR:-/tmp}/terminal-setup-install.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT

info "$(m "Terminal Setup $tag indiriliyor" "Downloading Terminal Setup $tag")"
# TS_RELEASE_BASE yalnızca testler içindir (ör. file:///yol/release)
base="${TS_RELEASE_BASE:-https://github.com/$REPO/releases/download/$tag}"
fetch "$base/$asset" "$work/$asset" || die "$(m "İndirilemedi" "Could not download"): $base/$asset"
fetch "$base/$asset.sha256" "$work/$asset.sha256" || die "$(m "Sağlama dosyası indirilemedi" "Could not download the checksum file")"

expected=$(awk '{ print $1 }' "$work/$asset.sha256")
actual=$(sha256sum "$work/$asset" | awk '{ print $1 }')
[[ -n "$expected" && "$expected" == "$actual" ]] || die "$(m "SHA-256 doğrulaması başarısız; dosya bozuk ya da değiştirilmiş." "SHA-256 check failed; the file is corrupt or was modified.")"
ok "$(m "SHA-256 doğrulandı" "SHA-256 verified")"

tar -xzf "$work/$asset" -C "$work"
root="$work/terminal-setup-$version"
[[ -x "$root/terminal-setup.sh" ]] || die "$(m "Arşiv beklenen yapıda değil" "The archive does not have the expected layout")"

# Menü ya da verilen komut; çıkışta geçici dizin silinir
"$root/terminal-setup.sh" "$@"
