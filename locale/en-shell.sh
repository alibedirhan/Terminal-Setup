#!/usr/bin/env bash
# shellcheck disable=SC2034  # I18N_EN lib/i18n.sh içinde kullanılır
# ============================================================================
# Terminal Setup - English catalog: kabuğun içindeki özellikler
# ============================================================================
# Karşılama kartı, komut paleti ve Alt+H yardımı: bileşen adları, kısayol
# ipuçları ve kabukta görünen iletiler. İletiler kurulumda sistem dilinde
# zsh parçasına yazılır; %s zsh'in printf'iyle çalışırken doldurulur.
# ============================================================================

declare -gA I18N_EN
I18N_EN+=(
    # --- Karşılama kartı ------------------------------------------------------
    ["Karşılama kartı"]="Welcome card"
    ["karşılama kartı"]="welcome card"
    ["Yeni terminalde bekleyen işler ve kaldığınız proje"]="What needs attention and your last project, in each new terminal"
    ["Kaldığınız projeye dönün"]="Go back to your last project"
    ["Günaydın"]="Good morning"
    ["İyi günler"]="Good afternoon"
    ["İyi akşamlar"]="Good evening"
    ["İyi geceler"]="Good night"
    ["%s güncelleme bekliyor"]="%s updates waiting"
    ["Yeniden başlatma gerekli"]="Restart required"
    ["Disk %%%s dolu"]="Disk %s%% full"
    ["Kaydedilmemiş iş: %s"]="Uncommitted work: %s"
    ["Kaldığınız yer"]="Last project"
    ["Dönülecek bir proje yok."]="No project to go back to."

    # --- Komut paleti ----------------------------------------------------------
    ["Komut paleti"]="Command palette"
    ["Ctrl+Space: projenin betikleri, testler, git ve son komutlar"]="Ctrl+Space: the project's scripts, tests, git and recent commands"
    ["Bu projede çalıştırabileceklerinizi listeleyin"]="List what you can run in this project"
    ["betik"]="script"
    ["test"]="test"
    ["ortam"]="env"
    ["geçmiş"]="recent"
    ["sanal ortamı aç"]="activate the virtual env"
    ["Bu dizinde önerilecek komut yok."]="Nothing to suggest in this directory."
    ["Enter: komut satırına yaz · Esc: kapat"]="Enter: put it on the command line · Esc: close"

    # --- Alt+H yardımı -----------------------------------------------------------
    ["Yazdığınız komutun kısa yardımını göster"]="Show quick help for the command you are typing"
    ["%s için yardım sayfası yok."]="No help page for %s."
)
