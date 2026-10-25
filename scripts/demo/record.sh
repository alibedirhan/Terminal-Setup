#!/usr/bin/env bash
# ============================================================================
# README görselleri: ekran görüntüleri ve animasyonlar (docs/images/)
# ============================================================================
# Menü tmux içinde, testlerin sahte sisteminde çalıştırılır (tests/helpers/):
# gerçek sisteme, paketlere ya da dconf'a dokunulmaz, ağa çıkılmaz. Önce
# sahte sisteme "full" profil ve Nord teması kurulur ki ekranlar dolu görünsün.
# Tuşlar gönderilir, her adımda ekran renkleriyle yakalanır (capture-pane -e)
# ve scripts/demo/render.py ile PNG/GIF'e çevrilir.
#
# Gerekenler: tmux, python3 + Pillow, DejaVu Sans Mono.
# Kullanım: scripts/demo/record.sh   (arayüz değişince yeniden çalıştırın)
# ============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/docs/images"
COLS=100 ROWS=34

# Sahte sistem PATH'i daraltır; araçların yolu önceden alınır
TMUX_BIN=$(command -v tmux) || { echo "tmux gerekli" >&2; exit 1; }
PYTHON=$(command -v python3) || { echo "python3 gerekli" >&2; exit 1; }
"$PYTHON" -c "import PIL" 2>/dev/null || { echo "Pillow gerekli: sudo apt install python3-pil" >&2; exit 1; }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/ts-demo.XXXXXXXX")
SOCK="ts-demo-$$"
trap '"$TMUX_BIN" -L "$SOCK" kill-server 2>/dev/null || true; rm -rf -- "$WORK"' EXIT
FRAMES="$WORK/frames"
mkdir -p "$FRAMES" "$OUT"

# Sahte sistem (testlerle aynı); common.bash bats değişkenlerini bekler
export BATS_TEST_TMPDIR="$WORK/sys" BATS_TEST_FILENAME="$ROOT/tests/unit/demo"
mkdir -p "$BATS_TEST_TMPDIR"
# shellcheck source=tests/helpers/common.bash
source "$ROOT/tests/helpers/common.bash"
setup_fakesys
"$ROOT/terminal-setup.sh" --yes install --profile full --theme nord > "$WORK/install.log" 2>&1
echo "update_check=off" >> "$HOME/.terminal-setup/settings"

# ----------------------------------------------------------------------------
# tmux yardımcıları
# ----------------------------------------------------------------------------
t() { "$TMUX_BIN" -L "$SOCK" "$@"; }

# Menüyü verilen dille başlat: start_menu tr|en
start_menu() {
    t kill-server 2>/dev/null || true
    export -p > "$WORK/env.sh"
    t -f /dev/null new-session -d -s d -x "$COLS" -y "$ROWS" \
        "bash --norc --noprofile -c 'source \"$WORK/env.sh\"; unset NO_COLOR; export TS_LANG=$1 TERM=xterm-256color COLORTERM=truecolor; exec \"$ROOT/terminal-setup.sh\"'"
    wait_for "$2"
}

wait_for() {
    local i
    for ((i = 0; i < 100; i++)); do
        t capture-pane -p -t d | grep -qF -- "$1" && { sleep 0.3; return 0; }
        sleep 0.1
    done
    echo "Ekranda beklenen metin yok: $1" >&2
    t capture-pane -p -t d >&2
    exit 1
}

keys() { local k; for k in "$@"; do t send-keys -t d "$k"; sleep 0.25; done; }

N=0
SCENE=()
# Kareyi yakala ve sahneye ekle: snap SÜRE_MS [ad]
snap() {
    local file
    printf -v file '%s/%03d%s.ansi' "$FRAMES" "$N" "${2:+-$2}"
    N=$((N + 1))
    sleep 0.2
    t capture-pane -e -p -t d > "$file"
    SCENE+=("$file:$1")
    LAST="$file"
}

render_gif() { "$PYTHON" "$ROOT/scripts/demo/render.py" gif "$OUT/$1" "${SCENE[@]}"; SCENE=(); }
render_png() { "$PYTHON" "$ROOT/scripts/demo/render.py" png "$OUT/$1" "$LAST"; }

# ----------------------------------------------------------------------------
# Sahneler
# ----------------------------------------------------------------------------

# 1. Ana menü (Türkçe ve İngilizce)
start_menu tr "Ne yapmak istersiniz?"
snap 0
render_png ana-menu.png
SCENE=()
start_menu en "What would you like to do?"
snap 0
render_png main-menu.png
SCENE=()

# 2. Tema dene: yedi temada gezinme (Türkçe ve İngilizce)
theme_tour() {
    start_menu "$1" "$2"
    keys 2
    wait_for "$3"
    snap 1600
    for _ in 1 2 3 4 5 6 7; do
        keys Right
        snap 1300
    done
    render_gif "$4"
}
theme_tour tr "Ne yapmak istersiniz?" "Tema dene" tema-dene.gif
theme_tour en "What would you like to do?" "Try themes" theme-browser.gif

# 3. Menü turu: gezinme, bileşenler, güncelleme, dil değiştirme
start_menu tr "Ne yapmak istersiniz?"
snap 1800
for _ in 1 2 3; do keys Down; snap 350; done
keys Up Up Up 3
wait_for "işareti kaldırılanlar"
snap 1500
for _ in 1 2 3 4 5 6; do keys Down; snap 300; done
keys q
wait_for "Ne yapmak istersiniz?"
keys 6
wait_for "Her şey güncel."
snap 2500
keys Enter
wait_for "Ne yapmak istersiniz?"
keys 8
wait_for "Dil / Language"
snap 1200
keys Enter
wait_for "English"
snap 1000
keys 3
wait_for "Settings"
snap 1000
keys q
wait_for "What would you like to do?"
snap 3000
render_gif menu-turu.gif

ls -lh "$OUT"
