#!/usr/bin/env bash
# ============================================================================
# Sürüm paketi: release/terminal-setup-SÜRÜM.tar.gz ve .sha256
# ============================================================================
# install.sh bu iki dosyayı GitHub release'inden indirip doğrular. Paket
# "git archive" ile üretilir: yalnızca commit'lenmiş dosyalar girer;
# .gitattributes'ta export-ignore olanlar (testler, CI) girmez.
# ============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

version="$(tr -d '[:space:]' < VERSION)"
name="terminal-setup-$version"
out_dir="$ROOT_DIR/release"
mkdir -p "$out_dir"

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Çalışma dizini temiz değil; önce commit'leyin." >&2
    exit 1
fi

git archive --format=tar.gz --prefix="$name/" -o "$out_dir/$name.tar.gz" HEAD
(cd "$out_dir" && sha256sum "$name.tar.gz" > "$name.tar.gz.sha256")

echo "Paket: $out_dir/$name.tar.gz"
echo "Sağlama: $(cat "$out_dir/$name.tar.gz.sha256")"
