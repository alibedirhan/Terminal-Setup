#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Başlangıç fotoğrafı
# ============================================================================
# İlk kurulumdan hemen önce sistemin hali bir kez kaydedilir ve hiçbir zaman
# rotasyona girmez. Kaldırmanın sonunda sistem bu fotoğrafla karşılaştırılır
# (lib/verify.sh). Fotoğraf yalnızca okuma yapar; hiçbir şeyi değiştirmez.
# ============================================================================

# Fotoğrafta içerik listesi tutulan konumlar: "dizin:derinlik"
BASELINE_WATCH=(
    "$HOME:1"
    "$HOME/.config:1"
    "$HOME/.local/bin:1"
    "$HOME/.local/share:1"
    "$HOME/.local/state:1"
    "$HOME/.cache:1"
)

baseline_exists() { [[ -f "$TS_BASELINE_DIR/meta" ]]; }

# Kurulu paketlerin sıralı listesi
baseline_list_packages() {
    has_cmd dpkg-query || return 0
    dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' 2>/dev/null \
        | awk '$1 == "ii" { print $2 }' | sort -u
}

# İzlenen konumlardaki dosya/dizin adları (durum dizini ve arşivler hariç)
baseline_list_paths() {
    local entry dir depth
    for entry in "${BASELINE_WATCH[@]}" "$TS_FONT_DIR:1"; do
        dir="${entry%:*}"
        depth="${entry##*:}"
        [[ -d "$dir" ]] || continue
        find "$dir" -mindepth 1 -maxdepth "$depth" 2>/dev/null
    done | grep -vE "^($TS_STATE_DIR|$HOME/terminal-setup-kaldirilan-)" | sort -u
}

baseline_list_gitconfig() {
    has_cmd git || return 0
    git config --global --list 2>/dev/null | sort
}

baseline_dump_dconf() {
    has_cmd dconf || return 0
    dconf dump "$1" 2>/dev/null
}

# Sistemin şu anki halini bir dizine yaz (fotoğraf ve doğrulama ortak kullanır)
baseline_capture_to() {
    local dir="$1"
    mkdir -p "$dir" || return 1
    baseline_list_packages > "$dir/packages.txt"
    sys_login_shell > "$dir/shell.txt"
    baseline_list_paths > "$dir/paths.txt"
    baseline_list_gitconfig > "$dir/gitconfig.txt"
    baseline_dump_dconf /org/gnome/terminal/ > "$dir/dconf-gnome-terminal.txt"
    baseline_dump_dconf /org/gnome/Ptyxis/ > "$dir/dconf-ptyxis.txt"
}

# Fotoğrafı al (zaten varsa dokunma)
baseline_take() {
    baseline_exists && return 0
    if is_dry_run; then
        log_plan "Başlangıç fotoğrafı alınacak: %s" "$(ts_pretty_path "$TS_BASELINE_DIR")"
        return 0
    fi
    log_step "Başlangıç fotoğrafı alınıyor (ilk kurulum)"
    baseline_capture_to "$TS_BASELINE_DIR" || return 1
    {
        echo "created=$(ts_now)"
        echo "version=$TS_VERSION"
        echo "os=$(sys_os)"
        echo "user=$USER"
    } > "$TS_BASELINE_DIR/meta"
    log_ok "Fotoğraf alındı: %s paket, giriş kabuğu %s" "$(wc -l < "$TS_BASELINE_DIR/packages.txt")" "$(cat "$TS_BASELINE_DIR/shell.txt")"
}

baseline_created_at() {
    sed -n 's/^created=//p' "$TS_BASELINE_DIR/meta" 2>/dev/null
}

baseline_had_package() {
    [[ -f "$TS_BASELINE_DIR/packages.txt" ]] && grep -qxF "$1" "$TS_BASELINE_DIR/packages.txt"
}
