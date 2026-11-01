#!/usr/bin/env bash
# Bileşen: karşılama kartı — yeni terminalde yalnızca dikkat isteyenler ve
# kaldığınız proje (resume). Kartı zsh/welcome.zsh çizer; biçimi ve renkleri
# temadan gelir (renderers/welcome.sh).

component_register welcome "Karşılama kartı" shell "Yeni terminalde bekleyen işler ve kaldığınız proje" "zsh"

component_tip welcome "resume" "Kaldığınız projeye dönün"

# Kartın iletileri sistem dilinde, zsh dizisi olarak -> REPLY
# (değerler zsh'in printf biçimidir; %s çalışırken doldurulur)
_welcome_messages() {
    local key text sq="'"
    local -a pairs=(
        morning "Günaydın" day "İyi günler" evening "İyi akşamlar" night "İyi geceler"
        updates "%s güncelleme bekliyor" reboot "Yeniden başlatma gerekli"
        disk "Disk %%%s dolu" dirty "Kaydedilmemiş iş: %s"
        resume "Kaldığınız yer" noresume "Dönülecek bir proje yok."
    )
    REPLY="typeset -gA _ts_wmsg=("
    while ((${#pairs[@]})); do
        key="${pairs[0]}"
        _t "${pairs[1]}"
        pairs=("${pairs[@]:2}")
        # Tek tırnak içinde: metindeki ' -> '\''
        text="${TR//$sq/$sq\\$sq$sq}"
        REPLY+=$'\n'"    $key $sq$text$sq"
    done
    # Büyük/küçük harf dönüşümü için (Türkçede i/İ, ı/I)
    REPLY+=$'\n'"    lang $TS_LANG"$'\n'")"
}

comp_welcome_install() {
    _welcome_messages
    act_zsh_snippet 96 welcome "$REPLY"$'\n'"$(cat "$TS_ROOT/zsh/welcome.zsh")" || return 1
    # Projeler ve arka plan bilgisi önbellektir
    act_glob "${XDG_CACHE_HOME:-$HOME/.cache}/terminal-setup/welcome*"
    act_glob "${XDG_CACHE_HOME:-$HOME/.cache}/terminal-setup/projects"
    # Uygulanmış bir tema varsa kartı ona göre biçimlendir
    theme_apply_one welcome
}

comp_welcome_verify() { [[ -f "$TS_CONFIG_DIR/zsh.d/96-welcome.zsh" ]]; }
