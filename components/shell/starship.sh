#!/usr/bin/env bash
# Bileşen: Starship — hızlı, her kabukta çalışan prompt (Powerlevel10k'ya seçenek)
#
# Powerlevel10k ile aynı anda kurulamaz: ikisi de prompt'u çizer. Renkler
# terminal paletinden gelir, yani seçilen temaya kendiliğinden uyar.

component_register starship "Starship" shell "Hızlı ve sade prompt (Powerlevel10k yerine)" "zsh fonts"

component_tip starship "starship preset -l" "Hazır görünümleri listele"
component_tip starship "starship explain" "Prompt'taki her parçanın ne olduğunu göster"

comp_starship_install() {
    if [[ "$(component_state p10k)" == ours ]]; then
        log_err "Starship ve Powerlevel10k birlikte kullanılamaz; önce Powerlevel10k'yı kaldırın."
        return 1
    fi
    act_gh_binary starship/starship '^starship-x86_64-unknown-linux-musl\.tar\.gz$' \
        '^starship-aarch64-unknown-linux-musl\.tar\.gz$' starship || return 1
    # Oh My Zsh'nin teması da prompt yazar; starship en sonda yüklenip onu ezer
    act_zsh_snippet 90 starship '(( $+commands[starship] )) && eval "$(starship init zsh)"' || return 1
    act_glob "$HOME/.cache/starship"
}

comp_starship_verify() {
    has_cmd starship && [[ -f "$TS_CONFIG_DIR/zsh.d/90-starship.zsh" ]]
}
