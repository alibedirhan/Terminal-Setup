#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Kullanıcı ayarları
# ============================================================================
# ~/.terminal-setup/settings dosyasında "anahtar=değer" satırları. Dosya
# kaynak olarak yüklenmez (source edilmez), satır satır okunur; böylece
# içine yazılan hiçbir şey kod olarak çalışmaz.
#
# Anahtarlar: theme (uygulanan tema), default_profile, update_check (on/off)
# ============================================================================

settings_get() {
    local key="$1" default="${2:-}" value
    if [[ -f "$TS_SETTINGS_FILE" ]]; then
        value=$(awk -F= -v k="$key" '$1 == k { sub(/^[^=]*=/, ""); print; exit }' "$TS_SETTINGS_FILE")
    fi
    printf '%s\n' "${value:-$default}"
}

settings_set() {
    local key="$1" value="$2" tmp
    [[ "$key" =~ ^[a-z_]+$ ]] || return 1
    [[ "$value" == *$'\n'* ]] && return 1
    is_dry_run && return 0
    mkdir -p "$TS_STATE_DIR" || return 1
    tmp="$TS_SETTINGS_FILE.tmp"
    {
        [[ -f "$TS_SETTINGS_FILE" ]] && awk -F= -v k="$key" '$1 != k' "$TS_SETTINGS_FILE"
        printf '%s=%s\n' "$key" "$value"
    } > "$tmp" && mv "$tmp" "$TS_SETTINGS_FILE"
}

# ----------------------------------------------------------------------------
# Araç sürümleri: ~/.terminal-setup/versions, "ad<TAB>etiket" satırları.
# GitHub'dan kurulan araçların hangi sürümde olduğunu güncelleme bilsin diye.
# ----------------------------------------------------------------------------

tool_version_get() {
    [[ -f "$TS_VERSIONS_FILE" ]] || return 0
    awk -F'\t' -v k="$1" '$1 == k { print $2; exit }' "$TS_VERSIONS_FILE"
}

tool_version_set() {
    local name="$1" tag="$2" tmp
    [[ "$name$tag" == *[[:space:]]* ]] && return 1
    is_dry_run && return 0
    mkdir -p "$TS_STATE_DIR" || return 1
    tmp="$TS_VERSIONS_FILE.tmp"
    {
        [[ -f "$TS_VERSIONS_FILE" ]] && awk -F'\t' -v k="$name" '$1 != k' "$TS_VERSIONS_FILE"
        printf '%s\t%s\n' "$name" "$tag"
    } > "$tmp" && mv "$tmp" "$TS_VERSIONS_FILE"
}
