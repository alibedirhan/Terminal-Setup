# Terminal Setup — komut paleti (Ctrl+Space)
# Bulunduğunuz projede çalıştırabileceklerinizi tek listede gösterir:
# betikler (package.json, Makefile, justfile), testler, Python sanal ortamı,
# git ve son kullandığınız komutlar. Seçtiğiniz komut çalıştırılmaz, komut
# satırına yazılır; Enter'a siz basarsınız. Liste fzf ile süzülür; renkler
# ve kenar temadan gelir (FZF_DEFAULT_OPTS).

# Projenin kökü: git kökü, yoksa bulunulan dizin -> REPLY
_ts_pal_root() {
    emulate -L zsh
    local d=$PWD
    while [[ -n $d && $d != / ]]; do
        [[ -e $d/.git ]] && { REPLY=$d; return 0; }
        d=${d:h}
    done
    REPLY=$PWD
}

# package.json'daki "scripts" anahtarları -> reply (jq gerekmez; satır satır)
_ts_pal_npm_scripts() {
    emulate -L zsh -o extended_glob
    local l in=0
    reply=()
    [[ -r $1 ]] || return 0
    for l in "${(@f)$(<$1)}"; do
        if (( ! in )); then
            [[ $l == [[:space:]]#\"scripts\"[[:space:]]#:[[:space:]]#\{* ]] && in=1
            continue
        fi
        [[ $l == [[:space:]]#\}* ]] && break
        [[ $l == (#b)[[:space:]]#\"([^\"]##)\"[[:space:]]#:* ]] && reply+=($match[1])
    done
}

# Bir dosyadaki hedef adları: _ts_pal_targets DOSYA DESEN -> reply (tekrarsız)
# make için "ad:" (değişken ataması ve .ÖZEL hedefler hariç), just için "ad argümanlar:"
_ts_pal_targets() {
    emulate -L zsh -o extended_glob
    local l
    reply=()
    for l in "${(@f)$(<$1)}"; do
        [[ $l == (#b)${~2} ]] && reply+=($match[1])
    done
    reply=(${(u)reply})
}

# Satır ekle: _ts_pal_add TÜR KOMUT [NEREDEN] (çağıranın rows dizisine:
# "görünen satır<TAB>komut")
_ts_pal_add() { rows+=("${(r:8:)1} $2${3:+  · $3}"$'\t'"$2"); }

# Paletin satırları -> reply
_ts_palette_items() {
    emulate -L zsh -o extended_glob
    _ts_pal_root
    local root=$REPLY f s pm=npm
    local -a rows py

    if [[ -r $root/package.json ]]; then
        [[ -e $root/pnpm-lock.yaml ]] && pm=pnpm
        [[ -e $root/yarn.lock ]] && pm=yarn
        [[ -e $root/bun.lockb || -e $root/bun.lock ]] && pm=bun
        _ts_pal_npm_scripts $root/package.json
        for s in $reply; do _ts_pal_add ${_ts_pmsg[script]} "$pm run $s" package.json; done
    fi
    for f in $root/(GNUmakefile|makefile|Makefile)(N[1]); do
        _ts_pal_targets $f '([A-Za-z0-9][A-Za-z0-9_.-]#):([^=]*|)'
        for s in $reply; do _ts_pal_add ${_ts_pmsg[script]} "make $s" ${f:t}; done
    done
    for f in $root/(justfile|Justfile|.justfile)(N[1]); do
        _ts_pal_targets $f '([A-Za-z0-9][A-Za-z0-9_-]#)([[:space:]][^:=]#|):([^=]*|)'
        for s in $reply; do _ts_pal_add ${_ts_pmsg[script]} "just $s" ${f:t}; done
    done
    if [[ -r $root/Cargo.toml ]]; then
        _ts_pal_add ${_ts_pmsg[test]} "cargo test" Cargo.toml
        _ts_pal_add ${_ts_pmsg[script]} "cargo run" Cargo.toml
    fi
    [[ -r $root/go.mod ]] && _ts_pal_add ${_ts_pmsg[test]} "go test ./..." go.mod
    py=($root/tests/test_*.py(N[1]))
    if [[ -r $root/pytest.ini || -r $root/tox.ini || -r $root/pyproject.toml ]] || (( $#py )); then
        _ts_pal_add ${_ts_pmsg[test]} "python3 -m pytest"
    fi
    # Python sanal ortamı: açıksa kapat, değilse projedekini aç
    if [[ -n ${VIRTUAL_ENV-} ]]; then
        _ts_pal_add ${_ts_pmsg[env]} deactivate ${VIRTUAL_ENV:t}
    else
        for f in $root/(.venv|venv|env)/bin/activate(N); do
            _ts_pal_add ${_ts_pmsg[env]} "source ${f#$PWD/}" ${_ts_pmsg[venv]}
        done
    fi
    if [[ -e $root/.git ]]; then
        for s in "git status" "git pull --rebase" "git push" "git log --oneline --graph -20"; do
            _ts_pal_add git $s
        done
        (( $+commands[lazygit] )) && _ts_pal_add git lazygit
    fi
    # Son kullanılanlar: geçmişten, tekrarsız ve en yenisi önce (en çok 15)
    local -A seen
    local n=0
    for s in "${(@f)$(fc -lnr -200 2>/dev/null)}"; do
        s=${s##[[:space:]]#}
        [[ -z $s || -n ${seen[$s]-} ]] && continue
        seen[$s]=1
        _ts_pal_add ${_ts_pmsg[recent]} $s
        (( ++n >= 15 )) && break
    done
    reply=($rows)
}

# fzf'i paletin seçenekleriyle çalıştır (uçtan uca test --filter ile çağırır)
_ts_palette_fzf() {
    fzf --height=40% --reverse --delimiter=$'\t' --with-nth=1 --header="${_ts_pmsg[header]}" "$@"
}

# Ctrl+Space: listeyi fzf'te aç, seçilen komutu satıra yaz
_ts_palette() {
    emulate -L zsh
    local pick
    _ts_palette_items
    if (( ! $#reply )); then
        zle -M "${_ts_pmsg[empty]}"
        return 0
    fi
    pick=$(print -rl -- $reply | _ts_palette_fzf 2>/dev/null)
    zle reset-prompt
    [[ -n $pick ]] || return 0
    BUFFER=${pick#*$'\t'}
    CURSOR=$#BUFFER
}

zle -N _ts_palette
bindkey -M emacs '^@' _ts_palette
bindkey -M viins '^@' _ts_palette
