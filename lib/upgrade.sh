#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Kurulu araçları güncelleme (komut: update)
# ============================================================================
# Yalnızca script'in kurduğu bileşenler ("ours") güncellenir:
#   - GitHub'dan indirilen araçlar son release'e yükseltilir
#   - Oh My Zsh, Powerlevel10k ve eklenti depoları son commit'e getirilir
# apt ile kurulan paketler sistemin işidir (sudo apt upgrade). Kullanıcının
# kendi kurduğu araçlara dokunulmaz.
#
# Neyin güncelleneceği bileşen dosyalarından okunur: kurulum fonksiyonu
# prova modunda çalıştırılır ve act_gh_binary / act_clone tariflerini bırakır
# (lib/actions/upgrade.sh). Yeni bir araç eklemek güncellemeyi de getirir.
# ============================================================================

UPGRADE_DONE=() UPGRADE_CURRENT=() UPGRADE_FAILED=()

# Bileşenin güncellenebilir parçalarını ACT_RECIPES'e topla: upgrade_recipes ID
upgrade_recipes() {
    local id="$1" fn saved_dry="$TS_DRY_RUN" saved_comp="$TS_CURRENT_COMPONENT"
    ACT_RECIPES=()
    fn=$(_comp_fn "$id" install)
    declare -F "$fn" >/dev/null || return 0
    TS_DRY_RUN=1 ACT_RECIPE_CAPTURE=1 TS_CURRENT_COMPONENT="$id"
    "$fn" >/dev/null 2>&1
    TS_DRY_RUN="$saved_dry" ACT_RECIPE_CAPTURE=0 TS_CURRENT_COMPONENT="$saved_comp"
}

# Tek tarifi uygula ve sonucu yazdır: upgrade_apply "tür<TAB>alan..."
upgrade_apply() {
    local -a f
    local label
    IFS=$'\t' read -ra f <<< "$1"
    case "${f[0]}" in
        gh)
            label="${f[5]}"
            act_upgrade_gh "${f[1]}" "${f[2]}" "${f[3]}" "${f[4]}" "${f[5]}" ;;
        git)
            label=$(basename "${f[2]}")
            act_upgrade_git "${f[1]}" "${f[2]}" ;;
        *) return 0 ;;
    esac
    case "$UPG_RESULT" in
        updated)
            log_ok "$label: $UPG_FROM -> $UPG_TO"
            UPGRADE_DONE+=("$label") ;;
        planned)
            UPGRADE_DONE+=("$label") ;;
        current)
            log_info "$label güncel ($UPG_TO)"
            UPGRADE_CURRENT+=("$label") ;;
        skipped) ;;
        *)
            log_err "$label güncellenemedi"
            UPGRADE_FAILED+=("$label") ;;
    esac
}

# Güncellenecek bileşenler: verilenler ya da script'in kurduğu tümü
_upgrade_targets() {
    local id
    if (($#)); then
        for id in "$@"; do
            if ! component_exists "$id"; then
                log_err "Bilinmeyen bileşen: $id"
                return 1
            fi
        done
        printf '%s\n' "$@"
    else
        ledger_components
    fi
}

upgrade_run() {
    local ids id recipe
    UPGRADE_DONE=() UPGRADE_CURRENT=() UPGRADE_FAILED=()
    if [[ $EUID -eq 0 ]]; then
        log_err "Bu aracı root olarak değil, normal kullanıcıyla çalıştırın."
        return 1
    fi
    if ! ledger_exists; then
        log_info "Henüz Terminal Setup ile kurulmuş bir şey yok."
        return 0
    fi
    ids=$(_upgrade_targets "$@") || return 2
    if ! net_online; then
        log_err "İnternet bağlantısı yok (github.com erişilemiyor)."
        return 1
    fi

    log_step "Yeni sürümler denetleniyor"
    for id in $ids; do
        component_exists "$id" || continue
        if [[ "$(component_state "$id")" != ours ]]; then
            (($#)) && log_info "${COMP_NAME[$id]} Terminal Setup ile kurulmadı; güncellenmez"
            continue
        fi
        upgrade_recipes "$id"
        for recipe in "${ACT_RECIPES[@]}"; do
            upgrade_apply "$recipe"
        done
    done
    upgrade_summary
    ((${#UPGRADE_FAILED[@]} == 0))
}

upgrade_summary() {
    printf '\n'
    ui_rule
    if ((${#UPGRADE_DONE[@]})); then
        if is_dry_run; then
            log_info "Güncellenecek: ${UPGRADE_DONE[*]}"
        else
            log_ok "Güncellenen: ${UPGRADE_DONE[*]}"
        fi
    elif ((${#UPGRADE_FAILED[@]} == 0)); then
        log_ok "Her şey güncel."
    fi
    ((${#UPGRADE_FAILED[@]})) && log_err "Güncellenemeyen: ${UPGRADE_FAILED[*]} (ayrıntı: $TS_LOG_FILE)"
    log_info "apt ile kurulan paketler sistemle birlikte güncellenir (Yazılım Güncelleyici ya da 'sudo apt upgrade')."
    return 0
}
