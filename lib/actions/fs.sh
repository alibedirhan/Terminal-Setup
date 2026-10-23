#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Eylem: dosya ve dizinler
# ============================================================================
# Kural: bir yol yalnızca script onu OLUŞTURDUYSA deftere yazılır. Zaten
# var olan bir şey kullanıcınındır ve kaldırmada dokunulmaz.
#
# Kayıt türleri:
#   path      tamamen script'e ait; kaldırırken silinir (rm -rf)
#   dir       paylaşılan dizin (~/.local/bin gibi); yalnızca boşsa silinir
#   glob      kalıba uyan önbellek dosyaları (~/.zcompdump*)
#   userdata  kullanımla oluşan veri (geçmiş, ayar); silinmez, arşive taşınır
# ============================================================================

# Asla silinmeyecek yollar (hatalı bir kayda karşı son savunma hattı)
fs_is_protected() {
    local p="${1%/}"
    case "$p" in
        ""|"/"|"$HOME"|"$HOME/.config"|"$HOME/.local"|"$HOME/.local/share" \
            |"$HOME/.cache"|"$HOME/.local/state"|/usr|/usr/*|/etc|/etc/*|/bin|/bin/*)
            return 0 ;;
    esac
    [[ "$p" != "$HOME"/* && "$p" != "${TMPDIR:-/tmp}"/* ]]
}

# Oluşturulacak yolu bildir: yoksa deftere yazar
act_path() {
    [[ -e "$1" || -L "$1" ]] && return 0
    ledger_add path "$1"
}

# Henüz var olmayan üst dizinleri "dir" olarak kaydet (en üstteki önce).
# Araçlar ~/.cache gibi dizinleri sonradan oluşturduğunda boş kalırlarsa
# kaldırmada silinirler.
_fs_record_missing_parents() {
    local p created=()
    p="$(dirname "$1")"
    while [[ ! -d "$p" && "$p" == "$HOME"/* ]]; do
        created=("$p" "${created[@]}")
        p="$(dirname "$p")"
    done
    for p in "${created[@]}"; do
        ledger_add dir "$p"
    done
}

# Kullanımla oluşacak veriyi bildir (şu an yoksa)
act_userdata() {
    [[ -e "$1" ]] && return 0
    _fs_record_missing_parents "$1"
    ledger_add userdata "$1"
}

# Kalıba uyan dosya şu an yoksa kalıbı bildir: act_glob "$HOME/.zcompdump*"
act_glob() {
    local matches
    matches=$(compgen -G "$1" 2>/dev/null | head -1)
    [[ -n "$matches" ]] && return 0
    _fs_record_missing_parents "$1"
    ledger_add glob "$1"
}

# Dizin oluştur; oluşturulan her üst dizin "dir" olarak kaydedilir
act_mkdir() {
    local target="$1" p created=()
    [[ -d "$target" ]] && return 0
    p="$target"
    while [[ ! -d "$p" ]]; do
        created=("$p" "${created[@]}")
        p="$(dirname "$p")"
    done
    if is_dry_run; then
        log_plan "mkdir -p $(ts_pretty_path "$target")"
        return 0
    fi
    for p in "${created[@]}"; do
        ledger_add dir "$p"
    done
    mkdir -p "$target"
}

# Script'e ait bir dosyayı yaz (yoksa oluşturulur ve kaydedilir).
# Kullanıcıya ait mevcut bir dosyanın üzerine yazmak için act_rc_* kullanın.
#   act_write_file YOL İÇERİK [mod]
act_write_file() {
    local path="$1" content="$2" mode="${3:-644}"
    if [[ -e "$path" ]] && ! ledger_has path "$path"; then
        log_err "Dosya kullanıcıya ait, üzerine yazılmadı: $(ts_pretty_path "$path")"
        return 1
    fi
    if is_dry_run; then
        log_plan "yaz $(ts_pretty_path "$path")"
        return 0
    fi
    act_mkdir "$(dirname "$path")" || return 1
    act_path "$path"
    printf '%s\n' "$content" > "$path.ts-tmp" && chmod "$mode" "$path.ts-tmp" \
        && mv -f "$path.ts-tmp" "$path"
}

# İndirilen bir dosyayı yerleştir: act_download URL HEDEF
act_download() {
    local url="$1" dest="$2" tmp
    if [[ -e "$dest" ]] && ! ledger_has path "$dest"; then
        return 0
    fi
    if is_dry_run; then
        log_plan "indir $(ts_pretty_path "$dest")"
        return 0
    fi
    act_mkdir "$(dirname "$dest")" || return 1
    tmp="$TS_TMP/dl.$RANDOM"
    net_fetch "$url" "$tmp" || { log_err "İndirilemedi: $url"; return 1; }
    act_path "$dest"
    mv -f "$tmp" "$dest"
}

# Git deposunu klonla: act_clone URL HEDEF
act_clone() {
    local url="$1" dest="$2"
    [[ -d "$dest/.git" ]] && return 0
    if is_dry_run; then
        log_plan "git clone $url $(ts_pretty_path "$dest")"
        return 0
    fi
    act_mkdir "$(dirname "$dest")" || return 1
    act_path "$dest"
    run_logged git clone --depth 1 --quiet "$url" "$dest" || {
        log_err "Klonlanamadı: $url"
        return 1
    }
}

# Çalıştırılabilir dosyayı ~/.local/bin altına kur: act_install_bin KAYNAK AD
act_install_bin() {
    local src="$1" name="$2" dest="$TS_BIN_DIR/$2"
    if [[ -e "$dest" ]] && ! ledger_has path "$dest"; then
        log_err "$(ts_pretty_path "$dest") zaten var ve size ait; üzerine yazılmadı"
        return 1
    fi
    act_mkdir "$TS_BIN_DIR" || return 1
    act_path "$dest"
    install -m 755 "$src" "$dest"
}

# GitHub release'inden tek bir çalıştırılabilir dosya kur.
#   act_gh_binary owner/repo 'x86_64-deseni' 'aarch64-deseni' ikili [hedef-ad]
act_gh_binary() {
    local repo="$1" pat_x86="$2" pat_arm="$3" bin="$4" name="${5:-$4}"
    local arch pattern tag asset work file

    arch=$(sys_arch) || { log_err "Desteklenmeyen işlemci mimarisi: $(uname -m)"; return 1; }
    [[ "$arch" == "x86_64" ]] && pattern="$pat_x86" || pattern="$pat_arm"

    if is_dry_run; then
        log_plan "GitHub $repo -> $(ts_pretty_path "$TS_BIN_DIR/$name")"
        return 0
    fi

    tag=$(gh_latest_tag "$repo") || { log_err "$repo: son sürüm bulunamadı"; return 1; }
    asset=$(gh_find_asset "$repo" "$tag" "$pattern")
    [[ -n "$asset" ]] || { log_err "$repo $tag: $arch için dosya yok"; return 1; }

    work="$TS_TMP/gh.$RANDOM"
    mkdir -p "$work/x"
    log_step "$repo $tag indiriliyor ($asset)"
    gh_download "$repo" "$tag" "$asset" "$work/$asset" || { log_err "İndirilemedi: $asset"; return 1; }

    case "$asset" in
        *.tar.gz|*.tgz) tar -xzf "$work/$asset" -C "$work/x" || return 1 ;;
        *.zip)
            has_cmd unzip || { log_err "unzip bulunamadı"; return 1; }
            unzip -q "$work/$asset" -d "$work/x" || return 1
            ;;
        *) cp "$work/$asset" "$work/x/$bin" ;;
    esac

    file=$(find "$work/x" -type f -name "$bin" | head -1)
    [[ -n "$file" ]] || { log_err "$asset içinde '$bin' bulunamadı"; return 1; }
    act_install_bin "$file" "$name"
}

# Yazı tipi önbelleğini yenile (yazı tipi eklendiğinde/silindiğinde)
act_font_cache() {
    has_cmd fc-cache || return 0
    is_dry_run && { log_plan "fc-cache"; return 0; }
    run_logged fc-cache -f "$TS_FONT_DIR" || true
}

# ----------------------------------------------------------------------------
# Geri alma işleyicileri (lib/undo.sh dağıtır)
# ----------------------------------------------------------------------------
FS_FONTS_CHANGED=0
UNDO_ARCHIVED=()   # arşive taşınan/kopyalanan yollar (rapor için)

# Arşiv dizinini ilk ihtiyaçta belirle ve oluştur. Alt kabukta ($(...))
# çağrılmamalıdır; TS_ARCHIVE_DIR'i ana kabukta ayarlar.
undo_archive_init() {
    if [[ -z "$TS_ARCHIVE_DIR" ]]; then
        TS_ARCHIVE_DIR="$HOME/terminal-setup-kaldirilan-$(ts_stamp)"
    fi
    is_dry_run || mkdir -p "$TS_ARCHIVE_DIR"
}

# Bir yolu, $HOME'a göreli yapısını koruyarak arşive taşı ya da kopyala
fs_archive() {
    local src="$1" mode="$2" rel dest
    rel="${src#"$HOME"/}"
    if is_dry_run; then
        log_plan "arşive $mode: $(ts_pretty_path "$src")"
        return 0
    fi
    undo_archive_init
    dest="$TS_ARCHIVE_DIR/$rel"
    mkdir -p "$(dirname "$dest")"
    if [[ "$mode" == "taşı" ]]; then
        mv -- "$src" "$dest"
    else
        cp -a -- "$src" "$dest"
    fi
    UNDO_ARCHIVED+=("$(ts_pretty_path "$src")")
}

undo_path() {
    local p="$1"
    [[ -e "$p" || -L "$p" ]] || return 0
    if fs_is_protected "$p"; then
        log_err "Korunan yol silinmedi: $p"
        return 1
    fi
    [[ "$p" == "$TS_FONT_DIR"/* ]] && FS_FONTS_CHANGED=1
    is_dry_run && { log_plan "sil $(ts_pretty_path "$p")"; return 0; }
    rm -rf -- "$p"
}

undo_dir() {
    local d="$1"
    [[ -d "$d" ]] || return 0
    if [[ -n "$(ls -A "$d" 2>/dev/null)" ]]; then
        log_debug "Dizin boş değil, bırakıldı: $d"
        return 0
    fi
    is_dry_run && { log_plan "rmdir $(ts_pretty_path "$d")"; return 0; }
    rmdir -- "$d"
}

undo_glob() {
    local f
    while IFS= read -r f; do
        [[ -n "$f" ]] && { undo_path "$f" || return 1; }
    done < <(compgen -G "$1" 2>/dev/null)
    return 0
}

undo_userdata() {
    [[ -e "$1" ]] || return 0
    fs_archive "$1" "taşı"
}
