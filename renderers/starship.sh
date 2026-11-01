#!/usr/bin/env bash
# ============================================================================
# Renderer: Starship prompt'u
# ============================================================================
# Starship'in ayar dosyası (~/.config/terminal-setup/starship.toml) temanın
# renk rollerinden ve kişiliğinden üretilir; tema ya da kişilik değişince
# yeniden yazılır. Kullanıcının ~/.config/starship.toml dosyasına dokunulmaz:
# Starship bizim dosyamızı STARSHIP_CONFIG ile okur.
#
# Kişiliğin SEGMENTS değeri prompt'un biçimini belirler:
#   plain      dizin "on" dal ●2        (modern)
#   minimal    dizin dal ~2, tek satır  (arctic)
#   powerline  dolgu etiketler ve ok    (vivid)
#   pills      hap etiketler            (soft)
#   brackets   [dizin] [dal*]           (retro)
#   arrows     dizin ▸ dal              (neon)
# Nerd Font karakterleri dosyaya TOML kaçışı (\ue0b0) olarak yazılır: önce
# yer tutucu (@PL@), kaçırma bittikten sonra kaçış dizisi.
# ============================================================================

renderer_register starship "Starship" tool

STARSHIP_CONFIG_FILE="$TS_CONFIG_DIR/starship.toml"

rend_starship_available() {
    [[ -f "$TS_CONFIG_DIR/zsh.d/90-starship.zsh" ]]
}

rend_starship_apply() {
    starship_config
    act_write_file "$STARSHIP_CONFIG_FILE" "$REPLY"
}

# Starship biçim metninde özel karakterleri kaçır: $ [ ] ( ) \ -> REPLY
_starship_escape() {
    local s="$1" out="" c i
    for ((i = 0; i < ${#s}; i++)); do
        c="${s:i:1}"
        case "$c" in
            '$' | '[' | ']' | '(' | ')' | '\') out+="\\$c" ;;
            *) out+="$c" ;;
        esac
    done
    REPLY="$out"
}

# TOML temel dizgesi: \ ve " kaçırılır -> REPLY
_starship_toml() {
    REPLY="${1//\\/\\\\}"
    REPLY="${REPLY//\"/\\\"}"
}

# Ayar dosyasının içeriği -> REPLY. Tema yüklüyse (ROLE dolu) renkler
# paletten, değilse terminalin kendi 16 renginin adlarından gelir.
starship_config() {
    local -A c
    local palette=0 seg layout sym sep lang fmt dir br gs ds bs gst
    local stg mod unt cfl key br_fmt
    if [[ -n "${ROLE[accent]:-}" ]]; then
        palette=1
        for key in bg fg accent accent2 info ok warn err muted; do c[$key]="$key"; done
    else
        c=([bg]=black [fg]=bold [accent]=blue [accent2]=purple [info]=cyan
            [ok]=green [warn]=yellow [err]=red [muted]=bright-black)
    fi
    seg="${STYLE[SEGMENTS]:-plain}" layout="${STYLE[PROMPT_LAYOUT]:-two-line}"
    _starship_escape "${STYLE[PROMPT_SYMBOL]:-❯}"; sym="$REPLY"
    _starship_escape "${STYLE[SEPARATOR]:-·}"; sep="$REPLY"
    lang='$python$nodejs$rust$golang'

    case "${STYLE[GIT_SYMBOLS]:-unicode}" in
        ascii)   stg='+' mod='*' unt='?' cfl='!' ;;
        minimal) stg='+$count ' mod='~$count ' unt='…$count ' cfl='!$count ' ;;
        *)       stg='✚$count ' mod='●$count ' unt='?$count ' cfl='✖$count ' ;;
    esac
    gs='$conflicted$staged$modified$untracked$ahead_behind'

    case "$seg" in
        minimal)
            fmt="\$directory\$git_branch\$git_status$lang\$cmd_duration"
            dir='[$path]($style) ' ds="${c[accent]}"
            br_fmt='[$branch]($style) ' bs="${c[accent2]}"
            gs="([$gs](\$style) )" gst="${c[muted]}" ;;
        powerline)
            fmt="\$directory\$git_branch\$git_status$lang\$cmd_duration"
            dir="[ \$path ](\$style)[@PL@](fg:${c[accent]}) " ds="bold bg:${c[accent]} fg:${c[bg]}"
            br_fmt='[ $symbol$branch ]($style)' bs="bold bg:${c[accent2]} fg:${c[bg]}"
            gs="([$gs ](\$style))[@PL@](fg:${c[accent2]}) " gst="bold bg:${c[accent2]} fg:${c[bg]}" ;;
        pills)
            fmt="\$directory\$git_branch\$git_status$lang\$cmd_duration"
            dir="[@PILL_L@](fg:${c[accent]})[ \$path](\$style)[@PILL_R@](fg:${c[accent]}) " ds="bg:${c[accent]} fg:${c[bg]}"
            br_fmt="[@PILL_L@](fg:${c[accent2]})[\$symbol\$branch](\$style)" bs="bg:${c[accent2]} fg:${c[bg]}"
            gs="([ $gs](\$style))[@PILL_R@](fg:${c[accent2]}) " gst="bg:${c[accent2]} fg:${c[bg]}" ;;
        brackets)
            fmt="[\\[](${c[fg]})\$directory[\\]](${c[fg]})( [\\[](${c[fg]})\$git_branch\$git_status[\\]](${c[fg]})) $lang\$cmd_duration"
            dir='[$path]($style)' ds="bold ${c[warn]}"
            br_fmt='[$branch]($style)' bs="bold ${c[ok]}"
            gs='([$conflicted$staged$modified$untracked]($style))' gst="bold ${c[err]}" ;;
        arrows)
            fmt="\$directory([$sep](${c[accent2]}) \$git_branch\$git_status)$lang\$cmd_duration"
            dir='[$path]($style) ' ds="bold ${c[accent]}"
            br_fmt='[$symbol$branch]($style) ' bs="bold ${c[accent2]}"
            gs="([$gs](\$style) )" gst="${c[info]}" ;;
        *)
            fmt="\$directory\$git_branch\$git_status$lang\$cmd_duration"
            dir='[$path]($style)[$read_only]($read_only_style) ' ds="bold ${c[accent]}"
            br_fmt="[on](${c[muted]}) [\$symbol\$branch](\$style) " bs="bold ${c[accent2]}"
            gs="([$gs](\$style) )" gst="${c[warn]}" ;;
    esac
    [[ "$layout" == two-line ]] && fmt+='$line_break'
    fmt+='$character'

    local out
    style_file_header
    out="$REPLY
