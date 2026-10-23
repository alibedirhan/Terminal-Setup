#!/usr/bin/env bash
# ============================================================================
# Sürüm yayınlama: scripts/release.sh 6.1.0 [--publish]
# ============================================================================
# 1. Kontroller: temiz çalışma dizini, CHANGELOG'da sürüm başlığı
# 2. Statik kontroller ve testler
# 3. VERSION güncellenir, commit + etiket (vSÜRÜM)
# 4. Paket ve sağlama üretilir
# 5. GitHub release TASLAK olarak oluşturulur (--publish ile yayınlanır)
#
# Etiket ve release'i GitHub'a göndermeden önce son bir onay istenir.
# ============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

version="${1:-}"
publish=0
[[ "${2:-}" == "--publish" ]] && publish=1
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Kullanım: $0 X.Y.Z [--publish]" >&2; exit 2; }
tag="v$version"

[[ -z "$(git status --porcelain)" ]] || { echo "Çalışma dizini temiz değil." >&2; exit 1; }
grep -q "^## \[$version\]" CHANGELOG.md || { echo "CHANGELOG.md içinde '## [$version]' başlığı yok." >&2; exit 1; }
git rev-parse "$tag" >/dev/null 2>&1 && { echo "$tag zaten var." >&2; exit 1; }
command -v gh >/dev/null || { echo "GitHub CLI (gh) gerekli." >&2; exit 1; }

bash scripts/check_static.sh
if command -v bats >/dev/null; then
    bats tests/unit tests/integration
else
    echo "bats bulunamadı; testler CI'da çalışır." >&2
fi

if [[ "$(tr -d '[:space:]' < VERSION)" != "$version" ]]; then
    echo "$version" > VERSION
    git add VERSION
    git commit -m "chore: sürüm $version"
fi
git tag -a "$tag" -m "Terminal Setup $version"
bash scripts/package_release.sh

notes=$(awk -v v="$version" '$0 ~ "^## \\[" v "\\]" { on=1; next } /^## \[/ && on { exit } on' CHANGELOG.md)
read -r -p "$tag etiketi ve release GitHub'a gönderilsin mi? [e/H] " answer
[[ "${answer,,}" == "e" ]] || { echo "Gönderilmedi. Etiketi silmek için: git tag -d $tag"; exit 0; }

git push origin HEAD "$tag"
draft_flag=(--draft)
((publish)) && draft_flag=()
gh release create "$tag" "${draft_flag[@]}" --title "Terminal Setup $version" --notes "$notes" \
    "release/terminal-setup-$version.tar.gz" "release/terminal-setup-$version.tar.gz.sha256"
echo "Release oluşturuldu: $tag"
