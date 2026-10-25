#!/usr/bin/env bats
# Menü, gerçek bir sözde terminalde (tmux) tuşlarla sürülür:
#   - ekranlar arasında gezinme ve geri dönme
#   - pencere boyutu değişince yeniden yerleşim
#   - hızlı tuş basımında ekrana kaçış dizisi çöpü düşmemesi
#   - çıkışta ve Ctrl+C'de terminalin eski haline dönmesi (yankı, satır kipi)
# tmux yoksa atlanır. Sahte sistemde çalışır; hiçbir şey kurulmaz.

load '../helpers/common'

setup() {
    TMUX_BIN=$(command -v tmux) || skip "tmux yok"
    setup_fakesys
    mkdir -p "$HOME/.terminal-setup"
    echo "update_check=off" > "$HOME/.terminal-setup/settings"
    TMUX_SOCK="ts-test-$$-$BATS_TEST_NUMBER"
    export -p > "$BATS_TEST_TMPDIR/env.sh"
    # Etkileşimli bir kabuk açılır; program onun içinde çalıştırılır
    "$TMUX_BIN" -L "$TMUX_SOCK" -f /dev/null new-session -d -s t -x 100 -y 40 \
        "bash --norc --noprofile -c 'source \"$BATS_TEST_TMPDIR/env.sh\"; unset NO_COLOR; export TERM=xterm-256color COLORTERM=truecolor PS1=\"KABUK> \"; exec bash --norc --noprofile -i'"
    wait_for "KABUK>"
}

teardown() {
    [[ -n "${TMUX_SOCK:-}" ]] && "$TMUX_BIN" -L "$TMUX_SOCK" kill-server 2>/dev/null
    return 0
}

t() { "$TMUX_BIN" -L "$TMUX_SOCK" "$@"; }
screen() { t capture-pane -p -t t; }
keys() { local k; for k in "$@"; do t send-keys -t t "$k"; sleep 0.15; done; }

# wait_for METİN [saniye]: ekranda görünene kadar bekle
wait_for() {
    local i
    for ((i = 0; i < ${2:-10} * 10; i++)); do
        screen | grep -qF -- "$1" && return 0
        sleep 0.1
    done
    echo "Beklenen metin gelmedi: $1"
    screen
    return 1
}

start_menu() {
    t send-keys -t t "\"$REPO_ROOT/terminal-setup.sh\"; echo \"ÇIKIŞ=\$?\"" Enter
    wait_for "Ne yapmak istersiniz?"
}

# Kabuğa dönüldükten sonra terminal ayarları normal mi
assert_terminal_restored() {
    t send-keys -t t "stty -a > \"$BATS_TEST_TMPDIR/stty.txt\"" Enter
    sleep 0.5
    grep -qw -- "echo" "$BATS_TEST_TMPDIR/stty.txt"
    grep -qw -- "icanon" "$BATS_TEST_TMPDIR/stty.txt"
    ! grep -qw -- "-echo" "$BATS_TEST_TMPDIR/stty.txt"
    ! grep -qw -- "-icanon" "$BATS_TEST_TMPDIR/stty.txt"
}

@test "menüde gezinme: tema, bileşenler, ayarlar ve geri" {
    start_menu
    keys 2
    wait_for "Tema dene"
    keys Right Right
    wait_for "3 / 12"
    keys q
    wait_for "Ne yapmak istersiniz?"
    keys 3
    wait_for "işareti kaldırılanlar kaldırılır"
    keys Down Down Space q
    wait_for "Ne yapmak istersiniz?"
    keys 8
    wait_for "Dosya konumları"
    keys q q
    wait_for "ÇIKIŞ=0"
    screen | grep -q "görüşmek üzere"
    assert_terminal_restored
}

@test "işlem çıktısı normal ekranda kalır; Enter ile menüye dönülür" {
    start_menu
    keys 5
    wait_for "devam etmek için basın"
    screen | grep -q "Sağlık kontrolü"
    keys Enter
    wait_for "Ne yapmak istersiniz?"
    keys q
    wait_for "ÇIKIŞ=0"
    # Durum çıktısı kaydırılabilir geçmişte kaldı, menü kalıntısı kalmadı
    t capture-pane -p -t t -S -200 | grep -q "Sağlık kontrolü"
    ! screen | grep -q "Ne yapmak istersiniz?"
    assert_terminal_restored
}

@test "pencere küçülünce menü sade başlığa geçer ve taşmaz" {
    start_menu
    screen | grep -q "▀▀█▀▀"
    t resize-window -t t -x 70 -y 22
    sleep 0.6
    keys Down
    wait_for "Ne yapmak istersiniz?"
    ! screen | grep -q "▀▀█▀▀"
    # tuş ipuçları en altta, başlık bir kez
    [ "$(screen | grep -c "Ne yapmak istersiniz?")" -eq 1 ]
    screen | grep -v '^$' | tail -n 1 | grep -q "enter"
    keys q
    wait_for "ÇIKIŞ=0"
}

@test "hızlı tuş basımı ekrana kaçış dizisi çöpü bırakmaz" {
    start_menu
    keys 3
    wait_for "işareti kaldırılanlar"
    local i
    for ((i = 0; i < 40; i++)); do t send-keys -t t Down; done
    for ((i = 0; i < 40; i++)); do t send-keys -t t Up; done
    sleep 1.5
    ! screen | grep -qE '\^\[|\[A|\[B|OA|OB'
    keys q q
    wait_for "ÇIKIŞ=0"
}

@test "Ctrl+C menüden çıkar ve terminali eski haline döndürür" {
    start_menu
    keys 2
    wait_for "Tema dene"
    t send-keys -t t C-c
    wait_for "ÇIKIŞ=130"
    screen | grep -q "İptal edildi"
    assert_terminal_restored
}

@test "dil menüden değiştirilir ve hemen uygulanır" {
    start_menu
    keys 8
    wait_for "Dil / Language"
    keys Enter
    wait_for "English"
    keys 3
    wait_for "Settings"
    keys q
    wait_for "What would you like to do?"
    grep -qx "language=en" "$HOME/.terminal-setup/settings"
    keys q
    wait_for "ÇIKIŞ=0"
    screen | grep -q "see you"
    assert_terminal_restored
}
