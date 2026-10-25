#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Ağ işlemleri ve GitHub release çözümleme
# ============================================================================
# GitHub API kullanılmaz (saatte 60 istek sınırı var). Son sürüm etiketi
# /releases/latest yönlendirmesinden, dosya listesi expanded_assets
# sayfasından okunur.
#
# Testler için: TS_FAKE_RELEASES_DIR tanımlıysa ağ yerine yerel klasör
# kullanılır: <dir>/<owner>__<repo>/tag ve <dir>/<owner>__<repo>/assets/*
# ============================================================================

NET_UA="terminal-setup/${TS_VERSION}"

# İnternet var mı? Temiz Ubuntu masaüstünde curl kurulu gelmez; bu yüzden
# curl yoksa wget, o da yoksa bash'in /dev/tcp bağlantısı denenir.
net_online() {
    [[ -n "${TS_FAKE_RELEASES_DIR:-}" ]] && return 0
    if has_cmd curl; then
        curl -fsS --max-time 8 -o /dev/null -A "$NET_UA" https://github.com 2>/dev/null
    elif has_cmd wget; then
        wget -q --timeout=8 --spider https://github.com 2>/dev/null
    else
        timeout 8 bash -c 'exec 3<>/dev/tcp/github.com/443' 2>/dev/null
    fi
}

# İndir: net_fetch URL HEDEF
net_fetch() {
    local url="$1" dest="$2"
    _log_write NET "$url -> $dest"
    curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 15 -A "$NET_UA" \
        -o "$dest" "$url" 2>> "$TS_LOG_FILE"
}

_gh_fake_dir() { echo "${TS_FAKE_RELEASES_DIR}/${1/\//__}"; }

# Son sürüm etiketi: gh_latest_tag owner/repo -> v1.2.3
gh_latest_tag() {
    local repo="$1" url tag
    if [[ -n "${TS_FAKE_RELEASES_DIR:-}" ]]; then
        cat "$(_gh_fake_dir "$repo")/tag" 2>/dev/null
        return
    fi
    url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' --max-time 20 -A "$NET_UA" \
        "https://github.com/$repo/releases/latest" 2>/dev/null) || return 1
    tag="${url##*/tag/}"
    [[ -n "$tag" && "$tag" != "$url" ]] || return 1
    echo "$tag"
}

# Etiketteki dosyalar arasından desene uyan ilkini bul.
# gh_find_asset owner/repo etiket 'regex' -> dosya adı
gh_find_asset() {
    local repo="$1" tag="$2" pattern="$3"
    if [[ -n "${TS_FAKE_RELEASES_DIR:-}" ]]; then
        find "$(_gh_fake_dir "$repo")/assets" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null \
            | sort | grep -E "$pattern" | head -1
        return
    fi
    curl -fsSL --max-time 20 -A "$NET_UA" \
        "https://github.com/$repo/releases/expanded_assets/$tag" 2>/dev/null \
        | grep -oE 'href="/[^"]+/releases/download/[^"]+"' \
        | sed 's#.*/##; s/"$//' \
        | grep -E "$pattern" | head -1
}

# Release dosyasını indir: gh_download owner/repo etiket dosya HEDEF
gh_download() {
    local repo="$1" tag="$2" asset="$3" dest="$4"
    if [[ -n "${TS_FAKE_RELEASES_DIR:-}" ]]; then
        cp "$(_gh_fake_dir "$repo")/assets/$asset" "$dest"
        return
    fi
    net_fetch "https://github.com/$repo/releases/download/$tag/$asset" "$dest"
}

# A sürümü B'den yeni mi: version_newer 6.1.0 6.0.0
version_newer() {
    [[ "$1" =~ ^[0-9]+(\.[0-9]+)*$ && "$1" != "$2" ]] || return 1
    [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" == "$1" ]]
}

# GitHub'daki sürümle karşılaştır. Yeni sürüm varsa yazdırır ve 0 döner.
update_check() {
    local remote
    has_cmd curl || return 1
    remote=$(curl -fsSL --max-time 4 -A "$NET_UA" \
        "https://raw.githubusercontent.com/alibedirhan/Terminal-Setup/main/VERSION" 2>/dev/null | tr -d '[:space:]')
    version_newer "$remote" "$TS_VERSION" || return 1
    log_info "Yeni sürüm mevcut: %s (kurulu: %s) — https://github.com/alibedirhan/Terminal-Setup" "$remote" "$TS_VERSION"
}
