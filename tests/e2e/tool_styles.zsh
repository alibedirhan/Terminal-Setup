#!/usr/bin/env zsh
# ============================================================================
# Uçtan uca: kişilikten üretilen araç ayarları gerçek araçlarda hatasız mı?
# tests/e2e/container.sh her kişilik için kullanıcı olarak çalıştırır:
#   zsh -f tests/e2e/tool_styles.zsh
# Hata kodu hangi aracın düştüğünü söyler; araçların hata çıktısı ekrana gelir.
# ============================================================================
emulate -L zsh
setopt no_unset

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
rm -rf $repo $err
