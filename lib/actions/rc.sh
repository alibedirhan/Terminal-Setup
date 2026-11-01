#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Eylem: kullanıcı ayar dosyalarına yönetilen blok
# ============================================================================
# ~/.zshrc, ~/.tmux.conf, kitty.conf gibi kullanıcı dosyalarına dağınık satır
# eklenmez. Her bileşen kendi işaretli bloğunu ekler:
#
#   # >>> terminal-setup:zsh >>>
#   ...
#   # <<< terminal-setup:zsh <<<
#
# Dosyaya ilk dokunuşta orijinali kopyalanır ("rcfile" kaydı). Dosyada hiçbir
# blok kalmadığında orijinal geri konur; kurulumdan sonra kullanıcının
# yaptığı başka değişiklikler varsa önce arşive kopyalanır (lib/undo.sh).
# ============================================================================

rc_marker_begin() { printf '# >>> terminal-setup:%s >>>' "$1"; }
rc_marker_end() { printf '# <<< terminal-setup:%s <<<' "$1"; }

rc_has_block() {
    [[ -f "$1" ]] && grep -qxF "$(rc_marker_begin "$2")" "$1"
}

# Bloğun mevcut içeriği (işaretler hariç)
rc_block_content() {
    local file="$1" id="$2"
    awk -v b="$(rc_marker_begin "$id")" -v e="$(rc_marker_end "$id")" '
        $0 == b { inside=1; next }
        $0 == e { inside=0; next }
        inside { print }' "$file"
}

# Bloğu dosyadan çıkar (diğer her bayta dokunmadan)
rc_strip_block() {
    local file="$1" id="$2" tmp
    [[ -f "$file" ]] || return 0
    tmp="$file.ts-tmp"
    awk -v b="$(rc_marker_begin "$id")" -v e="$(rc_marker_end "$id")" '
        $0 == b { inside=1; next }
        $0 == e { inside=0; next }
        !inside { print }' "$file" > "$tmp" && cat "$tmp" > "$file" && rm -f "$tmp"
}

# Dosyadaki tüm terminal-setup bloklarını çıkarılmış hali stdout'a yaz
rc_without_blocks() {
    awk '
        /^# >>> terminal-setup:[^ ]+ >>>$/ { inside=1; next }
        /^# <<< terminal-setup:[^ ]+ <<<$/ { inside=0; next }
        !inside { print }' "$1"
}

# Dosyanın orijinalini sakla (dosya başına bir kez). Sahibi "core"dur:
# bileşen tek başına kaldırıldığında orijinal geri yüklenmez, dosyadaki
# son blok kalktığında yüklenir.
act_snapshot() {
    local file="$1" saved owner="$TS_CURRENT_COMPONENT"
    ledger_has rcfile "$file" && return 0
    is_dry_run && return 0
    TS_CURRENT_COMPONENT="core"
    if [[ -f "$file" ]]; then
        mkdir -p "$TS_FILES_DIR" || { TS_CURRENT_COMPONENT="$owner"; return 1; }
        saved="$(ledger_count)-$(basename "$file")"
        cp -p "$file" "$TS_FILES_DIR/$saved" || { TS_CURRENT_COMPONENT="$owner"; return 1; }
        ledger_add rcfile "$file" "$saved" || { TS_CURRENT_COMPONENT="$owner"; return 1; }
    else
        ledger_add rcfile "$file" "NONE" || { TS_CURRENT_COMPONENT="$owner"; return 1; }
    fi
    TS_CURRENT_COMPONENT="$owner"
}

# Blok ekle/güncelle: act_rc_block DOSYA KİMLİK İÇERİK [top|bottom]
act_rc_block() {
    local file="$1" id="$2" content="$3" where="${4:-bottom}" tmp
    # Bloktaki açıklama sistem dilinde (dil değişince blok yenilenir)
    i18n_comments '#' "$content"; content="$REPLY"

    if rc_has_block "$file" "$id" && [[ "$(rc_block_content "$file" "$id")" == "$content" ]]; then
        _rc_record_block "$file" "$id"
        return 0
    fi
    if is_dry_run; then
        log_plan "%s içine '%s' bloğu" "$(ts_pretty_path "$file")" "$id"
        return 0
    fi

    act_snapshot "$file" || return 1
    act_mkdir "$(dirname "$file")" || return 1
    [[ -f "$file" ]] || { : > "$file" || return 1; }
    rc_strip_block "$file" "$id" || return 1

    tmp="$file.ts-tmp"
    {
        if [[ "$where" == "top" ]]; then
            rc_marker_begin "$id"; echo
            printf '%s\n' "$content"
            rc_marker_end "$id"; echo
            cat "$file"
        else
            cat "$file"
            # Dosya yeni satırla bitmiyorsa blok ayrı satırda başlasın
            [[ -s "$file" && -n "$(tail -c1 "$file")" ]] && echo
            rc_marker_begin "$id"; echo
            printf '%s\n' "$content"
            rc_marker_end "$id"; echo
        fi
    } > "$tmp" && cat "$tmp" > "$file" && rm -f "$tmp" || return 1

    _rc_record_block "$file" "$id"
}

