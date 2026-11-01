#!/usr/bin/env bash
# Bileşen: btop — sistem izleyici

component_register btop "btop" tools "Sistem izleyici" ""

component_tip btop "btop" "Sistem kaynaklarını izle"

comp_btop_install() {
    act_pkg btop || return 1
    # btop ayarlarını çıkarken btop.conf'a yazar: kullanıcı verisi, arşive taşınır.
    # Günlük dosyası silinir; dizin boş kalırsa o da (themes/ tema bileşenine ait).
    act_userdata "$HOME/.config/btop/btop.conf"
    act_glob "$HOME/.config/btop/btop.log"
}

comp_btop_verify() { has_cmd btop; }
