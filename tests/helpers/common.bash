#!/usr/bin/env bash
# ============================================================================
# Testler için ortak kurulum: her test kendi sahte sistemiyle çalışır.
#   - HOME geçici bir dizindir
#   - apt-get/dpkg-query/sudo/chsh/dconf/git clone/curl taklitleri PATH'tedir
#   - GitHub release'leri yerel klasörden okunur (TS_FAKE_RELEASES_DIR)
# Gerçek sisteme hiçbir şey yazılmaz, ağa çıkılmaz.
# ============================================================================

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

setup_fakesys() {
    export TS_ROOT="$REPO_ROOT"
    export FAKE_ROOT="$BATS_TEST_TMPDIR/sys"
    export HOME="$BATS_TEST_TMPDIR/home"
    export TMPDIR="$BATS_TEST_TMPDIR/tmp"
    export USER="tester"
    export NO_COLOR=1
    unset TS_STATE_DIR TS_CONFIG_DIR TS_BIN_DIR TS_FONT_DIR TS_ARCHIVE_DIR TS_CORE_LOADED
    mkdir -p "$HOME" "$TMPDIR" "$FAKE_ROOT/pkgbin" "$FAKE_ROOT/dconf" "$FAKE_ROOT/releases"
    _make_sysbin
    export PATH="$REPO_ROOT/tests/helpers/bin:$FAKE_ROOT/pkgbin:$HOME/.local/bin:$FAKE_ROOT/sysbin"

    echo "/bin/bash" > "$FAKE_ROOT/shell"
    printf '/bin/bash\n%s\n' "$FAKE_ROOT/pkgbin/zsh" > "$FAKE_ROOT/shells"
    export TS_SHELLS_FILE="$FAKE_ROOT/shells"
    printf 'ID=ubuntu\nVERSION_ID="24.04"\n' > "$FAKE_ROOT/os-release"
    export TS_OS_RELEASE="$FAKE_ROOT/os-release"
    export TS_FAKE_RELEASES_DIR="$FAKE_ROOT/releases"
    export TS_FAKE_ARCH="x86_64"

    # Başlangıçta kurulu paketler
    printf 'bash\ncoreutils\n' > "$FAKE_ROOT/dpkg.txt"
    cat > "$FAKE_ROOT/deps" <<'EOF'
zsh: zsh-common
bat: libgit2
ripgrep:
fd-find:
tmux: libevent
git: git-man
EOF
    cat > "$FAKE_ROOT/provides" <<'EOF'
zsh: zsh
bat: batcat
ripgrep: rg
fd-find: fdfind
tmux: tmux
btop: btop
duf: duf
tldr: tldr
unzip: unzip
curl: curl
EOF
    _make_release_fixtures
}

# Yalnızca temel Unix araçlarını içeren PATH dizini. Gerçek sistemdeki
# bat, eza, zsh gibi araçlar testi etkilemesin.
_make_sysbin() {
    local tool path
    mkdir -p "$FAKE_ROOT/sysbin"
    for tool in bash sh env awk sed grep tar gzip python3 find comm sort uniq head tail wc cut tr \
        cat cp mv rm mkdir rmdir ln ls chmod install date mktemp base64 dirname basename readlink \
        cmp diff tee sleep kill touch id uname paste xargs stat git tput true false; do
        path=$(PATH=/usr/bin:/bin command -v "$tool") && ln -sf "$path" "$FAKE_ROOT/sysbin/$tool"
    done
}

# Her GitHub aracı için sahte bir release (tar.gz ya da zip)
_make_release_fixtures() {
    local spec repo tag asset bin dir work
    local specs=(
        "junegunn/fzf|v0.1.0|fzf-0.1.0-linux_amd64.tar.gz|fzf"
        "ajeetdsouza/zoxide|v0.1.0|zoxide-0.1.0-x86_64-unknown-linux-musl.tar.gz|zoxide"
        "eza-community/eza|v0.1.0|eza_x86_64-unknown-linux-musl.tar.gz|eza"
        "dandavison/delta|0.1.0|delta-0.1.0-x86_64-unknown-linux-musl.tar.gz|delta"
        "jesseduffield/lazygit|v0.1.0|lazygit_0.1.0_linux_x86_64.tar.gz|lazygit"
        "bootandy/dust|v0.1.0|dust-v0.1.0-x86_64-unknown-linux-musl.tar.gz|dust"
        "dalance/procs|v0.1.0|procs-v0.1.0-x86_64-linux.zip|procs"
        "atuinsh/atuin|v0.1.0|atuin-x86_64-unknown-linux-musl.tar.gz|atuin"
    )
    for spec in "${specs[@]}"; do
        IFS='|' read -r repo tag asset bin <<< "$spec"
        dir="$FAKE_ROOT/releases/${repo/\//__}"
        work="$BATS_TEST_TMPDIR/build-$bin/pkg-$bin"
        mkdir -p "$dir/assets" "$work"
        echo "$tag" > "$dir/tag"
        printf '#!/bin/sh\necho "%s %s (taklit)"\n' "$bin" "$tag" > "$work/$bin"
        chmod +x "$work/$bin"
        if [[ "$asset" == *.zip ]]; then
            python3 -c "import zipfile,sys; z=zipfile.ZipFile(sys.argv[1],'w'); z.write(sys.argv[2],sys.argv[3]); z.close()" \
                "$dir/assets/$asset" "$work/$bin" "$bin"
        else
            tar -czf "$dir/assets/$asset" -C "$(dirname "$work")" "pkg-$bin"
        fi
    done
    # apt ile "unzip" kurulunca gerçekten açan bir taklit gelsin (python ile)
    cat > "$FAKE_ROOT/impl-unzip" <<'EOF'
#!/usr/bin/env bash
src="" dest="."
while (($#)); do case "$1" in -q) ;; -d) dest="$2"; shift ;; *) src="$1" ;; esac; shift; done
python3 -c "import zipfile,sys,os; z=zipfile.ZipFile(sys.argv[1]); z.extractall(sys.argv[2]); [os.chmod(os.path.join(sys.argv[2],n),0o755) for n in z.namelist()]" "$src" "$dest"
EOF
}

# Script'i çalıştır (onaylar otomatik)
ts() {
    "$REPO_ROOT/terminal-setup.sh" --yes "$@"
}

# Kütüphaneyi test kabuğuna yükle (birim testleri için)
load_lib() {
    # shellcheck source=/dev/null
    source "$REPO_ROOT/lib/core.sh"
    ts_load
    TS_TMP="$BATS_TEST_TMPDIR/ts-tmp"
    mkdir -p "$TS_TMP"
    log_init
}

pkg_is_installed() { grep -qxF "$1" "$FAKE_ROOT/dpkg.txt"; }

login_shell() { cat "$FAKE_ROOT/shell"; }
