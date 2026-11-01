# Terminal Setup — Alt+H: yazdığınız komutun kısa yardımı
# Komut satırındaki komutun tldr sayfasından açıklama ve ilk dört örnek
# istemin üstüne yazılır; yazdığınız satır olduğu gibi kalır. Sayfa sistem
# dilinde aranır, yoksa İngilizcesi gösterilir. tldr-hs (Ubuntu 22.04) ve
# tealdeer'in çıktıları aynı biçimde okunur.

# tldr çıktısını oku: _ts_help_parse KOMUT < çıktı -> reply
#   reply[1] açıklama, ardından (örnek açıklaması, örnek komut) çiftleri
# İlk boş satıra kadar açıklamadır (başlık ve bağlantı satırları hariç);
# sonra ":" ile biten açıklama ve onu izleyen komut satırı sırayla gelir.
_ts_help_parse() {
    emulate -L zsh -o extended_glob
    local cmd=$1 l t desc="" state=desc pending=""
    local -a ex
    while IFS= read -r l; do
        t=${l//$'\e'\[[0-9;]#m/}
        t=${${t##[[:space:]]#}%%[[:space:]]#}
        if [[ -z $t ]]; then
            [[ $state == desc && -n $desc ]] && state=ex
            continue
        fi
        if [[ $state == desc ]]; then
            [[ $t == $cmd || $t == *://* ]] || desc+=${desc:+ }$t
            continue
        fi
        if [[ -z $pending ]]; then
            pending=${${t#- }%:}
        else
            ex+=("$pending" "$t")
            pending=""
        fi
    done
    reply=("$desc" "${ex[@]}")
}

# KOMUT'un yardımı -> reply (sayfa yoksa 1 döner)
_ts_help_page() {
    emulate -L zsh
    local out=""
    reply=()
    (( $+commands[tldr] )) || return 1
    [[ ${_ts_hmsg[lang]-en} != en ]] && out=$(tldr -L ${_ts_hmsg[lang]} -- $1 2>/dev/null)
    [[ -n $out ]] || out=$(tldr -- $1 2>/dev/null)
    [[ -n $out ]] || return 1
    _ts_help_parse $1 <<< $out
    [[ -n ${reply[1]} ]]
}

# Komut satırındaki asıl komut: sudo, env gibi önekler ve AD=değer atamaları
# atlandıktan sonraki ilk kelime -> REPLY
_ts_help_command() {
    emulate -L zsh -o extended_glob
    local -a words=(${(z)1})
    while (( $#words > 1 )) &&
        [[ ${words[1]} == (sudo|env|nohup|time|command|builtin|exec|nice|noglob|[A-Za-z_][A-Za-z0-9_]#=*) ]]; do
        shift words
    done
    REPLY=${words[1]-}
}

# Alt+H
_ts_help() {
    emulate -L zsh
    # Kısaltma karakterle yapılsın (C/POSIX yerel ayarında bayt ortadan bölünürdü)
    local LC_ALL=C.UTF-8
    local cmd i n=0 R=$'\e[0m' B=$'\e[1m' D=$'\e[2m' G=$'\e[32m' max=$(( COLUMNS - 4 ))
    _ts_help_command "$BUFFER"
    cmd=$REPLY
    [[ -n $cmd ]] || return 0
    zle -I
    if ! _ts_help_page $cmd; then
        local msg
        printf -v msg "${_ts_hmsg[none]}" $cmd
        print -r -- "  $D$msg$R"
        return 0
    fi
    local -a page=("${reply[@]}")
    local d=${page[1]}
    (( ${#d} > max - ${#cmd} - 3 )) && d="${d[1,max-${#cmd}-4]}…"
    print -r -- "  $B$cmd$R $D—$R $d"
    for (( i = 2; i < $#page && n < 4; i += 2, n++ )); do
        print -r -- "  $D•$R ${page[i][1,max-2]}"
        print -r -- "    $G${page[i+1][1,max-2]}$R"
    done
}

zle -N _ts_help
bindkey -M emacs '^[h' _ts_help
bindkey -M emacs '^[H' _ts_help
bindkey -M viins '^[h' _ts_help
