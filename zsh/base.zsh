# Terminal Setup — zsh temeli (Oh My Zsh gerekmez)
# Oh My Zsh'in sessizce sağladığı varsayılanların özü: geçmiş, dizinler,
# tamamlama, tuşlar, pencere başlığı ve OSC 7. Kendi ayarlarınızı ~/.zshrc
# içinde, terminal-setup bloğunun altına yazın; onlar bunları ezer.

# --- Geçmiş ----------------------------------------------------------------
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=50000
SAVEHIST=10000
setopt extended_history hist_expire_dups_first hist_ignore_dups hist_ignore_space
setopt hist_verify share_history

# --- Dizinler ve kabuk davranışı -------------------------------------------
setopt auto_cd auto_pushd pushd_ignore_dups pushd_minus
setopt interactive_comments long_list_jobs multios
unsetopt flow_control                      # Ctrl+S/Ctrl+Q terminali dondurmasın

# --- Tamamlama ---------------------------------------------------------------
# Önbellek: günde bir kez tam denetim, diğer açılışlarda hızlı yol (-C)
_ts_cache="${XDG_CACHE_HOME:-$HOME/.cache}/terminal-setup"
[[ -d $_ts_cache ]] || mkdir -p "$_ts_cache"
autoload -Uz compinit
_ts_dump=("$_ts_cache/zcompdump-$ZSH_VERSION"(N.mh-24))
if (( $#_ts_dump )); then
    compinit -C -d "$_ts_cache/zcompdump-$ZSH_VERSION"
else
    compinit -d "$_ts_cache/zcompdump-$ZSH_VERSION"
fi
unset _ts_dump

setopt auto_menu complete_in_word always_to_end
unsetopt menu_complete
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$_ts_cache/zcompcache"

# ls ve tamamlama renkleri (tema uygulanınca araç parçası bunları değiştirir)
if [[ -z $LS_COLORS ]] && (( $+commands[dircolors] )); then
    eval "$(dircolors -b)"
fi
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
alias ls='ls --color=auto'                 # eza kuruluysa onun parçası bunu ezer
alias grep='grep --color=auto'

# --- Tuşlar ------------------------------------------------------------------
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line
bindkey '^[[A' up-line-or-beginning-search     # ↑ yazılanla başlayan eski komut
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
bindkey '^[[H' beginning-of-line;  bindkey '^[OH' beginning-of-line
bindkey '^[[F' end-of-line;        bindkey '^[OF' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word;    bindkey '^[[1;5D' backward-word
bindkey '^[[Z' reverse-menu-complete           # Shift+Tab
bindkey '^X^E' edit-command-line               # komutu düzenleyicide aç

# --- Pencere başlığı ve OSC 7 --------------------------------------------------
autoload -Uz add-zsh-hook
if [[ $TERM == (xterm*|*-256color|alacritty|foot*|kitty*|wezterm|ghostty|tmux*|screen*) ]]; then
    _ts_title_precmd() { print -Pn '\e]0;%~\a' }
    _ts_title_preexec() { print -n '\e]0;'; print -rn -- "${1[1,60]}"; print -n '\a' }
    add-zsh-hook precmd _ts_title_precmd
    add-zsh-hook preexec _ts_title_preexec

    # OSC 7: bulunulan dizini terminale bildirir; yeni sekme aynı dizinde açılır.
    # Yol, URL kurallarına göre UTF-8 baytları üzerinden kodlanır (é -> %C3%A9).
    _ts_osc7() {
        emulate -L zsh
        local LC_ALL=C url="" c i hex
        for (( i = 1; i <= ${#PWD}; i++ )); do
            c=${PWD[i]}
            if [[ $c == [a-zA-Z0-9/._~-] ]]; then
                url+=$c
            else
                printf -v hex '%%%02X' "'$c"
                url+=$hex
            fi
        done
        print -n "\e]7;file://${HOST}${url}\a"
    }
    add-zsh-hook chpwd _ts_osc7
    _ts_osc7
fi
