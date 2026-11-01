#!/usr/bin/env zsh
# ============================================================================
# Uçtan uca: kişilikten üretilen araç ayarları gerçek araçlarda hatasız mı?
# tests/e2e/container.sh her kişilik için kullanıcı olarak çalıştırır:
#   zsh -f tests/e2e/tool_styles.zsh
# Hata kodu hangi aracın düştüğünü söyler; araçların hata çıktısı ekrana gelir.
# ============================================================================
emulate -L zsh
setopt no_unset extended_glob

local d=$HOME/.config/terminal-setup err=${TMPDIR:-/tmp}/tool-styles.$$.err repo
path=($HOME/.local/bin $path)
source $d/zsh.d/60-eza.zsh
source $d/zsh.d/65-theme-lazygit.zsh
source $d/zsh.d/65-theme-tools.zsh

# Hata çıktısı boş olmalı: araçlar bilmedikleri değeri çoğu zaman uyarıyla geçer
quiet() {
    "$@" > /dev/null 2> $err || { cat $err; return 1; }
    [[ ! -s $err ]] || { cat $err; return 1; }
}

# eza: takma ad kişiliğin simge ve tarih seçeneklerini taşır
quiet eval 'll /etc' || exit 11
# bat: BAT_STYLE ortamdan okunur
quiet batcat --paging=never --color=always /etc/hostname || exit 12
# tmux: temel ayar ve tema dosyası ayrı adlı bir sunucuya yüklenir (açık oturumlara dokunmaz)
quiet tmux -L ts-e2e -f /dev/null new-session -d \; source-file $d/tmux.conf \; \
    source-file $d/tmux-theme.conf || { tmux -L ts-e2e kill-server 2> /dev/null; exit 13; }
tmux -L ts-e2e kill-server 2> /dev/null
# lazygit: ayar hatasında hemen çıkar (1); sağlıklı açılış zaman aşımıyla biter (124)
[[ ${LG_CONFIG_FILE-} == $d/lazygit.yml* ]] || exit 14
repo=$(mktemp -d)
git -C $repo init -q
TERM=xterm-256color script -qec "timeout 5 lazygit -p $repo" /dev/null > $err 2>&1
(( $? == 124 )) || { tr -d '\033' < $err | tail -5; exit 15; }
# Karşılama kartı: arka plan yenilemesi gerçek apt-check, df ve git ile;
# kart hatasız çizilir ve her satırı aynı genişlikte (kenarsız kişilik hariç)
local cache=${XDG_CACHE_HOME:-$HOME/.cache}/terminal-setup card
mkdir -p $cache && print -r -- $repo > $cache/projects || exit 16
source $d/zsh.d/65-theme-welcome.zsh
source $d/zsh.d/96-welcome.zsh
quiet _ts_welcome_refresh || exit 16
grep -q '^disk=[0-9]' $cache/welcome || exit 16
card=$(COLUMNS=80 _ts_welcome 2> $err)
[[ ! -s $err && -n $card ]] || { cat $err; exit 17; }
# Genişlik zsh'le, karakter olarak ölçülür (kapsayıcının awk'ı mawk: bayt sayar)
if [[ ${_ts_card[border]} != none ]]; then
    () {
        local LC_ALL=C.UTF-8 line
        local -A w
        for line in "${(@f)${card//$'\e'\[[0-9;]#m/}}"; do w[${#line}]=1; done
        (( ${#w} == 1 ))
    } || { print -r -- $card; exit 17; }
fi
# Komut paleti: seçenekleri gerçek fzf kabul eder, Makefile hedefi bulunur
print 'test:' > $repo/Makefile
source $d/zsh.d/97-palette.zsh
( cd $repo && _ts_palette_items && print -rl -- $reply | _ts_palette_fzf --filter='make test' ) > $err.pal 2> $err ||
    { cat $err; exit 18; }
[[ ! -s $err ]] && grep -q $'\tmake test$' $err.pal || { cat $err $err.pal; exit 18; }
# Alt+H: gerçek tldr istemcisinin (22.04 tldr-hs, sonrası tealdeer) çıktısı
# okunur: açıklama ve en az bir örnek, renk kodu kalmadan. Sayfa önbelleği
# indirilemediyse (ağ) denetim uyarıyla atlanır.
source $d/zsh.d/61-tldr-help.zsh
if tldr tar > /dev/null 2>&1; then
    _ts_help_page tar || { tldr tar | head -20; exit 19; }
    (( $#reply >= 3 )) && [[ $reply != *$'\e'* && ${reply[3]} == tar* ]] ||
        { print -rl -- $reply; tldr tar | head -20; exit 19; }
else
    print -u2 "uyarı: tldr sayfaları yok; Alt+H denetimi atlandı"
fi
rm -rf $repo $err $err.pal
