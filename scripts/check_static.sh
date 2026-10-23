#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Statik kontroller
# ============================================================================
# Kurallar (docs/ARCHITECTURE.md):
#   1. Tüm .sh dosyaları bash sözdizimi kontrolünden geçer.
#   2. ShellCheck: uyarı seviyesinde sıfır bulgu.
#   3. Hiçbir .sh dosyası 600 satırı aşamaz.
#   4. Sisteme dokunan komutlar yalnızca lib/actions/ içinde kullanılır.
#   5. curl/wget çıktısı doğrudan bir kabuğa borulanmaz.
#
# Kullanım: scripts/check_static.sh [--shellcheck PATH]
# ============================================================================
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

SHELLCHECK="${SHELLCHECK:-shellcheck}"
if [[ "${1:-}" == "--shellcheck" && -n "${2:-}" ]]; then
    SHELLCHECK="$2"
fi

MAX_LINES=600
failures=0

fail() {
    echo "  [HATA] $*" >&2
    failures=$((failures + 1))
}

# Geçiş süresince kurallardan muaf tutulan eski (v5) dosyalar.
# Yeni mimariye taşındıkça bu liste boşalır; boş olması hedeftir.
LEGACY_FILES=(
    "core/terminal-base.sh"
    "core/terminal-config.sh"
    "core/terminal-tools.sh"
    "install.sh"
    "scripts/check_repo_links.sh"
    "scripts/collect_logs.sh"
    "scripts/package_release.sh"
    "smart-release-manager.sh"
    "smart-version-manager.sh"
    "terminal-assistant.sh"
    "terminal-router.sh"
    "terminal-setup.sh"
    "terminal-ui.sh"
    "themes/catppuccin.sh"
    "themes/dracula.sh"
    "themes/gruvbox.sh"
    "themes/nord.sh"
    "themes/one-dark.sh"
    "themes/solarized.sh"
    "themes/tokyo-night.sh"
    "utils/config.sh"
    "utils/helpers.sh"
    "utils/system.sh"
)

is_legacy() {
    local file="$1" legacy
    for legacy in "${LEGACY_FILES[@]}"; do
        [[ "$file" == "$legacy" ]] && return 0
    done
    return 1
}

mapfile -t SH_FILES < <(git ls-files --cached --others --exclude-standard -- '*.sh' '*.bash' | sort)
mapfile -t BATS_FILES < <(git ls-files --cached --others --exclude-standard -- '*.bats' | sort)

echo "[1/5] Bash sözdizimi (${#SH_FILES[@]} dosya)"
for file in "${SH_FILES[@]}"; do
    bash -n "$file" 2>/dev/null || fail "Sözdizimi hatası: $file"
done

echo "[2/5] ShellCheck"
if command -v "$SHELLCHECK" >/dev/null 2>&1; then
    check_targets=()
    for file in "${SH_FILES[@]}"; do
        is_legacy "$file" || check_targets+=("$file")
    done
    if ((${#check_targets[@]} > 0)); then
        if ! "$SHELLCHECK" -x -S warning "${check_targets[@]}"; then
            fail "ShellCheck uyarıları var"
        fi
    fi
else
    fail "ShellCheck bulunamadı ($SHELLCHECK)"
fi

echo "[3/5] Dosya boyutu (en fazla $MAX_LINES satır)"
for file in "${SH_FILES[@]}" "${BATS_FILES[@]}"; do
    lines=$(wc -l < "$file")
    if ((lines > MAX_LINES)); then
        if is_legacy "$file"; then
            echo "  [muaf] $file: $lines satır"
        else
            fail "$file: $lines satır (sınır $MAX_LINES)"
        fi
    fi
done

echo "[4/5] Yan etki kuralı (yalnızca lib/actions/)"
# Sistemi değiştiren komut kalıpları. Okuma amaçlı kullanımlar (dconf read,
# git config --get) kurala takılmaz.
side_effect_pattern='(^|[;&|[:space:]])(sudo|apt-get|apt|snap|chsh|gsettings[[:space:]]+set|dconf[[:space:]]+(write|reset|load)|git[[:space:]]+config[[:space:]]+--global[[:space:]]+[^-]|fc-cache)([[:space:]]|$)'
for file in "${SH_FILES[@]}"; do
    case "$file" in
        lib/actions/*|lib/sudo.sh|tests/*|scripts/*|install.sh) continue ;;
    esac
    is_legacy "$file" && continue
    # Yorum satırlarını ve echo/printf ile yazılan yönergeleri atla.
    if grep -nE "$side_effect_pattern" "$file" \
        | grep -vE '^[0-9]+:[[:space:]]*#' \
        | grep -vE '(echo|printf|ui_[a-z_]+|log_[a-z]+)[[:space:]]' \
        | grep -q .; then
        grep -nE "$side_effect_pattern" "$file" \
            | grep -vE '^[0-9]+:[[:space:]]*#' \
            | grep -vE '(echo|printf|ui_[a-z_]+|log_[a-z]+)[[:space:]]' \
            | sed "s|^|  $file:|" >&2
        fail "$file: lib/actions/ dışında sisteme dokunan komut"
    fi
done

echo "[5/5] Borulu kurulum yasağı (curl|sh)"
for file in "${SH_FILES[@]}"; do
    [[ "$file" == "scripts/check_static.sh" ]] && continue
    if grep -nE '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh([[:space:]]|$)' "$file" \
        | grep -vE '^[0-9]+:[[:space:]]*#' | grep -q .; then
        fail "$file: curl/wget çıktısı kabuğa borulanıyor"
    fi
done

echo
if ((failures > 0)); then
    echo "Statik kontrol BAŞARISIZ: $failures hata." >&2
    exit 1
fi
echo "Statik kontrol başarılı."
