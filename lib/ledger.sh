#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Değişiklik defteri
# ============================================================================
# Script'in sistemde yaptığı her değişiklik buraya bir satır olarak yazılır.
# Kaldırma bu defteri sondan başa okuyup her satırı geri alır.
#
# Biçim (sekmeyle ayrılmış):  bileşen <TAB> tür <TAB> arg1 [<TAB> arg2]
# İlk satır sürüm başlığıdır; biçim değişirse eski defterler taşınabilir.
#
# Türler ve anlamları lib/undo.sh içinde belgelenmiştir.
# ============================================================================

LEDGER_HEADER="# terminal-setup ledger v1"

# Aynı (tür, arg1) için yalnızca ilk kaydın tutulduğu türler. İlk kayıt
# "kurulumdan önceki" değeri taşır; sonrakiler onu ezmemelidir.
# (rcblock bu listede değildir: bir dosyada farklı kimlikli birden çok blok
# olabilir; tekilliğini act_rc_block kendisi denetler.)
LEDGER_UNIQUE_TYPES=(pkg path glob userdata rcfile gitcfg dconf shell)
# (dir de listede değildir: aynı dizin birden çok bileşen için kaydedilebilir.)

ledger_init() {
    is_dry_run && return 0
    mkdir -p "$TS_STATE_DIR" || return 1
    log_persist
    if [[ ! -s "$TS_LEDGER" ]]; then
        printf '%s\n' "$LEDGER_HEADER" > "$TS_LEDGER"
        return 0
    fi
    local header
    header=$(head -1 "$TS_LEDGER")
    if [[ "$header" != "$LEDGER_HEADER" ]]; then
        log_err "Defter sürümü tanınmıyor: $header"
        return 1
    fi
}

ledger_exists() { [[ -s "$TS_LEDGER" ]]; }

# Değeri sekme/yeni satır içermeyecek biçimde kodla
ledger_encode() { printf '%s' "$1" | base64 -w0; }
ledger_decode() { printf '%s' "$1" | base64 -d 2>/dev/null; }

# Tüm kayıt satırları (başlık ve yorumlar hariç); isteğe bağlı bileşen süzgeci
ledger_lines() {
    local comp="${1:-}"
    [[ -f "$TS_LEDGER" ]] || return 0
    if [[ -n "$comp" ]]; then
        awk -F'\t' -v c="$comp" '!/^#/ && NF >= 3 && $1 == c' "$TS_LEDGER"
    else
        awk -F'\t' '!/^#/ && NF >= 3' "$TS_LEDGER"
    fi
}

# (tür, arg1) ile eşleşen ilk satır
ledger_find() {
    local type="$1" arg="$2"
    [[ -f "$TS_LEDGER" ]] || return 1
    awk -F'\t' -v t="$type" -v a="$arg" '!/^#/ && $2 == t && $3 == a { print; found=1; exit } END { exit !found }' "$TS_LEDGER"
}

ledger_has() { ledger_find "$1" "$2" >/dev/null; }

# Kayıt ekle: ledger_add tür arg1 [arg2]   (sahibi: TS_CURRENT_COMPONENT)
ledger_add() {
    local type="$1" a1="$2" a2="${3:-}"
    is_dry_run && return 0
    if in_list "$type" "${LEDGER_UNIQUE_TYPES[@]}" && ledger_has "$type" "$a1"; then
        return 0
    fi
    ledger_init || return 1
    if [[ -n "$a2" ]]; then
        printf '%s\t%s\t%s\t%s\n' "$TS_CURRENT_COMPONENT" "$type" "$a1" "$a2" >> "$TS_LEDGER"
    else
        printf '%s\t%s\t%s\n' "$TS_CURRENT_COMPONENT" "$type" "$a1" >> "$TS_LEDGER"
    fi
    log_debug "defter: $TS_CURRENT_COMPONENT $type $a1"
}

# Defterde kaydı olan bileşenler, ilk görülme sırasıyla
ledger_components() {
    ledger_lines | awk -F'\t' '!seen[$1]++ { print $1 }'
}

ledger_component_has_entries() {
    ledger_lines "$1" | grep -q .
}

# Tam olarak eşleşen ilk satırı defterden sil
ledger_remove_line() {
    local line="$1" tmp
    [[ -f "$TS_LEDGER" ]] || return 0
    tmp="$TS_LEDGER.tmp"
    awk -v l="$line" '!done && $0 == l { done=1; next } { print }' "$TS_LEDGER" > "$tmp" \
        && mv "$tmp" "$TS_LEDGER"
}

# Bir dosyaya ait rcblock kaydı kalmış mı?
ledger_file_has_blocks() {
    local file="$1"
    ledger_lines | awk -F'\t' -v f="$file" '$2 == "rcblock" && $3 == f { found=1 } END { exit !found }'
}

# Kayıt sayısı
ledger_count() { ledger_lines | wc -l; }
