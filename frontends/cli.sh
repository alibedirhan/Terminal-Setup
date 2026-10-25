#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Komut satırı arayüzü
# ============================================================================
# Menünün yaptığı her şey etkileşimsiz de yapılabilir; testler, video
# çekimleri ve betikler için. Komut verilmezse menü (TUI) açılır.
# ============================================================================

cli_usage() {
    cat <<EOF
Terminal Setup $TS_VERSION — Ubuntu terminal özelleştirme aracı

Kullanım: terminal-setup.sh [seçenekler] [komut]

Komutlar:
  (yok)                         Menüyü aç
  install [--profile P] [--theme T] [--components a,b]
                                Kur. Varsayılan profil: developer
  remove BİLEŞEN...             Bileşenleri kaldır
  update [BİLEŞEN...]           Kurulan araçları son sürüme güncelle
  theme list                    Temaları listele
  theme preview TEMA            Temayı terminalde önizle
  theme apply TEMA              Temayı uygula
  theme reset                   Görünümü kurulum öncesine döndür
  status                        Neyin kurulu olduğunu göster
  doctor [--fix]                Sağlık kontrolü (ve düzeltme)
  uninstall [--appearance]      Tamamen kaldır (ya da sadece görünümü sıfırla)
  verify [--strict]             Sistemi başlangıç fotoğrafıyla karşılaştır
  list [components|profiles|themes]

Seçenekler:
  -n, --dry-run    Hiçbir şeyi değiştirme, yalnızca planı göster
  -y, --yes        Onay sorularını otomatik yanıtla
      --debug      Ayrıntılı çıktı
      --no-color   Renkleri kapat
  -h, --help       Bu yardım
  -V, --version    Sürüm

Örnekler:
  ./terminal-setup.sh install --profile full --theme nord
  ./terminal-setup.sh --dry-run update
  ./terminal-setup.sh --dry-run uninstall
  ./terminal-setup.sh theme preview dracula
EOF
}

cli_main() {
    local args=()
    while (($#)); do
        case "$1" in
            -n|--dry-run) TS_DRY_RUN=1 ;;
            -y|--yes) TS_ASSUME_YES=1 ;;
            --debug) TS_DEBUG=1 ;;
            --no-color) C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN="" C_MAGENTA="" C_BOLD="" C_DIM="" C_RESET="" ;;
            -h|--help) cli_usage; return 0 ;;
            -V|--version) echo "Terminal Setup $TS_VERSION"; return 0 ;;
            *) args+=("$1") ;;
        esac
        shift
    done
    ts_init || return 1
    is_dry_run && log_info "Prova modu: hiçbir şey değiştirilmeyecek."

    local cmd="${args[0]:-}"
    ((${#args[@]})) && args=("${args[@]:1}")
    case "$cmd" in
        "")
            if ui_is_tty; then tui_main; else cli_usage; return 1; fi ;;
        install) cli_install "${args[@]}" ;;
        remove) cli_remove "${args[@]}" ;;
        update) upgrade_run "${args[@]}" ;;
        theme) cli_theme "${args[@]}" ;;
        status) status_show ;;
        doctor) run_doctor "${args[@]}" ;;
        uninstall)
            if [[ "${args[0]:-}" == "--appearance" ]]; then appearance_reset; else uninstall_all; fi ;;
        verify) verify_against_baseline "${args[@]}" ;;
        list) cli_list "${args[@]}" ;;
        help) cli_usage ;;
        *) log_err "Bilinmeyen komut: $cmd"; cli_usage; return 2 ;;
    esac
}

cli_install() {
    local profile="" theme="" components="" ids=() rc=0
    while (($#)); do
        case "$1" in
            --profile) profile="${2:-}"; shift ;;
            --theme) theme="${2:-}"; shift ;;
            --components) components="${2:-}"; shift ;;
            *) log_err "Bilinmeyen seçenek: $1"; return 2 ;;
        esac
        shift
    done
    if [[ -n "$theme" ]] && ! theme_exists "$theme"; then
        log_err "Tema bulunamadı: $theme (seçenekler: $(theme_list | tr '\n' ' '))"
        return 2
    fi
    if [[ -n "$components" ]]; then
        IFS=',' read -ra ids <<< "$components"
    else
        profile="${profile:-$(settings_get default_profile developer)}"
        mapfile -t ids < <(profile_components "$profile") || return 2
        ((${#ids[@]})) || return 2
    fi
    runner_install "${ids[@]}" || rc=1
    if [[ -n "$theme" ]]; then
        theme_apply "$theme" || log_warn "Tema uygulanamadı; daha sonra 'theme apply $theme' deneyin."
    fi
    install_next_steps
    return "$rc"
}

# Kurulumdan sonra kullanıcıya ne yapacağını söyle
install_next_steps() {
    is_dry_run && return 0
    printf '\n%s\n' "${C_BOLD}Sıradaki adımlar${C_RESET}"
    printf '  • Değişiklikleri görmek için terminali kapatıp yeniden açın (ya da: exec zsh)\n'
    if [[ "$(component_state p10k)" == "ours" && ! -f "$HOME/.p10k.zsh" ]]; then
        printf '  • Powerlevel10k sihirbazı ilk açılışta başlar (sonradan: p10k configure)\n'
    fi
    if [[ "$(component_state fonts)" == "ours" ]]; then
        printf '  • İkonlar kare görünürse terminal yazı tipini "MesloLGS NF" yapın\n'
    fi
    printf '  • Her şeyi geri almak için: ./terminal-setup.sh uninstall\n'
}

cli_remove() {
    local id rc=0
    (($#)) || { log_err "Kaldırılacak bileşeni belirtin."; return 2; }
    for id in "$@"; do
        if ! ledger_component_has_entries "$id"; then
            log_warn "$id: Terminal Setup tarafından kurulmamış; dokunulmadı."
            continue
        fi
        runner_remove_component "$id" || rc=1
    done
    return "$rc"
}

cli_theme() {
    local sub="${1:-list}" name="${2:-}" current t
    case "$sub" in
        list)
            current=$(settings_get theme)
            for t in $(theme_list); do
                theme_load "$t" >/dev/null || continue
                [[ "$t" == "$current" ]] && printf '* ' || printf '  '
                printf '%-12s %s\n' "$t" "${THEME[DESC]:-}"
            done ;;
        preview) [[ -n "$name" ]] || { log_err "Tema adı gerekli"; return 2; }; theme_preview "$name" ;;
        apply)
            [[ -n "$name" ]] || { log_err "Tema adı gerekli"; return 2; }
            runner_prepare_light || return 1
            theme_apply "$name" ;;
        reset) appearance_reset ;;
        *) log_err "Bilinmeyen tema komutu: $sub"; return 2 ;;
    esac
}

cli_list() {
    local what="${1:-components}" id cat p
    case "$what" in
        components)
            for cat in "${COMP_CATEGORIES[@]}"; do
                printf '%s\n' "${C_BOLD}${COMP_CAT_LABEL[$cat]}${C_RESET}"
                for id in $(component_ids_by_cat "$cat"); do
                    printf '  %-12s %s\n' "$id" "${COMP_DESC[$id]}"
                done
            done ;;
        profiles)
            for p in $(profile_list); do printf '%-10s %s\n' "$p" "$(profile_description "$p")"; done ;;
        themes) cli_theme list ;;
        *) log_err "Bilinmeyen liste: $what"; return 2 ;;
    esac
}
