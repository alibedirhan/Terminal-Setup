#!/usr/bin/env bash
# Bileşen: karşılama kartı — yeni terminalde yalnızca dikkat isteyenler ve
# kaldığınız proje (resume). Kartı zsh/welcome.zsh çizer; biçimi ve renkleri
# temadan gelir (renderers/welcome.sh).

component_register welcome "Karşılama kartı" shell "Yeni terminalde bekleyen işler ve kaldığınız proje" "zsh"

component_tip welcome "resume" "Kaldığınız projeye dönün"

# Kartın iletileri sistem dilinde (%s zsh'in printf'iyle doldurulur)
_welcome_messages() {
    i18n_zsh_messages _ts_wmsg \
        morning "Günaydın" day "İyi günler" evening "İyi akşamlar" night "İyi geceler" \
        updates "%s güncelleme bekliyor" reboot "Yeniden başlatma gerekli" \
        disk "Disk %%%s dolu" dirty "Kaydedilmemiş iş: %s" \
        resume "Kaldığınız yer" noresume "Dönülecek bir proje yok."
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
