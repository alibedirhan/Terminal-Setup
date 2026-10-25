#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Arayüz: terminal oturumu ve tuş okuma
# ============================================================================
# Terminalin kipine dokunan tek yer burasıdır.
#
#   ui_term_enter    menü oturumu: alternatif ekran, imleç gizli, satır
#                    kaydırma kapalı, tuş yankısı kapalı. Çizim sırasında
#                    basılan tuşlar ekrana çöp olarak düşmez.
#   ui_term_suspend  bir işlem çalışacak: terminal normal kipe ve ana ekrana
#                    döner; işlemin çıktısı kaydırılabilir geçmişte kalır.
#   ui_term_resume   menüye geri dön.
#   ui_term_leave    oturumu kapat.
#
# Çıkışta, Ctrl+C'de ya da hata ile sonlanmada terminal her durumda eski
# haline döner (ts_on_exit kancası). Tüm fonksiyonlar tekrar çağrılmaya
# dayanıklıdır; terminal yoksa hiçbir şey yapmaz.
# ============================================================================

UI_KEY=""             # ui_read_key sonucu
UI_COLS=80 UI_ROWS=24 # terminal boyutu (ui_term_size)
UI_RESIZED=0          # pencere boyutu değişti; sonraki çizim ekranı tam temizler
UI_TERM_ACTIVE=0      # menü oturumu açık mı
UI_TERM_SUSPENDED=0   # oturum açık ama bir işlem için normal kipte mi
_UI_STTY=""           # oturum öncesi terminal ayarları (stty -g)
_UI_HOOKED=0
_UI_SIZE_KNOWN=0      # oturumda boyut yalnızca WINCH sinyalinden sonra yeniden sorulur

ui_is_tty() { [[ -t 0 && -t 1 ]]; }

# Terminal boyutu -> UI_COLS, UI_ROWS (terminal yoksa COLUMNS/LINES ya da 80x24).
# Menü oturumunda her çizimde sorulmaz; pencere boyutu değişince yenilenir.
ui_term_size() {
    local size="" cols="" rows=""
    ((UI_TERM_ACTIVE && _UI_SIZE_KNOWN)) && return 0
    if ui_is_tty && size=$(stty size 2>/dev/null); then
        rows=${size% *} cols=${size#* }
    fi
    [[ "$cols" =~ ^[1-9][0-9]*$ ]] || cols=${COLUMNS:-80}
    [[ "$rows" =~ ^[1-9][0-9]*$ ]] || rows=${LINES:-24}
    [[ "$cols" =~ ^[1-9][0-9]*$ ]] || cols=80
    [[ "$rows" =~ ^[1-9][0-9]*$ ]] || rows=24
    UI_COLS=$cols UI_ROWS=$rows
    ((UI_TERM_ACTIVE)) && _UI_SIZE_KNOWN=1
    return 0
}

_ui_term_raw() {
    stty -echo -icanon 2>/dev/null
    # alternatif ekran, imleç gizli, satır sonunda kaydırma yok
    printf '\033[?1049h\033[?25l\033[?7l'
}

_ui_term_cooked() {
    printf '\033[?7h\033[?25h\033[?1049l'
    [[ -n "$_UI_STTY" ]] && stty "$_UI_STTY" 2>/dev/null
    return 0
}

ui_term_enter() {
    ui_is_tty || return 0
    ((UI_TERM_ACTIVE)) && return 0
    _UI_STTY=$(stty -g 2>/dev/null)
    if ((!_UI_HOOKED)); then
        ts_on_exit _ui_term_exit
        _UI_HOOKED=1
    fi
    trap 'UI_RESIZED=1 _UI_SIZE_KNOWN=0' WINCH
    _ui_term_raw
    UI_TERM_ACTIVE=1 UI_TERM_SUSPENDED=0 UI_RESIZED=1 _UI_SIZE_KNOWN=0
}

ui_term_leave() {
    ((UI_TERM_ACTIVE)) || return 0
    ((UI_TERM_SUSPENDED)) || _ui_term_cooked
    trap - WINCH
    UI_TERM_ACTIVE=0 UI_TERM_SUSPENDED=0 _UI_SIZE_KNOWN=0 UI_M=""
}

# Çıkış kancası. Tuş okuyan "read -s" Ctrl+C ile yarıda kesilirse bash,
# okumadan önce kaydettiği (menü kipindeki) ayarları kesinti işleyicisinden
# SONRA geri yükler. Bu yüzden çıkışta oturum öncesi ayarlar koşulsuz,
# en son yeniden yüklenir.
_ui_term_exit() {
    ui_term_leave
    [[ -n "$_UI_STTY" ]] && stty "$_UI_STTY" 2>/dev/null
    [[ -t 1 ]] && printf '\033[?7h\033[?25h'
    return 0
}

ui_term_suspend() {
    ((UI_TERM_ACTIVE && !UI_TERM_SUSPENDED)) || return 0
    _ui_term_cooked
    UI_TERM_SUSPENDED=1
}

ui_term_resume() {
    ((UI_TERM_ACTIVE && UI_TERM_SUSPENDED)) || return 0
    _ui_term_raw
    UI_TERM_SUSPENDED=0 UI_RESIZED=1 _UI_SIZE_KNOWN=0
}

# Menü oturumu açık ve şu an çizim kipinde mi
ui_term_drawing() { ((UI_TERM_ACTIVE && !UI_TERM_SUSPENDED)); }

# Tek tuş oku -> UI_KEY: up down left right home end pgup pgdn enter space
# tab backspace esc eof resize ya da basılan karakter. Sonuç değişkene
# yazılır; alt kabukta çağrılırsa pencere boyutu sinyali yakalanamaz.
ui_read_key() {
    local k="" c1="" c2="" c3="" rc
    IFS= read -rsn1 k
    rc=$?
    if ((rc > 128)); then UI_KEY=resize; return 0; fi
    if ((rc != 0)); then UI_KEY=eof; return 0; fi
    case "$k" in
        $'\033')
            IFS= read -rsn1 -t 0.05 c1 || true
            if [[ "$c1" == "[" || "$c1" == "O" ]]; then
                IFS= read -rsn1 -t 0.05 c2 || true
                if [[ "$c2" == [0-9] ]]; then
                    IFS= read -rsn1 -t 0.05 c3 || true
                    [[ "$c3" == "~" ]] || c2=""
                fi
            fi
            case "$c2" in
                A) UI_KEY=up ;; B) UI_KEY=down ;; C) UI_KEY=right ;; D) UI_KEY=left ;;
                H|1|7) UI_KEY=home ;; F|4|8) UI_KEY=end ;; 5) UI_KEY=pgup ;; 6) UI_KEY=pgdn ;;
                *) UI_KEY=esc ;;
            esac ;;
        "" | $'\n' | $'\r') UI_KEY=enter ;;
        " ") UI_KEY=space ;;
        $'\t') UI_KEY=tab ;;
        $'\177' | $'\b') UI_KEY=backspace ;;
        *) UI_KEY="$k" ;;
    esac
}
