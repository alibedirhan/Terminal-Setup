#!/usr/bin/env bash
# ============================================================================
# Terminal Setup — Ubuntu terminal özelleştirme aracı
# ============================================================================
# Giriş noktası. Mimari için: docs/ARCHITECTURE.md
#
#   lib/         motor (defter, fotoğraf, eylemler, çalıştırıcı)
#   components/  kurulabilir bileşenler (veri gibi tanımlanır)
#   themes/      renk paletleri        renderers/  paleti terminale çevirir
#   frontends/   menü (tui) ve komut satırı (cli)
#   diagnostics/ sağlık kontrolleri
# ============================================================================
set -uo pipefail

if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
    echo "Bash 4.4 veya üstü gerekli (mevcut: $BASH_VERSION)" >&2
    exit 1
fi

TS_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
export TS_ROOT

# shellcheck source=lib/core.sh
source "$TS_ROOT/lib/core.sh"
ts_load || exit 1
cli_main "$@"
