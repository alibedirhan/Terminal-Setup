# Terminal Setup — karşılama kartı
# Yeni terminalde yalnızca dikkat isteyenler gösterilir: bekleyen
# güncellemeler, yeniden başlatma, dolmak üzere olan disk, kaydedilmemiş iş
# ve kaldığınız proje (resume ile dönülür). Söylenecek bir şey yoksa kart
# çıkmaz; tmux içinde ve TS_WELCOME=off iken de çıkmaz.
# Kart çizilirken dış komut çalışmaz. Güncelleme, disk ve git bilgisi arka
# planda, en çok saatte bir önbelleğe yazılır.

zmodload zsh/datetime 2>/dev/null
zmodload -F zsh/stat b:zstat 2>/dev/null
typeset -g _ts_wcache="${XDG_CACHE_HOME:-$HOME/.cache}/terminal-setup"

# Biçim ve renkler: tema uygulanınca 65-theme-welcome.zsh bunları kişilikten
# ve renk rollerinden tanımlar. Tema yoksa terminalin 16 rengi.
(( ${+_ts_card} )) || typeset -gA _ts_card=(
    border rounded seg plain tcase normal xcase normal marks '● ◆ ↳' sep '·' date '+%d.%m.%y %H:%M'
    frame $'\e[34m' title $'\e[1;34m' text $'\e[0m' muted $'\e[2m'
    warn $'\e[33m' err $'\e[31m' cmd $'\e[1;34m' tag $'\e[1;30;44m' tagend $'\e[34m'
)

# Kullanıcının kendi resume komutu varsa ona dokunulmaz
if (( $+commands[resume] || $+aliases[resume] || $+functions[resume] )); then
    typeset -g _ts_resume=ts-resume
else
    typeset -g _ts_resume=resume
fi

# --- Projeler: dizin değişince git kökü kaydedilir ------------------------
# Fonksiyonlar kullanıcının kabuk seçeneklerinden etkilenmesin diye
# emulate -L zsh ile başlar.
_ts_git_root() {
    emulate -L zsh
    local d=$PWD
    while [[ -n $d && $d != / ]]; do
        [[ -e $d/.git ]] && { REPLY=$d; return 0; }
        d=${d:h}
    done
    return 1
}

