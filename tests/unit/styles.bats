#!/usr/bin/env bats
# Kişilikler: tema = palet + biçim; dosyalar denetlenir, kullanıcı seçebilir

load '../helpers/common'

setup() {
    setup_fakesys
    load_lib
}

@test "altı kişiliğin hepsi geçerli ve her biri en az bir temada kullanılıyor" {
    local s t n=0 used
    for s in $(style_list); do
        style_load "$s"
        n=$((n + 1))
        used=0
        for t in $(theme_list); do
            grep -qx "STYLE=\"$s\"" "$REPO_ROOT/themes/$t.theme" && used=1
        done
        ((used)) || { echo "kullanılmayan kişilik: $s"; false; }
    done
    [ "$n" -eq 6 ]
}

@test "her tema var olan bir kişiliğe bağlı ve yüklenince kişiliği de yüklenir" {
    local t
    for t in $(theme_list); do
        theme_load "$t"
        style_exists "${THEME[STYLE]}" || { echo "$t: ${THEME[STYLE]}"; false; }
        [ "${STYLE[ID]}" = "${THEME[STYLE]}" ]
    done
}

@test "kullanıcının seçimi temanın kişiliğinin önüne geçer; auto geri döndürür" {
    theme_load nord
    [ "${STYLE[ID]}" = arctic ]
    settings_set style retro
    theme_load nord
    [ "${STYLE[ID]}" = retro ]
    # Geçersiz bir ayar temanın kişiliğine düşer
    settings_set style olmayan
    theme_load nord
    [ "${STYLE[ID]}" = arctic ]
    settings_set style auto
    theme_load dracula
    [ "${STYLE[ID]}" = vivid ]
}

@test "geçersiz değer ya da eksik anahtar reddedilir" {
    mkdir -p "$BATS_TEST_TMPDIR/root/styles"
    grep -v '^BORDER=' "$REPO_ROOT/styles/modern.style" > "$BATS_TEST_TMPDIR/root/styles/eksik.style"
    sed 's/^BORDER=.*/BORDER="dalgali"/' "$REPO_ROOT/styles/modern.style" > "$BATS_TEST_TMPDIR/root/styles/kotu.style"
    TS_ROOT="$BATS_TEST_TMPDIR/root" run style_load eksik
    [ "$status" -ne 0 ]
    TS_ROOT="$BATS_TEST_TMPDIR/root" run style_load kotu
    [ "$status" -ne 0 ]
    run style_load "../modern"
    [ "$status" -ne 0 ]
}

@test "büyük/küçük harf Türkçeyi bilir" {
    style_load retro
    TS_LANG=tr style_case title "İyi akşamlar, Ali"
    [ "$REPLY" = "İYİ AKŞAMLAR, ALİ" ]
    TS_LANG=en style_case title "Good evening"
    [ "$REPLY" = "GOOD EVENING" ]
    style_load arctic
    TS_LANG=tr style_case text "Iğdır İzmir"
    [ "$REPLY" = "ığdır izmir" ]
    style_load modern
    style_case title "Aynen"
    [ "$REPLY" = "Aynen" ]
}

@test "her kişiliğin altı kenar karakteri ve fzf seçenekleri var" {
    local s
    for s in $(style_list); do
        style_load "$s"
        style_box
        read -ra box <<< "$REPLY"
        [ "${#box[@]}" -eq 6 ]
        style_fzf_opts
        [[ "$REPLY" == "--border="*" --pointer='${STYLE[PROMPT_SYMBOL]}'"* ]]
    done
}

@test "fzf parçası kişiliği taşır; retro'nun \$ simgesi zsh'te bozulmaz" {
    local zsh
    zsh=$(PATH=/usr/bin:/bin command -v zsh) || skip "gerçek zsh yok"
    settings_set style retro
    theme_load nord
    TS_CURRENT_COMPONENT=theme
    rend_clitools_apply
    local snip="$HOME/.config/terminal-setup/zsh.d/65-theme-tools.zsh"
    grep -q -- "--border=sharp" "$snip"
    run "$zsh" -f -c "source '$snip'; print -r -- \$FZF_DEFAULT_OPTS"
    [[ "$output" == *"--pointer='\$' --prompt='\$ '"* ]]
}
