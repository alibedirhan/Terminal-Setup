#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Komut satırı arayüzü
# ============================================================================
# Menünün yaptığı her şey etkileşimsiz de yapılabilir; testler, video
# çekimleri ve betikler için. Komut verilmezse menü (TUI) açılır.
# ============================================================================

cli_usage() {
    if [[ "$TS_LANG" == en ]] && declare -F cli_usage_en >/dev/null; then
        cli_usage_en
        return
    fi
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
  tips [--shell on|off]         Kurulan araçların kısayolları (ya da açılış ipucu)
  font list | font set AD       Yazı tiplerini listele ya da seç (meslo, jetbrains, firacode)
  doctor [--fix]                Sağlık kontrolü (ve düzeltme)
  uninstall [--appearance]      Tamamen kaldır (ya da sadece görünümü sıfırla)
  verify [--strict]             Sistemi başlangıç fotoğrafıyla karşılaştır
  list [components|profiles|themes]

Seçenekler:
  -n, --dry-run    Hiçbir şeyi değiştirme, yalnızca planı göster
  -y, --yes        Onay sorularını otomatik yanıtla
      --debug      Ayrıntılı çıktı
      --no-color   Renkleri kapat
      --lang DİL   Arayüz dili: tr, en (varsayılan: sistem dili)
  -h, --help       Bu yardım
  -V, --version    Sürüm

Örnekler:
  ./terminal-setup.sh install --profile full --theme nord
  ./terminal-setup.sh --dry-run update
  ./terminal-setup.sh --dry-run uninstall
  ./terminal-setup.sh theme preview dracula
EOF
}

cli_require_value() {
    [[ -n "${2:-}" && "$2" != -* ]] && return 0
    log_err "Seçenek için değer gerekli: %s" "$1"
    return 2
}

cli_main() {
    local args=() lang="" info=""
    i18n_init
    while (($#)); do
        case "$1" in
            -n|--dry-run) TS_DRY_RUN=1 ;;
            -y|--yes) TS_ASSUME_YES=1 ;;
            --debug) TS_DEBUG=1 ;;
            --no-color) C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN="" C_MAGENTA="" C_BOLD="" C_DIM="" C_RESET="" ;;
            --lang) cli_require_value "$1" "${2:-}" || return 2; lang="$2"; shift ;;
            --lang=*) cli_require_value --lang "${1#--lang=}" || return 2; lang="${1#--lang=}" ;;
            -h|--help) info=help ;;
            -V|--version) info=version ;;
            *) args+=("$1") ;;
        esac
        shift
    done
    i18n_init "$lang"
    case "$info" in
        help) cli_usage; return 0 ;;
        version) echo "Terminal Setup $TS_VERSION"; return 0 ;;
    esac
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
        tips) cli_tips "${args[@]}" ;;
        font) cli_font "${args[@]}" ;;
        doctor) run_doctor "${args[@]}" ;;
        uninstall)
            if [[ "${args[0]:-}" == "--appearance" ]]; then appearance_reset; else uninstall_all; fi ;;
        verify) verify_against_baseline "${args[@]}" ;;
        list) cli_list "${args[@]}" ;;
        help) cli_usage ;;
        *) log_err "Bilinmeyen komut: %s" "$cmd"; cli_usage; return 2 ;;
    esac
}

