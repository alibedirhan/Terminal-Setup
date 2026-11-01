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
)
