#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

echo "[1/3] Eski repository adı kontrolü"
if grep -RIn --exclude-dir=.git --exclude-dir=release --exclude-dir=dist --exclude='*.zip' --exclude='check_repo_links.sh' 'Terminal-Theme-format-after' .; then
  fail "Eski repository adı bulundu. Terminal-Setup olarak güncellenmeli."
fi

echo "[2/3] Doğru repository linki kontrolü"
for file in README.md INSTALL.md; do
  grep -q 'github.com/alibedirhan/Terminal-Setup' "$file" || fail "$file içinde doğru GitHub linki yok"
done
grep -q 'raw.githubusercontent.com/alibedirhan/Terminal-Setup' install.sh || fail "install.sh içinde doğru raw GitHub linki yok"

echo "[3/3] Kişisel/özel isim sızıntısı kontrolü"
if grep -RIn --exclude-dir=.git --exclude-dir=release --exclude-dir=dist --exclude='*.zip' --exclude='check_repo_links.sh' -Ei 'mrgözlük|mr\. gözlük|deniz|gözlük' .; then
  fail "Kişisel/özel isim izi bulundu."
fi

echo "Repository link kontrolü OK"
