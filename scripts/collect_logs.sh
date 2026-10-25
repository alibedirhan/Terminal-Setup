#!/usr/bin/env bash
# ============================================================================
# Hata bildirimi için log paketi: terminal-setup-log-TARİH.tar.gz
# ============================================================================
# İçerik: sistem bilgisi, durum ve teşhis çıktısı, log dosyası, defter.
# Kişisel dosya içeriği eklenmez. Paketi paylaşmadan önce göz atın.
# ============================================================================
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
state="${TS_STATE_DIR:-$HOME/.terminal-setup}"
stamp="$(date +%Y%m%d-%H%M%S)"
out="terminal-setup-log-$stamp"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/$out"

{
    echo "Tarih: $(date --iso-8601=seconds)"
    echo "Sürüm: $(cat "$ROOT_DIR/VERSION" 2>/dev/null)"
    uname -a
    grep PRETTY_NAME /etc/os-release
    echo "SHELL=${SHELL:-} TERM=${TERM:-} XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-}"
} > "$work/$out/sistem.txt" 2>&1

NO_COLOR=1 "$ROOT_DIR/terminal-setup.sh" status > "$work/$out/durum.txt" 2>&1
NO_COLOR=1 "$ROOT_DIR/terminal-setup.sh" doctor < /dev/null > "$work/$out/teshis.txt" 2>&1
cp "$state/logs/terminal-setup.log" "$work/$out/" 2>/dev/null
cp "$state/ledger" "$work/$out/defter.txt" 2>/dev/null

tar -czf "$out.tar.gz" -C "$work" "$out"
echo "Log paketi hazır: $PWD/$out.tar.gz"
