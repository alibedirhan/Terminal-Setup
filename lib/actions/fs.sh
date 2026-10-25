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
        log_plan "mkdir -p %s" "$(ts_pretty_path "$target")"
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
        log_err "Dosya kullanıcıya ait, üzerine yazılmadı: %s" "$(ts_pretty_path "$path")"
        return 1
    fi
    if is_dry_run; then
        log_plan "yaz %s" "$(ts_pretty_path "$path")"
        return 0
    fi
    act_mkdir "$(dirname "$path")" || return 1
    act_path "$path"
    printf '%s\n' "$content" > "$path.ts-tmp" && chmod "$mode" "$path.ts-tmp" \
        && mv -f "$path.ts-tmp" "$path"
}

# Kullanıcının sonradan değiştireceği bir ayar dosyasını yalnızca yoksa
# oluştur. Kullanıcı verisi sayılır: üzerine yazılmaz, kaldırırken silinmez,
# arşive taşınır. act_seed_file YOL İÇERİK
act_seed_file() {
    local path="$1" content="$2"
    [[ -e "$path" ]] && return 0
    if is_dry_run; then
        log_plan "yaz %s" "$(ts_pretty_path "$path")"
        return 0
    fi
    act_mkdir "$(dirname "$path")" || return 1
    act_userdata "$path"
    printf '%s\n' "$content" > "$path"
}

# İndirilen bir dosyayı yerleştir: act_download URL HEDEF
act_download() {
    local url="$1" dest="$2" tmp
    if [[ -e "$dest" ]] && ! ledger_has path "$dest"; then
        return 0
    fi
    if is_dry_run; then
        log_plan "indir %s" "$(ts_pretty_path "$dest")"
        return 0
    fi
    act_mkdir "$(dirname "$dest")" || return 1
    tmp="$TS_TMP/dl.$RANDOM"
    net_fetch "$url" "$tmp" || { log_err "İndirilemedi: %s" "$url"; return 1; }
    act_path "$dest"
    mv -f "$tmp" "$dest"
}

# Git deposunu klonla: act_clone URL HEDEF
act_clone() {
    local url="$1" dest="$2"
    _act_recipe git "$url" "$dest"
    [[ -d "$dest/.git" ]] && return 0
    if is_dry_run; then
        log_plan "git clone %s %s" "$url" "$(ts_pretty_path "$dest")"
        return 0
    fi
    act_mkdir "$(dirname "$dest")" || return 1
    act_path "$dest"
    run_logged git clone --depth 1 --quiet "$url" "$dest" || {
        log_err "Klonlanamadı: %s" "$url"
        return 1
    }
}

# Çalıştırılabilir dosyayı ~/.local/bin altına kur: act_install_bin KAYNAK AD
act_install_bin() {
    local src="$1" name="$2" dest="$TS_BIN_DIR/$2"
    if [[ -e "$dest" ]] && ! ledger_has path "$dest"; then
        log_err "%s zaten var ve size ait; üzerine yazılmadı" "$(ts_pretty_path "$dest")"
        return 1
    fi
    act_mkdir "$TS_BIN_DIR" || return 1
    act_path "$dest"
    install -m 755 "$src" "$dest"
}

# GitHub release'inden tek bir çalıştırılabilir dosya kur. Kurulan sürüm
# ~/.terminal-setup/versions'a yazılır (güncelleme karşılaştırması için).
#   act_gh_binary owner/repo 'x86_64-deseni' 'aarch64-deseni' ikili [hedef-ad]
act_gh_binary() {
    local repo="$1" pat_x86="$2" pat_arm="$3" bin="$4" name="${5:-$4}" tag
    _act_recipe gh "$repo" "$pat_x86" "$pat_arm" "$bin" "$name"

    if is_dry_run; then
        log_plan "GitHub %s -> %s" "$repo" "$(ts_pretty_path "$TS_BIN_DIR/$name")"
        return 0
    fi

    tag=$(gh_latest_tag "$repo") || { log_err "%s: son sürüm bulunamadı" "$repo"; return 1; }
    _gh_fetch_bin "$repo" "$tag" "$pat_x86" "$pat_arm" "$bin" || return 1
    act_install_bin "$REPLY" "$name" || return 1
    tool_version_set "$name" "$tag"
}