# rcblock kaydını (bileşen, dosya, kimlik) üçlüsü için bir kez yaz
_rc_record_block() {
    local entry
    is_dry_run && return 0
    entry=$(printf '%s\t%s\t%s\t%s' "$TS_CURRENT_COMPONENT" rcblock "$1" "$2")
    ledger_lines | grep -xF -- "$entry" >/dev/null && return 0
    ledger_init && printf '%s\n' "$entry" >> "$TS_LEDGER"
}

# Zsh parçası: ~/.config/terminal-setup/zsh.d/SIRA-AD.zsh
#   act_zsh_snippet 60 zoxide 'eval "$(zoxide init zsh)"'
act_zsh_snippet() {
    local order="$1" name="$2" content="$3"
    _t "%s — Terminal Setup tarafından yönetilir" "$name"
    act_write_file "$TS_CONFIG_DIR/zsh.d/$order-$name.zsh" "# $TR"$'\n'"$content"
}

# Parçalar ~/.zshrc'nin başında yüklenir. Oh My Zsh'i kullanıcının kendi
# satırları sonradan yüklüyorsa plugins=(...) bizim eklentilerimizi listeden
# düşürür ve key-bindings.zsh Ctrl+R'yi düz aramaya geri bağlar. Aşağıdaki
# iki üretici, .zshrc bittikten sonra (ilk istemde bir kez) eksik kalanı
# tamamlayan zsh kodu yazar; Oh My Zsh'i script kurduysa hiçbir şey yapmaz.

# Eklenti yüklenmemişse doğrudan yükle:
#   zsh_late_load AD 'ATLAMA_KOŞULU' DOSYA [SONRA_ÇALIŞACAK_KOMUT]
zsh_late_load() {
    local fn="_ts_late_$1" skip="$2" file after="${4:-}"
    printf -v file '%q' "$3"
    cat <<ZSH
autoload -Uz add-zsh-hook
$fn() {
    add-zsh-hook -d precmd $fn
    (( $skip )) && return
    [[ -r $file ]] || return
    source $file${after:+; $after}
}
add-zsh-hook precmd $fn
ZSH
}

# Ctrl+R düz aramaya (ya da devralınabilir bir widget'a) bağlıysa WIDGET'a bağla.
# Kullanıcının kendi seçtiği başka bir widget'a dokunulmaz.
#   zsh_late_rebind AD WIDGET [DEVRALINAN_WIDGET...]
zsh_late_rebind() {
    local fn="_ts_late_$1" widget="$2" from
    shift 2
    from=$(IFS='|'; printf '%s' "history-incremental-search-backward${*:+|$*}")
    cat <<ZSH
autoload -Uz add-zsh-hook
$fn() {
    add-zsh-hook -d precmd $fn
    (( \$+widgets[$widget] )) || return
    case \${\$(bindkey -M emacs '^R')[2]} in
        ($from) bindkey -M emacs '^R' $widget ;;
    esac
}
add-zsh-hook precmd $fn
ZSH
}

# ----------------------------------------------------------------------------
# Geri alma işleyicileri (lib/undo.sh dağıtır)
# ----------------------------------------------------------------------------
undo_rcblock() {
    local file="$1" id="$2"
    is_dry_run && { log_plan "%s: '%s' bloğu çıkarılacak" "$(ts_pretty_path "$file")" "$id"; return 0; }
    rc_strip_block "$file" "$id"
}

# Ayar dosyasını orijinal haline getir. Kurulumdan sonra kullanıcının yaptığı
# değişiklikler (blok dışı) varsa dosyanın son hali önce arşive kopyalanır.
undo_rcfile() {
    local file="$1" saved="$2" current="" original=""
    [[ ! -f "$file" && "$saved" == "NONE" ]] && return 0
    if is_dry_run; then
        # Planda diğer kayıtlar henüz geri alınmadığı için içerik karşılaştırılamaz
        log_plan "%s kurulum öncesi haline dönecek" "$(ts_pretty_path "$file")"
        return 0
    fi
    [[ -f "$file" ]] && current="$(rc_without_blocks "$file")"
    [[ "$saved" != "NONE" ]] && original="$(cat "$TS_FILES_DIR/$saved" 2>/dev/null)"

    if [[ -f "$file" && "$current" != "$original" ]]; then
        log_info "%s kurulumdan sonra değişmiş; son hali arşivleniyor" "$(ts_pretty_path "$file")"
        fs_archive "$file" "kopyala" || return 1
    fi
    if [[ "$saved" == "NONE" ]]; then
        rm -f -- "$file"
    else
        cp -p -- "$TS_FILES_DIR/$saved" "$file" && rm -f -- "$TS_FILES_DIR/$saved"
    fi
}
