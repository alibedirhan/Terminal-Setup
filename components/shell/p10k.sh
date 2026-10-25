#!/usr/bin/env bash
# Bileşen: Powerlevel10k — hızlı ve bilgi dolu prompt

component_register p10k "Powerlevel10k" shell "Git durumunu gösteren hızlı prompt" "ohmyzsh fonts"

component_tip p10k "p10k configure" "Prompt görünümünü yeniden seç"

P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

comp_p10k_install() {
    act_clone https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" || return 1
    act_zsh_snippet 05 p10k-instant '# Anında prompt: zsh başlangıcının en üstünde kalmalı
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi' || return 1
    act_zsh_snippet 16 p10k-theme 'ZSH_THEME="powerlevel10k/powerlevel10k"' || return 1
    act_zsh_snippet 50 p10k-config '[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"' || return 1
    # Sihirbazın yazdığı ayar dosyası kullanıcı verisidir: kaldırmada arşivlenir
    act_userdata "$HOME/.p10k.zsh"
    act_glob "$HOME/.cache/p10k-*"
    act_glob "$HOME/.cache/gitstatus"
}

comp_p10k_verify() {
    [[ -f "$P10K_DIR/powerlevel10k.zsh-theme" ]] && [[ -f "$TS_CONFIG_DIR/zsh.d/16-p10k-theme.zsh" ]]
}