# Release dosyasını indirip içinden ikiliyi çıkar; yolu REPLY'ye yazar.
#   _gh_fetch_bin owner/repo etiket 'x86_64-deseni' 'aarch64-deseni' ikili
_gh_fetch_bin() {
    local repo="$1" tag="$2" pat_x86="$3" pat_arm="$4" bin="$5"
    local arch pattern asset work file
    REPLY=""

    arch=$(sys_arch) || { log_err "Desteklenmeyen işlemci mimarisi: %s" "$(uname -m)"; return 1; }
    [[ "$arch" == "x86_64" ]] && pattern="$pat_x86" || pattern="$pat_arm"
    asset=$(gh_find_asset "$repo" "$tag" "$pattern")
    [[ -n "$asset" ]] || { log_err "%s %s: %s için dosya yok" "$repo" "$tag" "$arch"; return 1; }

    work="$TS_TMP/gh.$RANDOM"
    mkdir -p "$work/x"
    log_step "%s %s indiriliyor (%s)" "$repo" "$tag" "$asset"
    gh_download "$repo" "$tag" "$asset" "$work/$asset" || { log_err "İndirilemedi: %s" "$asset"; return 1; }

    case "$asset" in
        *.tar.gz|*.tgz) tar -xzf "$work/$asset" -C "$work/x" || return 1 ;;
        *.zip)
            has_cmd unzip || { log_err "unzip bulunamadı"; return 1; }
            unzip -q "$work/$asset" -d "$work/x" || return 1
            ;;
        *) cp "$work/$asset" "$work/x/$bin" ;;
    esac

    file=$(find "$work/x" -type f -name "$bin" | head -1)
    [[ -n "$file" ]] || { log_err "%s içinde '%s' bulunamadı" "$asset" "$bin"; return 1; }
    REPLY="$file"
}

# GitHub release arşivinden seçilen dosyaları script'e ait bir dizine çıkar.
# Dizin varsa (önceden kurulmuş ya da kullanıcının) dokunulmaz.
#   act_gh_extract owner/repo 'dosya-deseni' HEDEF-DİZİN 'glob'...
act_gh_extract() {
    local repo="$1" pattern="$2" dest="$3" tag asset work f n=0
    shift 3
    [[ -d "$dest" ]] && return 0
    if is_dry_run; then
        log_plan "GitHub %s -> %s" "$repo" "$(ts_pretty_path "$dest")"
        return 0
    fi
    tag=$(gh_latest_tag "$repo") || { log_err "%s: son sürüm bulunamadı" "$repo"; return 1; }
    asset=$(gh_find_asset "$repo" "$tag" "$pattern")
    [[ -n "$asset" ]] || { log_err "%s %s: %s için dosya yok" "$repo" "$tag" "$pattern"; return 1; }
    work="$TS_TMP/gh.$RANDOM"
    mkdir -p "$work/x"
    log_step "%s %s indiriliyor (%s)" "$repo" "$tag" "$asset"
    gh_download "$repo" "$tag" "$asset" "$work/$asset" || { log_err "İndirilemedi: %s" "$asset"; return 1; }
    case "$asset" in
        *.tar.xz) tar -xJf "$work/$asset" -C "$work/x" || return 1 ;;
        *.tar.gz|*.tgz) tar -xzf "$work/$asset" -C "$work/x" || return 1 ;;
        *) log_err "%s içinde '%s' bulunamadı" "$asset" "$*"; return 1 ;;
    esac
    act_mkdir "$(dirname "$dest")" || return 1
    act_path "$dest"
    mkdir -p "$dest"
    for pattern in "$@"; do
        while IFS= read -r f; do
            cp "$f" "$dest/" && n=$((n + 1))
        done < <(find "$work/x" -type f -name "$pattern")
    done
    ((n > 0)) || { log_err "%s içinde '%s' bulunamadı" "$asset" "$*"; return 1; }
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
        if [[ "$mode" == "taşı" ]]; then
            log_plan "arşive taşı: %s" "$(ts_pretty_path "$src")"
        else
            log_plan "arşive kopyala: %s" "$(ts_pretty_path "$src")"
        fi
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
        log_err "Korunan yol silinmedi: %s" "$p"
        return 1
    fi
    [[ "$p" == "$TS_FONT_DIR"/* ]] && FS_FONTS_CHANGED=1
    is_dry_run && { log_plan "sil %s" "$(ts_pretty_path "$p")"; return 0; }
    rm -rf -- "$p"
}

undo_dir() {
    local d="$1"
    [[ -d "$d" ]] || return 0
    if [[ -n "$(ls -A "$d" 2>/dev/null)" ]]; then
        log_debug "Dizin boş değil, bırakıldı: $d"
        return 0
    fi
    is_dry_run && { log_plan "rmdir %s" "$(ts_pretty_path "$d")"; return 0; }
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
