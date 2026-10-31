#!/usr/bin/env bash
# Bileşen: Zsh — kabuk, yönetilen başlangıç dosyası ve varsayılan kabuk

component_register zsh "Zsh" shell "Gelişmiş kabuk; varsayılan kabuk yapılır" ""

_zsh_init_content() {
    cat <<INIT
# Terminal Setup — yönetilen zsh başlangıcı. Bu dosyayı düzenlemeyin; kaldırmada
# silinir. Kendi ayarlarınızı ~/.zshrc içinde, terminal-setup bloğunun dışına yazın.
typeset -U path PATH
path=("\$HOME/.local/bin" \$path)
# TS_ZSH_TIMING tanımlıysa her parçanın süresi stderr'e yazılır (doctor kullanır)
(( \${+TS_ZSH_TIMING} )) && zmodload zsh/datetime
for _ts_snippet in "$TS_CONFIG_DIR"/zsh.d/*.zsh(N); do
    (( \${+TS_ZSH_TIMING} )) && _ts_t=\$EPOCHREALTIME
    source "\$_ts_snippet"
    (( \${+TS_ZSH_TIMING} )) && printf 'ts-timing %s %d\\n' "\${_ts_snippet:t:r}" \$(( (EPOCHREALTIME - _ts_t) * 1000 )) >&2
done
unset _ts_snippet _ts_t
INIT
}

comp_zsh_install() {
    local zsh_path
    act_pkg zsh || return 1
    act_write_file "$TS_CONFIG_DIR/init.zsh" "$(_zsh_init_content)" || return 1
    act_rc_block "$HOME/.zshrc" zsh "# Terminal Setup ayarlarını yükler. Bu bloğu düzenlemeyin.
[[ -r \"$TS_CONFIG_DIR/init.zsh\" ]] && source \"$TS_CONFIG_DIR/init.zsh\"" top || return 1
    # Temel: geçmiş, tamamlama, tuşlar, başlık, OSC 7 (Oh My Zsh gerekmez)
    act_zsh_snippet 10 base "$(cat "$TS_ROOT/zsh/base.zsh")" || return 1
    # Kullanımla oluşan dosyalar: geçmiş arşivlenir, tamamlama önbelleği silinir
    act_userdata "$HOME/.zsh_history"
    act_glob "$HOME/.zcompdump*"
    act_glob "${XDG_CACHE_HOME:-$HOME/.cache}/terminal-setup"
    zsh_path=$(command -v zsh || echo /usr/bin/zsh)
    act_login_shell "$zsh_path"
}

comp_zsh_verify() {
    has_cmd zsh && [[ -f "$TS_CONFIG_DIR/init.zsh" ]] && rc_has_block "$HOME/.zshrc" zsh
}
