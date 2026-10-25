#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Başlangıç fotoğrafıyla karşılaştırma
# ============================================================================
# "Kalıntı bırakmadı" iddiasını kanıta dayandırır. Sistemin şu anki hali
# başlangıç fotoğrafıyla karşılaştırılır:
#
#   Hata    defterde geri alınamamış kayıt, ayar farkı (kabuk, git, terminal),
#           kurulumdan önce var olup artık olmayan paket ya da dosya
#   Bilgi   kurulumdan sonra eklenmiş paket ya da dosya (kullanıcının
#           kendisinin eklediği şeyler olabilir; --strict ile hata sayılır)
# ============================================================================

VERIFY_ERRORS=0
VERIFY_NOTES=0

# Rapor satırları çevrilir: _verify_ok "Biçim %s" ARG...
_verify_ok()   { _t "$@"; printf '  %s %s\n' "${C_GREEN}✓${C_RESET}" "$TR"; }
_verify_err()  { _t "$@"; printf '  %s %s\n' "${C_RED}✗${C_RESET}" "$TR"; VERIFY_ERRORS=$((VERIFY_ERRORS + 1)); }
_verify_note() { _t "$@"; printf '  %s %s\n' "${U_INFO:-$C_YELLOW}•${C_RESET}" "$TR"; VERIFY_NOTES=$((VERIFY_NOTES + 1)); }

_verify_list() {
    local max=12 n=0 item
    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        n=$((n + 1))
        ((n <= max)) && printf '      %s\n' "$(ts_pretty_path "$item")"
    done
    if ((n > max)); then
        _t "... ve %s tane daha" "$((n - max))"
        printf '      %s\n' "$TR"
    fi
    return 0
}

# Karşılaştır: verify_against_baseline [--strict]
verify_against_baseline() {
    local strict=0 now base="$TS_BASELINE_DIR" diff_out
    [[ "${1:-}" == "--strict" ]] && strict=1
    VERIFY_ERRORS=0
    VERIFY_NOTES=0

    if ! baseline_exists; then
        log_err "Başlangıç fotoğrafı yok; karşılaştırma yapılamaz."
        return 1
    fi
    now="$TS_TMP/verify-now"
    baseline_capture_to "$now"

    _t "Başlangıç fotoğrafıyla karşılaştırma"
    printf '%s\n' "${C_BOLD}${TR}${C_RESET} ($(baseline_created_at))"

    # 1. Defter
    if (( $(ledger_count) == 0 )); then
        _verify_ok "Defterde geri alınmamış kayıt yok"
    else
        _verify_err "Defterde %s kayıt duruyor (kalıntı):" "$(ledger_count)"
        ledger_lines | awk -F'\t' '{ print $1 ": " $2 " " $3 }' | _verify_list
    fi

    # 2. Ayarlar: kabuk, git, terminal profilleri
    local -A labels=(
        [shell.txt]="Giriş kabuğu"
        [gitconfig.txt]="Git genel ayarları"
        [dconf-gnome-terminal.txt]="GNOME Terminal profili"
        [dconf-ptyxis.txt]="Ptyxis ayarları"
    )
    local f
    for f in shell.txt gitconfig.txt dconf-gnome-terminal.txt dconf-ptyxis.txt; do
        if cmp -s "$base/$f" "$now/$f"; then
            _t "${labels[$f]}"
            _verify_ok "%s kurulum öncesiyle aynı" "$TR"
        else
            _t "${labels[$f]}"
            _verify_err "%s farklı:" "$TR"
            diff "$base/$f" "$now/$f" | grep -E '^[<>]' | head -8 | sed 's/^/      /'
        fi
    done

    # 3. Paketler
    diff_out=$(comm -23 "$base/packages.txt" "$now/packages.txt")
    if [[ -n "$diff_out" ]]; then
        _verify_err "Kurulumdan önce kurulu olup artık olmayan paketler:"
        _verify_list <<< "$diff_out"
    else
        _verify_ok "Önceden kurulu paketlerin hepsi yerinde"
    fi
    diff_out=$(comm -13 "$base/packages.txt" "$now/packages.txt")
    if [[ -n "$diff_out" ]]; then
        if ((strict)); then _verify_err "Fotoğraftan sonra eklenen paketler:"; else
            _verify_note "Fotoğraftan sonra eklenen paketler (sizin kurduklarınız olabilir):"; fi
        _verify_list <<< "$diff_out"
    else
        _verify_ok "Fazladan paket yok"
    fi

    # 4. Dosyalar (izlenen konumlar)
    diff_out=$(comm -23 "$base/paths.txt" "$now/paths.txt")
    if [[ -n "$diff_out" ]]; then
        _verify_err "Kurulumdan önce var olup artık olmayan dosyalar:"
        _verify_list <<< "$diff_out"
    else
        _verify_ok "Önceden var olan dosyaların hepsi yerinde"
    fi
    diff_out=$(comm -13 "$base/paths.txt" "$now/paths.txt")
    if [[ -n "$diff_out" ]]; then
        if ((strict)); then _verify_err "Fotoğraftan sonra oluşan dosyalar:"; else
            _verify_note "Fotoğraftan sonra oluşan dosyalar (sizin oluşturduklarınız olabilir):"; fi
        _verify_list <<< "$diff_out"
    else
        _verify_ok "Fazladan dosya yok"
    fi

    printf '\n'
    if ((VERIFY_ERRORS == 0)); then
        _t "Sonuç: kalıntı yok."
        printf '%s\n' "${C_GREEN}${C_BOLD}${TR}${C_RESET}"
        return 0
    fi
    _t "Sonuç: %s fark bulundu." "$VERIFY_ERRORS"
    printf '%s\n' "${C_RED}${C_BOLD}${TR}${C_RESET}"
    return 1
}
