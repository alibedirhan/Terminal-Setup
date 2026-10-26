#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Geri alma dağıtıcısı
# ============================================================================
# Defter kayıtları sondan başa okunur ve her tür kendi işleyicisine
# (lib/actions/* içindeki undo_<tür>) gönderilir. Bu dosya sisteme kendisi
# dokunmaz. Başarıyla geri alınan her kayıt defterden silinir; yarıda kesilen
# bir kaldırma kaldığı yerden devam edebilir. Paketler en sonda, tek seferde
# ve güvenlik simülasyonuyla silinir.
#
#   Tür       İşleyici       Geri alma
#   pkg       pkg_purge_owned  apt-get purge (simülasyonla)
#   path      undo_path      rm -rf
#   dir       undo_dir       boşsa rmdir
#   glob      undo_glob      kalıba uyan dosyaları sil
#   userdata  undo_userdata  arşive taşı
#   rcblock   undo_rcblock   bloğu dosyadan çıkar
#   rcfile    undo_rcfile    orijinali geri koy (son blok kalktığında)
#   gitcfg    undo_gitcfg    önceki değere dön ya da sil
#   dconf     undo_dconf     önceki değere dön ya da sıfırla
#   shell     undo_shell     giriş kabuğunu geri al
#   note      —              bilgi amaçlı
# ============================================================================

UNDO_FAILED=0

_undo_one() {
    local type="$1" a1="$2" a2="$3"
    [[ "$type" == "note" ]] && return 0
    if ! declare -F "undo_$type" >/dev/null; then
        log_warn "Bilinmeyen defter kaydı: %s" "$type"
        return 1
    fi
    "undo_$type" "$a1" "$a2"
}

# Kayıt satırlarını (stdin) sondan başa geri al
undo_lines() {
    local -a lines=() pkgs=() pkg_lines=()
    local line i comp type a1 a2
    mapfile -t lines
    for ((i = ${#lines[@]} - 1; i >= 0; i--)); do
        line="${lines[i]}"
        IFS=$'\t' read -r comp type a1 a2 <<< "$line"
        # Yazı tipi dosyaları bitince önbelleği hemen yenile; böylece önbellek
        # dizinini silen kayıt (glob) bundan SONRA işlenir ve kalıntı kalmaz.
        if ((FS_FONTS_CHANGED)) && ! [[ "$type" == "path" && "$a1" == "$TS_FONT_DIR"/* ]]; then
            _undo_flush_font_cache
        fi
        if [[ "$type" == "pkg" ]]; then
            pkgs+=("$a1")
            pkg_lines+=("$line")
            continue
        fi
        if _undo_one "$type" "$a1" "$a2"; then
            is_dry_run || ledger_remove_line "$line"
            # Başka bileşenlerin dosyalarını içerdiği için silinemeyen ortak
            # dizin "core"a devredilir; tam kaldırmada yeniden denenir.
            if [[ "$type" == "dir" && "$comp" != "core" && -d "$a1" ]] && ! is_dry_run; then
                printf 'core\tdir\t%s\n' "$a1" >> "$TS_LEDGER"
            fi
        else
            UNDO_FAILED=$((UNDO_FAILED + 1))
        fi
    done
    ((FS_FONTS_CHANGED)) && _undo_flush_font_cache
    ((${#pkgs[@]} == 0)) && return 0

    pkg_purge_owned "${pkgs[@]}" || UNDO_FAILED=$((UNDO_FAILED + 1))
    is_dry_run && return 0
    for line in "${pkg_lines[@]}"; do
        IFS=$'\t' read -r comp type a1 a2 <<< "$line"
        pkg_installed "$a1" || ledger_remove_line "$line"
    done
}

# Yazı tipi dizini hâlâ yazı tipi içeriyorsa önbelleği yenile
_undo_flush_font_cache() {
    FS_FONTS_CHANGED=0
    compgen -G "$TS_FONT_DIR/*" >/dev/null || return 0
    act_font_cache
}

# Bir dosyaya hâlâ bağlı kayıt var mı? (blok ya da .gitconfig için git ayarı)
_undo_file_referenced() {
    local file="$1"
    ledger_file_has_blocks "$file" && return 0
    [[ "$file" == "$TS_GITCONFIG" ]] && ledger_lines | awk -F'\t' '$2 == "gitcfg" { f=1 } END { exit !f }'
}

# Hiçbir kaydın bağlı kalmadığı dosyaları orijinal haline döndür
undo_rcfile_gc() {
    local line comp type file saved
    while IFS= read -r line; do
        IFS=$'\t' read -r comp type file saved <<< "$line"
        if ! is_dry_run && _undo_file_referenced "$file"; then
            continue
        fi
        if undo_rcfile "$file" "$saved"; then
            is_dry_run || ledger_remove_line "$line"
        else
            UNDO_FAILED=$((UNDO_FAILED + 1))
        fi
    done < <(ledger_lines | awk -F'\t' '$2 == "rcfile"')
}

# Bir bileşenin tüm kayıtlarını geri al
undo_component() {
    UNDO_FAILED=0
    # Alt kabuk, hata sayısını ve arşiv bilgilerini çağırandan gizlememeli.
    undo_lines < <(ledger_lines "$1")
    is_dry_run || undo_rcfile_gc
    ((UNDO_FAILED == 0))
}