# En son girilen projeler, en yenisi başta (en çok 10)
_ts_project_seen() {
    emulate -L zsh
    _ts_git_root || return 0
    local root=$REPLY f=$_ts_wcache/projects
    local -a list
    [[ -r $f ]] && list=("${(@f)$(<$f)}")
    [[ ${list[1]-} == $root ]] && return 0
    list=($root ${list:#$root})
    [[ -d $_ts_wcache ]] || mkdir -p -- $_ts_wcache 2>/dev/null || return 0
    print -rl -- ${list[1,10]} >| $f 2>/dev/null
}

# Projenin dalı .git/HEAD'den: _ts_branch KÖK -> REPLY (çalışma ağacında .git dosyadır)
_ts_branch() {
    emulate -L zsh
    local git=$1/.git head
    REPLY=""
    if [[ -f $git ]]; then
        head=$(<$git)
        git=${head#gitdir: }
        [[ $git == /* ]] || git=$1/$git
    fi
    [[ -r $git/HEAD ]] || return 1
    head=$(<$git/HEAD)
    REPLY=${head#ref: refs/heads/}
    [[ $REPLY == $head ]] && REPLY=${head[1,7]}
    return 0
}

# Kaldığınız proje: bulunduğunuz projeden farklı, en son girilen -> REPLY
_ts_last_project() {
    emulate -L zsh
    local f=$_ts_wcache/projects p here=""
    _ts_git_root && here=$REPLY
    REPLY=""
    [[ -r $f ]] || return 1
    for p in "${(@f)$(<$f)}"; do
        [[ -n $p && $p != $here && -d $p ]] && { REPLY=$p; return 0; }
    done
    return 1
}

$_ts_resume() {
    emulate -L zsh
    _ts_last_project || { print -r -- "${_ts_wmsg[noresume]}"; return 1; }
    cd -- $REPLY
}

# --- Arka plan bilgisi ----------------------------------------------------
_ts_welcome_refresh() {
    emulate -L zsh
    local f=$_ts_wcache/welcome out="" n p
    local -a dirty fields
    [[ -d $_ts_wcache ]] || mkdir -p -- $_ts_wcache 2>/dev/null || return 0
    # apt-check sonucu stderr'e "güncellemeler;güvenlik" diye yazar
    local apt=${TS_APT_CHECK:-/usr/lib/update-notifier/apt-check}
    if [[ -x $apt ]]; then
        n=$($apt 2>&1 >/dev/null)
        [[ $n == <->\;<-> ]] && out+="updates=${n%%;*}"$'\n'
    fi
    # df -P: ikinci satırın beşinci alanı doluluk yüzdesi (Capacity)
    n=$(df -P -- $HOME 2>/dev/null)
    fields=(${=${${(f)n}[2]-}})
    n=${fields[5]-}
    n=${n%\%}
    [[ $n == <-> ]] && out+="disk=$n"$'\n'
    if [[ -r $_ts_wcache/projects ]]; then
        for p in "${(@f)$(<$_ts_wcache/projects)}"; do
            [[ -e $p/.git ]] || continue
            [[ -n $(git -C $p status --porcelain --untracked-files=no 2>/dev/null) ]] && dirty+=(${p:t})
        done
    fi
    out+="dirty=${(j:/:)dirty}"$'\n'
    print -rn -- $out >| $f.$$ 2>/dev/null && mv -f -- $f.$$ $f 2>/dev/null
}

# --- Kart -----------------------------------------------------------------
# Kişiliğe göre büyük/küçük harf: _ts_case normal|lower|upper METİN -> REPLY
# Türkçede i/İ ve ı/I ayrı harflerdir; yerel ayar Türkçe değilse zsh bunu bilmez.
_ts_case() {
    emulate -L zsh
    local I=$'\u0130' i=$'\u0131'   # noktalı büyük İ, noktasız küçük ı
    REPLY=$2
    case $1 in
        upper) [[ ${_ts_wmsg[lang]-} == tr ]] && REPLY=${REPLY//i/$I}; REPLY=${(U)REPLY} ;;
        lower) [[ ${_ts_wmsg[lang]-} == tr ]] && { REPLY=${REPLY//I/$i}; REPLY=${REPLY//$I/i}; }; REPLY=${(L)REPLY} ;;
    esac
}

# Kartın satırları -> reply ("tür|metin"; tür: warn err resume)
_ts_welcome_items() {
    emulate -L zsh -o extended_glob
    local -A info
    local l txt
    reply=()
    # Sayılar aritmetiğe girmeden önce denetlenir
    [[ -r $_ts_wcache/welcome ]] && for l in "${(@f)$(<$_ts_wcache/welcome)}"; do
        case $l in
            (updates|disk)=<->) info[${l%%=*}]=${l#*=} ;;
            dirty=*) info[dirty]=${l#dirty=} ;;
        esac
    done
    if (( ${info[updates]:-0} > 0 )); then
        printf -v txt "${_ts_wmsg[updates]}" ${info[updates]}
        reply+=("warn|$txt")
    fi
    [[ -e ${TS_REBOOT_FILE:-/var/run/reboot-required} ]] && reply+=("warn|${_ts_wmsg[reboot]}")
    if (( ${info[disk]:-0} >= 90 )); then
        printf -v txt "${_ts_wmsg[disk]}" ${info[disk]}
        reply+=("err|$txt")
    fi
    if [[ -n ${info[dirty]-} ]]; then
        local -a d=("${(@s:/:)info[dirty]}")
        local names=${(j:, :)d[1,2]}
        (( $#d > 2 )) && names+=" +$(( $#d - 2 ))"
        printf -v txt "${_ts_wmsg[dirty]}" $names
        reply+=("warn|$txt")
    fi
    if _ts_last_project; then
        local p=$REPLY
        _ts_branch $p
        reply+=("resume|${_ts_wmsg[resume]}: ${p:t}${REPLY:+ ($REPLY)}")
    fi
}

_ts_welcome() {
    emulate -L zsh
    [[ -z ${TMUX-} && ${TS_WELCOME-} != off ]] || return 0
    local -a items
    _ts_welcome_items
    items=("${reply[@]}")
    (( $#items )) || return 0

    local -A c=("${(@kv)_ts_card}")
    local -a marks=(${=c[marks]})
    local R=$'\e[0m' W=$(( COLUMNS - 2 < 72 ? COLUMNS - 2 : 72 ))
    local hour greet date title it kind txt mark cmd=$_ts_resume
    (( W >= 24 )) || return 0
    strftime -s hour '%H' $EPOCHSECONDS
    case $hour in
        0[5-9]|1[01]) greet=${_ts_wmsg[morning]} ;;
        1[2-7]) greet=${_ts_wmsg[day]} ;;
        1[89]|2[0-2]) greet=${_ts_wmsg[evening]} ;;
        *) greet=${_ts_wmsg[night]} ;;
    esac
    _ts_case ${c[tcase]} "$greet, ${(C)${USERNAME:-${USER-}}}"; title=$REPLY
    strftime -s date "${c[date]#+}" $EPOCHSECONDS
    _ts_case ${c[tcase]} "$date"; date=$REPLY

    # Satırlar: işaret, metin; sığmayan metin … ile kısaltılır. Büyük/küçük
    # harf yalnızca etikete uygulanır; proje ve dal adları olduğu gibi kalır.
    local -a plain col
    local max=$(( W - 4 )) extra
    for it in $items; do
        kind=${it%%|*} txt=${it#*|}
        if [[ $txt == *': '* ]]; then
            _ts_case ${c[xcase]} "${txt%%: *}"; txt="$REPLY: ${txt#*: }"
        else
            _ts_case ${c[xcase]} "$txt"; txt=$REPLY
        fi
        case $kind in err) mark=${marks[2]} ;; resume) mark=${marks[3]} ;; *) mark=${marks[1]} ;; esac
        extra=0
        [[ $kind == resume ]] && extra=$(( 3 + ${#cmd} ))
        (( ${#mark} + 1 + ${#txt} + extra > max )) && txt="${txt[1,max-${#mark}-2-extra]}…"
        if [[ $kind == resume ]]; then
            plain+=("$mark $txt — $cmd")
            col+=("${c[muted]}$mark$R ${c[text]}$txt$R ${c[muted]}—$R ${c[cmd]}$cmd$R")
        else
            plain+=("$mark $txt")
            col+=("${c[$kind]}$mark$R ${c[text]}$txt$R")
        fi
    done

    local i
    if [[ ${c[border]} == none ]]; then
        # Kenarsız kişilik: kutu yok, ince sol çizgi
        print -r -- "${c[frame]}▏$R ${c[title]}$title$R  ${c[muted]}$date$R"
        for (( i = 1; i <= $#col; i++ )); do print -r -- "${c[frame]}▏$R ${col[i]}"; done
        return 0
    fi

    local tl tr bl br h v
    case ${c[border]} in
        sharp) tl=┌ tr=┐ bl=└ br=┘ h=─ v=│ ;;
        heavy) tl=┏ tr=┓ bl=┗ br=┛ h=━ v=┃ ;;
        double) tl=╔ tr=╗ bl=╚ br=╝ h=═ v=║ ;;
        *) tl=╭ tr=╮ bl=╰ br=╯ h=─ v=│ ;;
    esac
    # Başlık kişiliğin segment biçimiyle; tp görünen metin, tc renkli hâli
    local tp tc
    case ${c[seg]} in
        brackets) tp="[ $title ]"; tc="${c[title]}$tp$R" ;;
        arrows) tp="${c[sep]} $title"; tc="${c[title]}$tp$R" ;;
        powerline) tp=" $title "$'\ue0b0'; tc="${c[tag]} $title $R${c[tagend]}"$'\ue0b0'"$R" ;;
        pills) tp=$'\ue0b6'" $title "$'\ue0b4'; tc="${c[tagend]}"$'\ue0b6'"$R${c[tag]} $title $R${c[tagend]}"$'\ue0b4'"$R" ;;
        *) tp=$title; tc="${c[title]}$title$R" ;;
    esac
    # Üst satır: köşe ─ başlık ─── tarih ─ köşe (genişlik W). Sığmazsa önce
    # tarih düşer, sonra başlık sade hâliyle kısaltılır.
    local fill=$(( W - ${#tp} - ${#date} - 8 ))
    if (( fill < 1 )); then
        date=""
        fill=$(( W - ${#tp} - 5 ))
        if (( fill < 1 )); then
            tp="${title[1,W-7]}…"; tc="${c[title]}$tp$R"
            fill=$(( W - ${#tp} - 5 ))
        fi
    fi
    if [[ -n $date ]]; then
        print -r -- "${c[frame]}$tl$h$R $tc ${c[frame]}${(pl:fill::$h:)}$R ${c[muted]}$date$R ${c[frame]}$h$tr$R"
    else
        print -r -- "${c[frame]}$tl$h$R $tc ${c[frame]}${(pl:fill::$h:)}$tr$R"
    fi
    for (( i = 1; i <= $#col; i++ )); do
        print -r -- "${c[frame]}$v$R ${col[i]}${(l:W-3-${#plain[i]}:)}${c[frame]}$v$R"
    done
    print -r -- "${c[frame]}$bl${(pl:W-2::$h:)}$br$R"
}

# İlk istemde bir kez: kartı çiz, önbellek bir saatten eskiyse arka planda yenile
_ts_welcome_precmd() {
    emulate -L zsh
    add-zsh-hook -d precmd _ts_welcome_precmd
    _ts_welcome
    local -a st
    if [[ ! -r $_ts_wcache/welcome ]] || { zstat -A st +mtime -- $_ts_wcache/welcome 2>/dev/null &&
        (( EPOCHSECONDS - st[1] > 3600 )); }; then
        ( _ts_welcome_refresh ) &!
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _ts_project_seen
add-zsh-hook precmd _ts_welcome_precmd
_ts_project_seen