cli_install() {
    local profile="" theme="" components="" ids=()
    while (($#)); do
        case "$1" in
            --profile) cli_require_value "$1" "${2:-}" || return 2; profile="$2"; shift ;;
            --theme) cli_require_value "$1" "${2:-}" || return 2; theme="$2"; shift ;;
            --components) cli_require_value "$1" "${2:-}" || return 2; components="$2"; shift ;;
            *) log_err "Bilinmeyen seçenek: %s" "$1"; return 2 ;;
        esac
        shift
    done
    if [[ -n "$theme" ]] && ! theme_exists "$theme"; then
        log_err "Tema bulunamadı: %s (seçenekler: %s)" "$theme" "$(theme_list | tr '\n' ' ')"
        return 2
    fi
    if [[ -n "$components" ]]; then
        IFS=',' read -ra ids <<< "$components"
    else
        profile="${profile:-$(settings_get default_profile developer)}"
        mapfile -t ids < <(profile_components "$profile") || return 2
        ((${#ids[@]})) || return 2
    fi
    runner_install "${ids[@]}" || return 1
    if [[ -n "$theme" ]]; then
        theme_apply "$theme" || {
            log_warn "Tema uygulanamadı; daha sonra '%s' deneyin." "theme apply $theme"
            return 1
        }
    fi
    install_next_steps
    return 0
}

# Kurulumdan sonra kullanıcıya ne yapacağını söyle
install_next_steps() {
    is_dry_run && return 0
    _t "Sıradaki adımlar"
    printf '\n%s\n' "${C_BOLD}${TR}${C_RESET}"
    _next_step "Değişiklikleri görmek için terminali kapatıp yeniden açın (ya da: exec zsh)"
    if [[ "$(component_state p10k)" == "ours" && ! -f "$HOME/.p10k.zsh" ]]; then
        _next_step "Powerlevel10k sihirbazı ilk açılışta başlar (sonradan: p10k configure)"
    fi
    if [[ "$(component_state fonts)" == "ours" ]]; then
        _next_step "İkonlar kare görünürse terminal yazı tipini \"MesloLGS NF\" yapın"
    fi
    _next_step "Her şeyi geri almak için: ./terminal-setup.sh uninstall"
}

_next_step() { _t "$@"; printf '  • %s\n' "$TR"; }

cli_tips() {
    case "${1:-} ${2:-}" in
        " ") tips_show ;;
        "--shell on") tips_shell_enable && log_ok "Açılış ipucu açıldı; yeni terminallerde görünür." ;;
        "--shell off") tips_shell_disable && log_ok "Açılış ipucu kapatıldı." ;;
        *) log_err "Bilinmeyen seçenek: %s" "$*"; return 2 ;;
    esac
}

cli_font() {
    case "${1:-list}" in
        list) fonts_list ;;
        set) [[ -n "${2:-}" ]] || { log_err "Yazı tipi adı gerekli"; return 2; }; font_select "$2" ;;
        *) log_err "Bilinmeyen seçenek: %s" "$1"; return 2 ;;
    esac
}

cli_remove() {
    local id rc=0
    (($#)) || { log_err "Kaldırılacak bileşeni belirtin."; return 2; }
    for id in "$@"; do
        if ! ledger_component_has_entries "$id"; then
            log_warn "%s: Terminal Setup tarafından kurulmamış; dokunulmadı." "$id"
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
                _t "${THEME[DESC]:-}"
                printf '%-18s %s\n' "$t" "$TR"
            done ;;
        preview) [[ -n "$name" ]] || { log_err "Tema adı gerekli"; return 2; }; theme_preview "$name" ;;
        apply)
            [[ -n "$name" ]] || { log_err "Tema adı gerekli"; return 2; }
            runner_prepare_light || return 1
            theme_apply "$name" ;;
        reset) appearance_reset ;;
        *) log_err "Bilinmeyen tema komutu: %s" "$sub"; return 2 ;;
    esac
}

cli_list() {
    local what="${1:-components}" id cat p
    case "$what" in
        components)
            for cat in "${COMP_CATEGORIES[@]}"; do
                _t "${COMP_CAT_LABEL[$cat]}"
                printf '%s\n' "${C_BOLD}${TR}${C_RESET}"
                for id in $(component_ids_by_cat "$cat"); do
                    _t "${COMP_DESC[$id]}"
                    printf '  %-12s %s\n' "$id" "$TR"
                done
            done ;;
        profiles)
            for p in $(profile_list); do
                _t "$(profile_description "$p")"
                printf '%-10s %s\n' "$p" "$TR"
            done ;;
        themes) cli_theme list ;;
        *) log_err "Bilinmeyen liste: %s" "$what"; return 2 ;;
    esac
}
