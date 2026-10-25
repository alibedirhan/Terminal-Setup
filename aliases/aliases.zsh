# Navigasyon
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Sık kullanılanlar
alias c='clear'
alias h='history'
alias grep='grep --color=auto'
alias update='sudo apt update && sudo apt upgrade'

# Güvenli dosya işlemleri (üzerine yazmadan önce sorar)
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias mkdir='mkdir -pv'

# Git
alias gst='git status'
alias gco='git checkout'
alias glg='git log --oneline --graph --all'
alias gp='git pull'
alias gph='git push'
alias gundo='git reset --soft HEAD~1'

# Dosya ve disk
alias ffind='find . -type f -name'
alias recent='ls -lt | head'
alias dfh='df -h -x tmpfs -x devtmpfs'
alias dusage='du -sh * 2>/dev/null | sort -rh | head -n 10'
alias untar='tar -xvf'

# Ağ
alias myip='curl -s https://ifconfig.me; echo'
alias ports='ss -tulpn'
alias pingg='ping -c 4 google.com'
