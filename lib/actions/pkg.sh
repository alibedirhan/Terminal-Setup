#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Eylem: apt paketleri
# ============================================================================
# act_pkg yalnızca eksik paketleri kurar. Kurulumdan önce ve sonra paket
# listesinin farkı alınır; bağımlılıklar dahil, script'in getirdiği her
# paket deftere yazılır. Önceden kurulu paketler asla kaydedilmez.
#
# Kaldırırken (pkg_purge_owned) önce simülasyon yapılır: bir paketi silmek
# deftere ait olmayan bir paketi de götürecekse o paket atlanır.
# ============================================================================

PKG_APT_UPDATED=0
PKG_SKIPPED=()   # pkg_purge_owned: güvenlik nedeniyle atlanan paketler

APT_OPTS=(-y -q -o DPkg::Lock::Timeout=120)

pkg_installed() {
    dpkg-query -W -f='${db:Status-Abbrev}' "$1" 2>/dev/null | grep -q '^ii'
}

_pkg_apt() {
    run_logged as_root env DEBIAN_FRONTEND=noninteractive apt-get "${APT_OPTS[@]}" "$@"
}

pkg_update_once() {
    ((PKG_APT_UPDATED)) && return 0
    log_step "Paket listesi güncelleniyor"
    _pkg_apt update || { log_err "apt-get update başarısız (log: %s)" "$TS_LOG_FILE"; return 1; }
    PKG_APT_UPDATED=1
}

# Paketleri kur ve deftere yaz: act_pkg paket...
act_pkg() {
    local name missing=()
    for name in "$@"; do
        pkg_installed "$name" || missing+=("$name")
    done
    ((${#missing[@]} == 0)) && return 0

    if is_dry_run; then
        log_plan "apt-get install %s" "${missing[*]}"
        return 0
    fi

    sudo_begin || return 1
    pkg_update_once || return 1

    local before="$TS_TMP/pkgs-before" after="$TS_TMP/pkgs-after"
    baseline_list_packages > "$before"

    # Niyet önce yazılır: kurulum yarıda kesilse bile kaldırma bunları bilir.
    for name in "${missing[@]}"; do
        ledger_add pkg "$name"
    done

    log_step "apt: %s" "${missing[*]}"
    if ! _pkg_apt install --no-install-recommends "${missing[@]}"; then
        log_err "Paket kurulamadı: %s (log: %s)" "${missing[*]}" "$TS_LOG_FILE"
        return 1
    fi

    baseline_list_packages > "$after"
    while IFS= read -r name; do
        [[ -n "$name" ]] && ledger_add pkg "$name"
    done < <(comm -13 "$before" "$after")
}

# Simülasyonda kaldırılacak paket adları (mimari eki atılmış)
_pkg_simulate_purge() {
    LC_ALL=C apt-get -s purge "$@" 2>/dev/null \
        | awk '/^(Purg|Remv) / { sub(/:.*/, "", $2); print $2 }' | sort -u
}

# Deftere ait paketleri güvenli biçimde kaldır: pkg_purge_owned paket...
pkg_purge_owned() {
    local owned=("$@") installed=() safe=() name extra
    PKG_SKIPPED=()
    for name in "${owned[@]}"; do
        pkg_installed "$name" && installed+=("$name")
    done
    ((${#installed[@]} == 0)) && return 0

    local owned_file="$TS_TMP/pkgs-owned"
    printf '%s\n' "${owned[@]}" | sort -u > "$owned_file"

    extra=$(_pkg_simulate_purge "${installed[@]}" | comm -23 - "$owned_file")
    if [[ -z "$extra" ]]; then
        safe=("${installed[@]}")
    else
        # Toplu silme yabancı paket götürüyor; paketleri tek tek dene
        for name in "${installed[@]}"; do
            extra=$(_pkg_simulate_purge "$name" | comm -23 - "$owned_file")
            if [[ -z "$extra" ]]; then
                safe+=("$name")
            else
                PKG_SKIPPED+=("$name")
                log_warn "%s kaldırılmadı: şu paket(ler) ona bağlı: %s" "$name" "$(echo "$extra" | tr '\n' ' ')"
            fi
        done
    fi
    ((${#safe[@]} == 0)) && return 0

    if is_dry_run; then
        log_plan "apt-get purge %s" "${safe[*]}"
        return 0
    fi
    sudo_begin || return 1
    log_step "apt purge: %s paket" "${#safe[@]}"
    _pkg_apt purge "${safe[@]}" || { log_err "Paket kaldırma başarısız (log: %s)" "$TS_LOG_FILE"; return 1; }
}
