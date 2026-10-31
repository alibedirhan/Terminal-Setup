#!/usr/bin/env bash
# ============================================================================
# Terminal Setup - Renk rolleri ve okunabilirlik garantisi
# ============================================================================
# Temanın 16 rengi terminale olduğu gibi gider; temanın kimliği korunur.
# Terminal Setup'ın kendi çizdiği her şey (fzf, btop, tmux, önizleme, prompt)
# ise numaralı renkleri değil, anlamı olan rolleri kullanır:
#
#   fg accent accent2 info ok warn err muted sel sel_fg border cursor bg
#
# Roller arka plana karşı WCAG 2 kontrast oranıyla denetlenir:
#   muted         hesaplanır: arka plandan ön plana, 4.5:1'e ulaşan ilk karışım
#                 (temaların COLOR8'i çoğu zaman okunmaz: Solarized'da 1.0:1)
#   renkli roller en az 3:1; altındaysa ön plana doğru gerektiği kadar kayar
#   sel_fg        seçim zemininde en az 4.5:1; olmuyorsa zemin açılır
# Hesap tek bir awk çağrısıdır; gawk eklentisi kullanılmaz (Ubuntu'da mawk).
# ============================================================================

declare -gA ROLE=()
PALETTE_MIN_TEXT=4.5
PALETTE_MIN_COLOR=3.0

# Ortak awk fonksiyonları: renkler "#RRGGBB"
_PALETTE_AWK='
function hexv(s,   i, v) { s = tolower(s); v = 0
    for (i = 1; i <= length(s); i++) v = v * 16 + index("0123456789abcdef", substr(s, i, 1)) - 1
    return v }
function ch(h, n) { return hexv(substr(h, 2 + 2 * n, 2)) }
function lin(v) { v = v / 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ^ 2.4 }
function lum(h) { return 0.2126 * lin(ch(h, 0)) + 0.7152 * lin(ch(h, 1)) + 0.0722 * lin(ch(h, 2)) }
function contrast(a, b,   x, y, t) { x = lum(a); y = lum(b); if (y > x) { t = x; x = y; y = t }
    return (x + 0.05) / (y + 0.05) }
function mix(a, b, p,   n, out) { out = "#"
    for (n = 0; n < 3; n++) out = out sprintf("%02X", int((ch(a, n) * (100 - p) + ch(b, n) * p) / 100 + 0.5))
    return out }
function ensure(c, min,   p, m) { for (p = 0; p <= 100; p += 2) { m = mix(c, fg, p); if (contrast(m, bg) >= min) return m }
    return fg }
'

# İki rengin kontrast oranı: palette_contrast "#RRGGBB" "#RRGGBB" -> "4.52"
palette_contrast() {
    awk -v a="$1" -v b="$2" "$_PALETTE_AWK"'BEGIN { printf "%.2f\n", contrast(a, b) }'
}

# İki rengin karışımı: palette_mix A B YÜZDE (0 = A, 100 = B) -> "#RRGGBB"
palette_mix() {
    awk -v a="$1" -v b="$2" -v p="$3" "$_PALETTE_AWK"'BEGIN { print mix(a, b, p) }'
}

# Yüklü temadan (THEME) rolleri hesapla -> ROLE
palette_roles() {
    local key value
    ROLE=()
    while IFS='=' read -r key value; do
        [[ -n "$key" ]] && ROLE[$key]="$value"
    done < <(awk -v bg="${THEME[BACKGROUND]}" -v fg="${THEME[FOREGROUND]}" \
        -v accent="${THEME[ACCENT]}" -v accent2="${THEME[COLOR5]}" -v info="${THEME[COLOR6]}" \
        -v ok="${THEME[COLOR2]}" -v warn="${THEME[COLOR3]}" -v err="${THEME[COLOR1]}" \
        -v sel="${THEME[SELECTION_BG]}" -v sel0="${THEME[SELECTION_BG]}" -v selfg="${THEME[SELECTION_FG]}" \
        -v border="${THEME[BORDER]}" -v cursor="${THEME[CURSOR]}" \
        -v mintext="$PALETTE_MIN_TEXT" -v mincolor="$PALETTE_MIN_COLOR" "$_PALETTE_AWK"'
        BEGIN {
            print "bg=" bg; print "fg=" fg; print "border=" border; print "cursor=" cursor
            print "accent=" ensure(accent, mincolor); print "accent2=" ensure(accent2, mincolor)
            print "info=" ensure(info, mincolor); print "ok=" ensure(ok, mincolor)
            print "warn=" ensure(warn, mincolor); print "err=" ensure(err, mincolor)
            muted = fg
            for (p = 20; p <= 100; p++) { m = mix(bg, fg, p); if (contrast(m, bg) >= mintext) { muted = m; break } }
            print "muted=" muted
            if (contrast(selfg, sel) < mintext) selfg = (contrast(fg, sel) >= contrast(bg, sel)) ? fg : bg
            # Hâlâ yetmiyorsa seçim zemini arka plana doğru açılır (yazı rengi kalır)
            for (p = 0; p <= 100 && contrast(selfg, sel) < mintext; p += 2) sel = mix(sel0, bg, p)
            print "sel=" sel; print "sel_fg=" selfg
        }')
    [[ -n "${ROLE[muted]:-}" ]]
}