add_newline = true"
    ((palette)) && out+=$'\n''palette = "terminal_setup"'
    _starship_toml "$fmt"; out+=$'\n'"format = \"$REPLY\""
    out+=$'\n''right_format = "$status"'
    if ((palette)); then
        out+=$'\n\n''[palettes.terminal_setup]'
        for key in bg fg accent accent2 info ok warn err muted; do
            out+=$'\n'"$key = \"${ROLE[$key]}\""
        done
    fi
    _starship_toml "$dir"; dir="$REPLY"
    _starship_toml "$br_fmt"; br="$REPLY"
    _starship_toml "$gs"; gs="$REPLY"
    _starship_toml "$sep"; sep="$REPLY"
    _starship_toml "$sym"; sym="$REPLY"
    out+="

[directory]
style = \"$ds\"
truncation_length = 3
truncation_symbol = \"…/\"
format = \"$dir\"

[git_branch]
symbol = \"\\ue0a0 \"
truncation_length = 24
truncation_symbol = \"…\"
style = \"$bs\"
format = \"$br\"

[git_status]
style = \"$gst\"
format = \"$gs\"
staged = \"$stg\"
modified = \"$mod\"
untracked = \"$unt\"
conflicted = \"$cfl\"
ahead = \"⇡\$count \"
behind = \"⇣\$count \"
diverged = \"⇡\$ahead_count⇣\$behind_count \"

[python]
format = \"[via](${c[muted]}) [py \$version( \\\\(\$virtualenv\\\\))](\$style) \"
style = \"${c[warn]}\"

[nodejs]
format = \"[via](${c[muted]}) [node \$version](\$style) \"
style = \"${c[ok]}\"

[rust]
format = \"[via](${c[muted]}) [rust \$version](\$style) \"
style = \"${c[err]}\"

[golang]
format = \"[via](${c[muted]}) [go \$version](\$style) \"
style = \"${c[info]}\"

[cmd_duration]
min_time = 2000
style = \"${c[warn]}\"
format = \"[$sep](${c[muted]}) [\$duration](\$style) \"

[character]
success_symbol = \"[$sym](bold ${c[ok]})\"
error_symbol = \"[$sym](bold ${c[err]})\"

[status]
disabled = false
style = \"${c[err]}\"
format = \"[✘ \$status](\$style)\""
    # Yer tutucular en sonda TOML Unicode kaçışına çevrilir (kaçırma onları bozmasın)
    local pl="\\ue0b0" pill_l="\\ue0b6" pill_r="\\ue0b4"
    out="${out//@PL@/$pl}"
    out="${out//@PILL_L@/$pill_l}"
    REPLY="${out//@PILL_R@/$pill_r}"
}
