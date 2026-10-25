#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Eylem: kurulu araçları güncelleme
# ============================================================================
# GitHub'dan indirilen araçlar (~/.local/bin) ve klonlanan depolar (Oh My
# Zsh, Powerlevel10k, zsh eklentileri) yalnızca script onları kurduysa
# güncellenir. Güncelleme deftere satır yazmaz: bu yollar zaten script'e ait
# (path) kayıtlıdır ve kaldırma onları sürümden bağımsız olarak siler.
#
# Tarifler: lib/upgrade.sh bir bileşenin kurulum fonksiyonunu prova modunda
# ACT_RECIPE_CAPTURE=1 ile çalıştırır; act_gh_binary ve act_clone ne
# kurduklarını ACT_RECIPES dizisine yazar. Böylece her aracın deposu ve
# dosya deseni tek yerde, bileşen dosyasında kalır.
#
# Sonuç UPG_RESULT'a yazılır: updated | current | planned | skipped | failed
# (UPG_FROM ve UPG_TO eski ve yeni sürümü taşır).
# ============================================================================

ACT_RECIPE_CAPTURE=0
ACT_RECIPES=()
UPG_RESULT="" UPG_FROM="" UPG_TO=""

# Tarifi kaydet (yalnızca toplama sırasında): _act_recipe tür alan...
_act_recipe() {
    ((ACT_RECIPE_CAPTURE)) || return 0
    local IFS=$'\t'
    ACT_RECIPES+=("$*")
}

# GitHub aracını son sürüme yükselt:
#   act_upgrade_gh owner/repo 'x86_64-deseni' 'aarch64-deseni' ikili ad
act_upgrade_gh() {
    local repo="$1" pat_x86="$2" pat_arm="$3" bin="$4" name="$5"
    local dest="$TS_BIN_DIR/$5" current tag
    UPG_RESULT=failed UPG_FROM="" UPG_TO=""

    if ! ledger_has path "$dest"; then
        UPG_RESULT=skipped
        return 0
    fi
    current=$(tool_version_get "$name")
    _t "bilinmiyor"
    UPG_FROM="${current:-$TR}"
    tag=$(gh_latest_tag "$repo") || { log_err "%s: son sürüm bulunamadı" "$repo"; return 1; }
    UPG_TO="$tag"
    if [[ "$current" == "$tag" ]]; then
        UPG_RESULT=current
        return 0
    fi
    if is_dry_run; then
        log_plan "%s %s -> %s" "$name" "$UPG_FROM" "$tag"
        UPG_RESULT=planned
        return 0
    fi

    _gh_fetch_bin "$repo" "$tag" "$pat_x86" "$pat_arm" "$bin" || return 1
    # Çalışan bir ikilinin üzerine yazılamaz ("Text file busy"); yeni dosya
    # yanına kurulup yer değiştirilir.
    install -m 755 "$REPLY" "$dest.ts-tmp" && mv -f "$dest.ts-tmp" "$dest" || return 1
    tool_version_set "$name" "$tag"
    UPG_RESULT=updated
}

# Klonlanmış depoyu uzak depodaki son commit'e getir: act_upgrade_git URL HEDEF
# İçindeki izlenen dosyalar elle değiştirildiyse dokunulmaz.
act_upgrade_git() {
    local url="$1" dest="$2" local_head remote_head
    UPG_RESULT=failed UPG_FROM="" UPG_TO=""

    if ! ledger_has path "$dest" || [[ ! -d "$dest/.git" ]]; then
        UPG_RESULT=skipped
        return 0
    fi
    local_head=$(git -C "$dest" rev-parse HEAD 2>/dev/null) || local_head=""
    if [[ -z "$local_head" ]]; then
        log_warn "%s geçerli bir git deposu değil; güncellenmedi" "$(ts_pretty_path "$dest")"
        UPG_RESULT=skipped
        return 0
    fi
    remote_head=$(git ls-remote "$url" HEAD 2>> "$TS_LOG_FILE" | cut -f1)
    [[ -n "$remote_head" ]] || { log_err "%s: uzak depoya ulaşılamadı" "$url"; return 1; }
    UPG_FROM="${local_head:0:7}" UPG_TO="${remote_head:0:7}"
    if [[ "$local_head" == "$remote_head" ]]; then
        UPG_RESULT=current
        return 0
    fi
    if ! git -C "$dest" diff --quiet HEAD 2>/dev/null; then
        log_warn "%s içinde değiştirilmiş dosyalar var; güncellenmedi" "$(ts_pretty_path "$dest")"
        UPG_RESULT=skipped
        return 0
    fi
    if is_dry_run; then
        log_plan "%s %s -> %s" "$(ts_pretty_path "$dest")" "$UPG_FROM" "$UPG_TO"
        UPG_RESULT=planned
        return 0
    fi

    run_logged git -C "$dest" fetch --quiet --depth 1 origin &&
        run_logged git -C "$dest" reset --quiet --hard FETCH_HEAD || return 1
    UPG_TO=$(git -C "$dest" rev-parse --short=7 HEAD)
    UPG_RESULT=updated
}
