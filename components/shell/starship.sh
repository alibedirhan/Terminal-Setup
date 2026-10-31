#!/usr/bin/env bash
# Bileşen: Starship — varsayılan prompt (v7). Projeyi tanır: git durumu, Node,
# Python sanal ortamı, Rust, Go; komut süresi ve hata kodu.
#
# Ayar dosyası (~/.config/terminal-setup/starship.toml) temanın renk
# rollerinden ve kişiliğinden üretilir (renderers/starship.sh); tema ya da
# kişilik değişince yeniden yazılır. Kullanıcının ~/.config/starship.toml'una
# dokunulmaz. Powerlevel10k ile aynı anda kurulamaz: ikisi de prompt'u çizer.

component_register starship "Starship" shell "Temaya ve kişiliğe uyan hızlı prompt" "zsh fonts"

component_tip starship "starship preset -l" "Hazır görünümleri listele"
component_tip starship "starship explain" "Prompt'taki her parçanın ne olduğunu göster"

comp_starship_install() {
    if [[ "$(component_state p10k)" == ours ]]; then
        log_err "Starship ve Powerlevel10k birlikte kullanılamaz; önce Powerlevel10k'yı kaldırın."
        return 1
    fi
    act_gh_binary starship/starship '^starship-x86_64-unknown-linux-musl\.tar\.gz$' \
        '^starship-aarch64-unknown-linux-musl\.tar\.gz$' starship || return 1
    # Tema yoksa renkler terminalin kendi 16 renginden; tema uygulanınca yeniden yazılır
    _starship_current_theme
    starship_config
    act_write_file "$STARSHIP_CONFIG_FILE" "$REPLY" || return 1
    # Oh My Zsh'nin teması da prompt yazar; starship en sonda yüklenip onu ezer
    act_zsh_snippet 90 starship "export STARSHIP_CONFIG=\"$STARSHIP_CONFIG_FILE\"
(( \$+commands[starship] )) && eval \"\$(starship init zsh)\"" || return 1
    act_glob "$HOME/.cache/starship"
}

# Uygulanmış tema varsa onu (rolleri ve kişiliğiyle) yükle; yoksa yalnızca kişilik
_starship_current_theme() {
    local theme
    theme=$(settings_get theme)
    if [[ -n "$theme" ]] && theme_load "$theme" 2>/dev/null; then
        return 0
    fi
    THEME=() ROLE=()
    style_effective
    style_load "$REPLY"
}

comp_starship_verify() {
    has_cmd starship && [[ -f "$TS_CONFIG_DIR/zsh.d/90-starship.zsh" && -f "$STARSHIP_CONFIG_FILE" ]]
}
