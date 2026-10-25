#!/usr/bin/env bash
# Teşhis: zsh ne kadar hızlı açılıyor? Yavaşsa en çok zaman alan parçaları söyler.

diag_register zshspeed "Zsh açılışı"

ZSH_SLOW_MS=300

# Bir zsh açılışının süresi (ms): _zsh_start_ms -> REPLY
_zsh_start_ms() {
    local s e
    s=${EPOCHREALTIME/[.,]/}
    zsh -i -c exit < /dev/null > /dev/null 2>&1 || return 1
    e=${EPOCHREALTIME/[.,]/}
    REPLY=$(((e - s) / 1000))
}

# En yavaş iki parça: "40-ohmyzsh-load 210 ms, 70-atuin 60 ms" -> REPLY
_zsh_slowest_parts() {
    REPLY=$(TS_ZSH_TIMING=1 zsh -i -c exit 2>&1 < /dev/null > /dev/null |
        awk '$1 == "ts-timing" { print $3, $2 }' | sort -rn | head -2 |
        awk '{ printf "%s%s %d ms", (NR > 1 ? ", " : ""), $2, $1 }')
}

diag_zshspeed_check() {
    local best="" i
    if ! has_cmd zsh || [[ ! -f "$TS_CONFIG_DIR/init.zsh" ]]; then
        diag_say "Zsh bileşeni kurulu değil"
        return 0
    fi
    if [[ -z "${EPOCHREALTIME:-}" ]]; then
        diag_say "ölçülemedi (bash 5 gerekir)"
        return 0
    fi
    for i in 1 2 3; do
        _zsh_start_ms || { diag_say "zsh başlatılamadı"; return 2; }
        [[ -z "$best" || "$REPLY" -lt "$best" ]] && best="$REPLY"
    done
    if ((best <= ZSH_SLOW_MS)); then
        diag_say "%s ms" "$best"
        return 0
    fi
    _zsh_slowest_parts
    if [[ -n "$REPLY" ]]; then
        diag_say "%s ms, yavaş. En çok zaman alan: %s" "$best" "$REPLY"
    else
        diag_say "%s ms, yavaş (%s ms üstü)" "$best" "$ZSH_SLOW_MS"
    fi
    return 1
}
