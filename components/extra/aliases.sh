#!/usr/bin/env bash
# Bileşen: Alias'lar — örnek kısayollar + mevcut ~/.aliases / ~/.bash_aliases
# dosyalarınızı zsh'de de kullanma. Dosyalarınıza dokunulmaz, sadece okunur.

component_register aliases "Alias'lar" extra "Örnek kısayollar; bash alias'larınızı zsh'e taşır" "zsh"

component_tip aliases ".." "Üst dizine çık"
component_tip aliases "gst" "git status"
component_tip aliases "glg" "Git geçmişini grafikle göster"

comp_aliases_install() {
    local f user_files=()
    act_zsh_snippet 90 aliases "$(cat "$TS_ROOT/aliases/aliases.zsh")" || return 1
    for f in "$HOME/.aliases" "$HOME/.bash_aliases"; do
        [[ -f "$f" ]] && user_files+=("$f")
    done
    ((${#user_files[@]} == 0)) && return 0
    log_info "Bulunan alias dosyaları: %s" "${user_files[*]}"
    ui_confirm "Bu dosyalar zsh'de de yüklensin mi?" e || return 0
    local content="# Kullanıcının kendi alias dosyaları (yalnızca okunur)"
    for f in "${user_files[@]}"; do
        content+=$'\n'"[[ -r \"$f\" ]] && source \"$f\""
    done
    act_zsh_snippet 91 user-aliases "$content"
}

comp_aliases_verify() { [[ -f "$TS_CONFIG_DIR/zsh.d/90-aliases.zsh" ]]; }
