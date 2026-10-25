#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Kısayollar ve açılış ipucu
# ============================================================================
# Bileşenler ne öğrettiğini kendi dosyasında bildirir:
#   component_tip fzf "Ctrl+R" "Komut geçmişinde bulanık ara"
# "Kısayollar" ekranı yalnızca kurulu (script'in ya da kullanıcının) araçların
# ipuçlarını gösterir. İstenirse (Ayarlar → Açılış ipucu) her yeni zsh
# oturumunda bunlardan biri tek satır gösterilir: ipuçları seçili dilde
# ~/.config/terminal-setup/tips.txt dosyasına yazılır, zsh parçası ilk
# prompttan önce rastgele birini basar. Bu dosyalar "tips" bileşenine aittir;
# kapatınca ya da kaldırınca silinir.
# ============================================================================

declare -ga TIP_COMP=() TIP_KEY=() TIP_TEXT=()
TIPS_FILE="$TS_CONFIG_DIR/tips.txt"
RUNNER_AFTER_CHANGE+=(tips_shell_refresh)

component_tip() {
    TIP_COMP+=("$1")
    TIP_KEY+=("$2")
    TIP_TEXT+=("$3")
}

# Kurulu bileşenlerin ipucu sıraları -> TIPS_IDX
tips_collect() {
    local i id
    local -A state=()
    TIPS_IDX=()
    for i in "${!TIP_COMP[@]}"; do
        id="${TIP_COMP[i]}"
        [[ -n "${state[$id]:-}" ]] || state[$id]=$(component_state "$id")
        [[ "${state[$id]}" == ours || "${state[$id]}" == external ]] && TIPS_IDX+=("$i")
    done
}

# Kısayollar ekranı (CLI: tips)
tips_show() {
    local i id last="" key
    ui_title "Kısayollar"
    tips_collect
    if ((${#TIPS_IDX[@]} == 0)); then
        log_info "Henüz kısayolu olan bir araç kurulu değil."
        return 0
    fi
    for i in "${TIPS_IDX[@]}"; do
        id="${TIP_COMP[i]}"
        if [[ "$id" != "$last" ]]; then
            ui_line ""
            ui_section "$(comp_label "$id")"
            last="$id"
        fi
        _t "${TIP_KEY[i]}"
        ui_padr "$TR" 16
        key="$REPLY"
        _t "${TIP_TEXT[i]}"
        ui_line "  ${U_ACC}${key}${U_RST} $TR"
    done
    ui_line ""
}

# Açılış ipucunu aç ya da (açıksa) yeniden yaz; dil ya da araçlar değişince çağrılır
tips_shell_enable() {
    local i lines="" owner="$TS_CURRENT_COMPONENT"
    if [[ ! -f "$TS_CONFIG_DIR/init.zsh" ]]; then
        log_warn "Açılış ipucu için Zsh bileşeni kurulu olmalı."
        return 1
    fi
    runner_prepare_light || return 1
    tips_collect
    for i in "${TIPS_IDX[@]}"; do
        _t "${TIP_KEY[i]}"
        lines+="$TR — "
        _t "${TIP_TEXT[i]}"
        lines+="$TR"$'\n'
    done
    TS_CURRENT_COMPONENT="tips"
    act_write_file "$TIPS_FILE" "${lines%$'\n'}" &&
        _t "ipucu" &&
        act_zsh_snippet 95 tips "_ts_tip() {
    add-zsh-hook -d precmd _ts_tip
    [[ -r '$TIPS_FILE' ]] || return 0
    local -a tips=(\"\${(@f)\$(<'$TIPS_FILE')}\")
    (( \${#tips} )) && printf '\\e[2m%s:\\e[0m %s\\n' '$TR' \"\${tips[RANDOM % \${#tips} + 1]}\"
}
autoload -Uz add-zsh-hook && add-zsh-hook precmd _ts_tip"
    local rc=$?
    TS_CURRENT_COMPONENT="$owner"
    ((rc == 0)) && settings_set shell_tips on
    return "$rc"
}

tips_shell_disable() {
    ledger_component_has_entries tips && undo_component tips
    settings_set shell_tips off
}

# Açıksa ipucu dosyasını güncelle (kurulum, kaldırma ve dil değişiminden sonra)
tips_shell_refresh() {
    [[ "$(settings_get shell_tips off)" == on ]] || return 0
    tips_shell_enable > /dev/null
}
