#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Bileşen çalıştırıcı
# ============================================================================
# Bileşenler components/ altında kendini kaydeder:
#
#   component_register bat "Bat" tools "Renkli cat" ""
#   comp_bat_install() { act_pkg bat; ... }
#   comp_bat_verify()  { has_cmd batcat; }
#
# Kaldırma fonksiyonu yazılmaz: bileşenin tüm eylemleri deftere düştüğü
# için geri alma geneldir (lib/undo.sh). Kurulum yarıda kalırsa o bileşenin
# kayıtları hemen geri alınır; sistem yarım bırakılmaz.
# ============================================================================

declare -ga COMP_IDS=()
declare -gA COMP_NAME=() COMP_CAT=() COMP_DESC=() COMP_DEPS=()

COMP_CATEGORIES=(shell tools extra)
declare -gA COMP_CAT_LABEL=([shell]="Kabuk" [tools]="Araçlar" [extra]="Ekstra")

# component_register kimlik "Ad" kategori "Açıklama" "bağımlılık ..."
component_register() {
    local id="$1"
    COMP_IDS+=("$id")
    COMP_NAME[$id]="$2"
    COMP_CAT[$id]="$3"
    COMP_DESC[$id]="$4"
    COMP_DEPS[$id]="${5:-}"
}

component_exists() { [[ -n "${COMP_NAME[$1]:-}" ]]; }

# Bileşenin (çevrilmiş) görünen adı: comp_label ID
comp_label() {
    _t "${COMP_NAME[$1]:-$1}"
    printf '%s' "$TR"
}

# Görüntüleme ve kurulum sırası: profiles/full.profile'daki sıra esas alınır
# (dosyalar alfabetik yüklendiği için), profilde olmayanlar sona eklenir.
component_sort() {
    local sorted=() id
    while IFS= read -r id; do
        component_exists "$id" && ! in_list "$id" "${sorted[@]}" && sorted+=("$id")
    done < <(grep -vE '^[[:space:]]*(#|$)' "$TS_ROOT/profiles/full.profile" 2>/dev/null)
    for id in "${COMP_IDS[@]}"; do
        in_list "$id" "${sorted[@]}" || sorted+=("$id")
    done
    COMP_IDS=("${sorted[@]}")
}

_comp_fn() { echo "comp_${1//-/_}_$2"; }

component_verify() {
    local fn
    fn=$(_comp_fn "$1" verify)
    declare -F "$fn" >/dev/null || return 1
    "$fn" >/dev/null 2>&1
}

# Durum: ours (script kurdu) | broken (kaydı var, çalışmıyor)
#        external (script kurmadı ama sistemde var) | absent
component_state() {
    local id="$1" has_entries=0
    ledger_lines "$id" | awk -F'\t' '$2 != "note"' | grep -q . && has_entries=1
    if component_verify "$id"; then
        ((has_entries)) && echo ours || echo external
    else
        ((has_entries)) && echo broken || echo absent
    fi
}

component_ids_by_cat() {
    local cat="$1" id
    for id in "${COMP_IDS[@]}"; do
        [[ "${COMP_CAT[$id]}" == "$cat" ]] && echo "$id"
    done
}

# Bağımlılıkları önce gelecek şekilde sırala
_RESOLVED=()
_resolve_visit() {
    local id="$1" dep
    in_list "$id" "${_RESOLVED[@]}" && return 0
    component_exists "$id" || { log_err "Bilinmeyen bileşen: %s" "$id"; return 1; }
    for dep in ${COMP_DEPS[$id]}; do
        _resolve_visit "$dep" || return 1
    done
    _RESOLVED+=("$id")
}

resolve_components() {
    local id
    _RESOLVED=()
    for id in "$@"; do
        _resolve_visit "$id" || return 1
    done
    printf '%s\n' "${_RESOLVED[@]}"
}

# ----------------------------------------------------------------------------
# Profiller: profiles/<ad>.profile, satır başına bir bileşen
# ----------------------------------------------------------------------------
profile_list() {
    local f
    for f in "$TS_ROOT"/profiles/*.profile; do
        [[ -f "$f" ]] && basename "$f" .profile
    done
}

profile_description() {
    sed -n 's/^# *Açıklama: *//p' "$TS_ROOT/profiles/$1.profile" 2>/dev/null | head -1
}

profile_components() {
    local f="$TS_ROOT/profiles/$1.profile"
    [[ -f "$f" ]] || { log_err "Profil bulunamadı: %s" "$1"; return 1; }
    grep -vE '^[[:space:]]*(#|$)' "$f" | awk '{ print $1 }'
}

# ----------------------------------------------------------------------------
# Kurulum
# ----------------------------------------------------------------------------

