#!/usr/bin/env bash
# ============================================================================
# Renderer: GNOME Terminal
# ============================================================================
# Varsayılan profilin renk anahtarları dconf ile yazılır. Her anahtarın
# önceki değeri deftere düşer; kaldırınca profil eski haline döner.
# ============================================================================

renderer_register gnome "GNOME Terminal"

# GNOME Terminal'in yerleşik varsayılan profil kimliği
GNOME_DEFAULT_PROFILE="b1dcc9dd-5262-4d8d-a863-c897e6d979b9"

rend_gnome_available() {
    has_cmd gnome-terminal && has_cmd dconf
}

_gnome_profile_path() {
    local uuid=""
    has_cmd gsettings && uuid=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
    [[ "$uuid" =~ ^[0-9a-f-]{36}$ ]] || uuid="$GNOME_DEFAULT_PROFILE"
    echo "/org/gnome/terminal/legacy/profiles:/:$uuid/"
}

rend_gnome_apply() {
    local p
    p=$(_gnome_profile_path)
    act_dconf_key "${p}use-theme-colors" "false" &&
    act_dconf_key "${p}background-color" "'${THEME[BACKGROUND]}'" &&
    act_dconf_key "${p}foreground-color" "'${THEME[FOREGROUND]}'" &&
    act_dconf_key "${p}palette" "$(theme_palette_gvariant)" &&
    act_dconf_key "${p}cursor-colors-set" "true" &&
    act_dconf_key "${p}cursor-background-color" "'${THEME[CURSOR]}'" &&
    act_dconf_key "${p}cursor-foreground-color" "'${THEME[BACKGROUND]}'" &&
    act_dconf_key "${p}highlight-colors-set" "true" &&
    act_dconf_key "${p}highlight-background-color" "'${THEME[SELECTION_BG]}'" &&
    act_dconf_key "${p}highlight-foreground-color" "'${THEME[SELECTION_FG]}'"
}

rend_gnome_font() {
    local p
    p=$(_gnome_profile_path)
    act_dconf_key "${p}use-system-font" "false" &&
    act_dconf_key "${p}font" "'$TS_FONT_NAME $TS_FONT_SIZE'"
}
