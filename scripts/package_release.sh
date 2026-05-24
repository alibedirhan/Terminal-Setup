#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

version="$(tr -d '[:space:]' < VERSION)"
name="Terminal-Setup-v${version}-safe-release"
out_dir="$ROOT_DIR/release"
mkdir -p "$out_dir"

bash scripts/check_static.sh

zip_path="$out_dir/${name}.zip"
sha_path="$zip_path.sha256"
rm -f "$zip_path" "$sha_path"

cd "$ROOT_DIR/.."
zip -r "$zip_path" "$(basename "$ROOT_DIR")" \
  -x '*/.git/*' \
     '*/release/*' \
     '*/dist/*' \
     '*/logs/*' \
     '*/backups/*' \
     '*/node_modules/*' \
     '*.DS_Store' \
     '*.zip' \
     '*.sha256' \
     '*.log' >/dev/null

cd "$out_dir"
sha256sum "$(basename "$zip_path")" > "$(basename "$sha_path")"

echo "Release paketi hazır: $zip_path"
echo "Checksum: $sha_path"