# Her kurulumdan önce: ortam kontrolü, fotoğraf, temel araçlar
runner_prepare() {
    if [[ $EUID -eq 0 ]]; then
        log_err "Bu aracı root olarak değil, normal kullanıcıyla çalıştırın."
        return 1
    fi
    if ! sys_is_supported; then
        log_warn "Desteklenmeyen sistem: %s. Desteklenen: Ubuntu 22.04, 24.04, 26.04." "$(sys_os)"
        ui_confirm "Yine de devam edilsin mi?" h || return 1
    fi
    if ! is_dry_run && ! net_online; then
        log_err "İnternet bağlantısı yok (github.com erişilemiyor)."
        return 1
    fi
    baseline_take || return 1
    ledger_init || return 1

    TS_CURRENT_COMPONENT="core"
    act_pkg curl git ca-certificates || return 1
    # Script'in kendi ayar dizini tamamen ona aittir
    if [[ ! -d "$TS_CONFIG_DIR" ]]; then
        act_mkdir "$(dirname "$TS_CONFIG_DIR")" || return 1
        act_path "$TS_CONFIG_DIR"
        is_dry_run || mkdir -p "$TS_CONFIG_DIR"
    fi
}

# Yalnızca ayar değiştiren işlemler (tema) için hafif hazırlık
runner_prepare_light() {
    if [[ $EUID -eq 0 ]]; then
        log_err "Bu aracı root olarak değil, normal kullanıcıyla çalıştırın."
        return 1
    fi
    baseline_take && ledger_init
}

RUN_INSTALLED=() RUN_SKIPPED=() RUN_FAILED=()

# Kurulum ya da kaldırmadan sonra çağrılacak fonksiyonlar (üst katmanlar
# kendini ekler; çalıştırıcı onları tanımaz): RUNNER_AFTER_CHANGE+=(fn)
RUNNER_AFTER_CHANGE=()

_runner_after_change() {
    local fn
    is_dry_run && return 0
    for fn in "${RUNNER_AFTER_CHANGE[@]}"; do "$fn" || true; done
}

# Tek bileşeni kur; başarısızsa kayıtlarını geri al
runner_install_one() {
    local id="$1" state fn
    state=$(component_state "$id")
    case "$state" in
        ours)
            log_ok "%s zaten kurulu" "$(comp_label "$id")"
            RUN_SKIPPED+=("$id")
            return 0 ;;
        external)
            log_info "%s sistemde zaten var (size ait); dokunulmayacak" "$(comp_label "$id")"
            TS_CURRENT_COMPONENT="$id"
            ledger_has note "external:$id" || ledger_add note "external:$id"
            RUN_SKIPPED+=("$id")
            return 0 ;;
    esac

    fn=$(_comp_fn "$id" install)
    log_step "%s kuruluyor" "${C_BOLD}$(comp_label "$id")${C_RESET}"
    TS_CURRENT_COMPONENT="$id"
    if "$fn" && { is_dry_run || component_verify "$id"; }; then
        is_dry_run || log_ok "%s kuruldu" "$(comp_label "$id")"
        RUN_INSTALLED+=("$id")
        TS_CURRENT_COMPONENT="core"
        return 0
    fi
    TS_CURRENT_COMPONENT="core"
    log_err "%s kurulamadı; yaptığı değişiklikler geri alınıyor" "$(comp_label "$id")"
    is_dry_run || undo_component "$id"
    RUN_FAILED+=("$id")
    return 1
}

# Bileşen listesini (bağımlılıklarıyla) kur
runner_install() {
    local ids id
    RUN_INSTALLED=() RUN_SKIPPED=() RUN_FAILED=()
    ids=$(resolve_components "$@") || return 1
    runner_prepare || return 1
    for id in $ids; do
        runner_install_one "$id" || true
    done
    runner_summary
    _runner_after_change
    ((${#RUN_FAILED[@]} == 0))
}

runner_summary() {
    printf '\n'
    ui_rule
    if is_dry_run; then
        ((${#RUN_INSTALLED[@]})) && log_info "Kurulacak: %s" "${RUN_INSTALLED[*]}"
    else
        ((${#RUN_INSTALLED[@]})) && log_ok "Kurulan: %s" "${RUN_INSTALLED[*]}"
    fi
    ((${#RUN_SKIPPED[@]})) && log_info "Atlanan (zaten var): %s" "${RUN_SKIPPED[*]}"
    ((${#RUN_FAILED[@]})) && log_err "Kurulamayan: %s (ayrıntı: %s)" "${RUN_FAILED[*]}" "$TS_LOG_FILE"
    return 0
}

# ----------------------------------------------------------------------------
# Kaldırma
# ----------------------------------------------------------------------------

# Bir bileşeni kaldır. Başka bir bileşen ona bağlıysa reddeder.
runner_remove_component() {
    local id="$1" other
    local -a deps
    for other in $(ledger_components); do
        [[ "$other" == "$id" ]] && continue
        component_exists "$other" || continue
        read -ra deps <<< "${COMP_DEPS[$other]}"
        if in_list "$id" "${deps[@]}"; then
            log_err "%s kaldırılamaz: %s ona bağlı" "$(comp_label "$id")" "$(comp_label "$other")"
            return 1
        fi
    done
    log_step "%s kaldırılıyor" "$(comp_label "$id")"
    UNDO_FAILED=0
    undo_component "$id"
    _runner_after_change
    ((UNDO_FAILED == 0))
}
