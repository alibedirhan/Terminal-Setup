#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Arayüz: sorular
# ============================================================================
# Evet/hayır, yazarak onay ve "devam için Enter". Satır okuyan sorular normal
# terminal kipi ister; menü çizim kipindeyken çağrılırlarsa terminal geçici
# olarak normal kipe alınır ve sonra geri dönülür. Böylece bileşenler ve
# kaldırma adımları hangi bağlamdan çağrıldıklarını bilmek zorunda kalmaz.
# ============================================================================

_UI_PROMPT_RESUME=0

_ui_prompt_begin() {
    _UI_PROMPT_RESUME=0
    if ui_term_drawing; then
        ui_term_suspend
        _UI_PROMPT_RESUME=1
    fi
}

_ui_prompt_end() {
    ((_UI_PROMPT_RESUME)) && ui_term_resume
    _UI_PROMPT_RESUME=0
    return 0
}

ui_pause() {
    [[ "$TS_ASSUME_YES" == "1" ]] && return 0
    ui_is_tty || return 0
    _ui_prompt_begin
    _t "devam etmek için basın"
    printf '\n%s%s enter %s %s%s%s ' "$UI_M" "$U_CAP" "$U_RST" "$U_MUTED" "$TR" "$U_RST"
    read -r _ || true
    _ui_prompt_end
}

# Evet/hayır sorusu: ui_confirm "Soru %s" [e|h varsayılan] [ARG...]
# Soru çevrilir; yanıt her iki dilde de kabul edilir (e/evet/y/yes).
ui_confirm() {
    local question default="${2:-h}" answer hint rc
    [[ "$TS_ASSUME_YES" == "1" ]] && return 0
    _t "$1" "${@:3}"
    question="$TR"
    if [[ "$TS_LANG" == en ]]; then
        [[ "$default" == "e" ]] && hint="Y/n" || hint="y/N"
    else
        [[ "$default" == "e" ]] && hint="E/h" || hint="e/H"
    fi
    _ui_prompt_begin
    while true; do
        printf '%s%s?%s %s%s%s %s(%s)%s %s›%s ' "$UI_M" "$U_ACC" "$U_RST" "$U_BOLD" "$question" "$U_RST" \
            "$U_MUTED" "$hint" "$U_RST" "$U_ACC" "$U_RST"
        if ! IFS= read -r answer; then rc=1; break; fi
        answer="${answer:-$default}"
        case "${answer,,}" in
            e|evet|y|yes) rc=0; break ;;
            h|hayır|hayir|n|no) rc=1; break ;;
        esac
        _t "Lütfen 'e' veya 'h' girin."
        printf '%s%s\n' "$UI_M" "${U_MUTED}${TR}${U_RST}"
    done
    _ui_prompt_end
    return "$rc"
}

# Tehlikeli işlem için kelime yazdırarak onay: ui_type_confirm "kaldır"
# Kelime de çevrilir; kullanıcı ekranda gördüğünü yazar.
ui_type_confirm() {
    local word answer="" rc=1
    [[ "$TS_ASSUME_YES" == "1" ]] && return 0
    _t "$1"
    word="$TR"
    _t "Onaylamak için %s yazın" "${U_BOLD}${word}${U_RST}"
    _ui_prompt_begin
    printf '%s%s!%s %s %s›%s ' "$UI_M" "$U_ERR" "$U_RST" "$TR" "$U_ERR" "$U_RST"
    IFS= read -r answer && [[ "$answer" == "$word" ]] && rc=0
    _ui_prompt_end
    return "$rc"
}
