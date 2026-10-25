#!/usr/bin/env python3
"""tmux ekran karelerini (capture-pane -e) PNG ya da animasyonlu GIF'e çevirir.

Kullanım:
  render.py png ÇIKTI.png KARE.ansi
  render.py gif ÇIKTI.gif KARE.ansi:SÜRE_MS [KARE.ansi:SÜRE_MS ...]

Kareler 24 bit, 256 ve 16 renkli SGR kodlarını içerebilir. Yarım bloklar ve
kutu çizgileri yazı tipiyle değil doğrudan çizilir; böylece satırlar arasında
boşluk kalmaz ve logo kesintisiz görünür. Gereken: Pillow, DejaVu Sans Mono.
"""
import re
import sys

from PIL import Image, ImageDraw, ImageFont

FONT_DIR = "/usr/share/fonts/truetype/dejavu/"
FONT_SIZE = 16
PAD = 14            # pencere içi kenar boşluğu
TITLE_H = 30        # başlık çubuğu
DEFAULT_FG = (205, 214, 244)
DEFAULT_BG = (24, 24, 37)
TITLE_BG = (17, 17, 27)
ANSI16 = [
    (69, 71, 90), (243, 139, 168), (166, 227, 161), (249, 226, 175),
    (137, 180, 250), (245, 194, 231), (148, 226, 213), (186, 194, 222),
    (88, 91, 112), (243, 139, 168), (166, 227, 161), (249, 226, 175),
    (137, 180, 250), (245, 194, 231), (148, 226, 213), (166, 173, 200),
]


def xterm256(n):
    if n < 16:
        return ANSI16[n]
    if n < 232:
        n -= 16
        steps = [0, 95, 135, 175, 215, 255]
        return (steps[n // 36], steps[(n // 6) % 6], steps[n % 6])
    v = 8 + (n - 232) * 10
    return (v, v, v)


class Cell:
    __slots__ = ("ch", "fg", "bg", "bold", "dim")

    def __init__(self, ch=" ", fg=None, bg=None, bold=False, dim=False):
        self.ch, self.fg, self.bg, self.bold, self.dim = ch, fg, bg, bold, dim


SGR = re.compile(r"\x1b\[([0-9;:]*)m")
OTHER_ESC = re.compile(r"\x1b(\[[0-9;?]*[A-Za-z]|\][^\x07]*\x07|[()][A-Z0-9])")


def parse_line(line):
    """Bir satırı hücrelere ayır."""
    cells = []
    st = {"fg": None, "bg": None, "bold": False, "dim": False, "rev": False}
    pos = 0
    line = OTHER_ESC.sub(lambda m: m.group(0) if m.group(0).endswith("m") else "", line)
    for m in SGR.finditer(line + "\x1b[m"):
        for ch in line[pos:m.start()]:
            fg, bg = st["fg"], st["bg"]
            if st["rev"]:
                fg, bg = (bg or DEFAULT_BG), (fg or DEFAULT_FG)
            cells.append(Cell(ch, fg, bg, st["bold"], st["dim"]))
        pos = m.end()
        apply_sgr(st, m.group(1))
    return cells


def apply_sgr(st, params):
    codes = [int(p) if p.isdigit() else 0 for p in re.split("[;:]", params or "0")]
    i = 0
    while i < len(codes):
        c = codes[i]
        if c == 0:
            st.update(fg=None, bg=None, bold=False, dim=False, rev=False)
        elif c == 1:
            st["bold"] = True
        elif c == 2:
            st["dim"] = True
        elif c == 22:
            st["bold"] = st["dim"] = False
        elif c == 7:
            st["rev"] = True
        elif c == 27:
            st["rev"] = False
        elif 30 <= c <= 37:
            st["fg"] = ANSI16[c - 30]
        elif 90 <= c <= 97:
            st["fg"] = ANSI16[c - 90 + 8]
        elif 40 <= c <= 47:
            st["bg"] = ANSI16[c - 40]
        elif 100 <= c <= 107:
            st["bg"] = ANSI16[c - 100 + 8]
        elif c == 39:
            st["fg"] = None
        elif c == 49:
            st["bg"] = None
        elif c in (38, 48) and i + 1 < len(codes):
            key = "fg" if c == 38 else "bg"
            if codes[i + 1] == 5 and i + 2 < len(codes):
                st[key] = xterm256(codes[i + 2])
                i += 2
            elif codes[i + 1] == 2 and i + 4 < len(codes):
                st[key] = tuple(codes[i + 2:i + 5])
                i += 4
        i += 1


def blend(a, b, t):
    return tuple(int(a[k] * (1 - t) + b[k] * t) for k in range(3))


class Renderer:
    def __init__(self, cols, rows):
        self.cols, self.rows = cols, rows
        self.font = ImageFont.truetype(FONT_DIR + "DejaVuSansMono.ttf", FONT_SIZE)
        self.bold = ImageFont.truetype(FONT_DIR + "DejaVuSansMono-Bold.ttf", FONT_SIZE)
        self.cw = round(self.font.getlength("M"))
        asc, desc = self.font.getmetrics()
        self.ch = asc + desc + 2
        self.width = cols * self.cw + 2 * PAD
        self.height = rows * self.ch + 2 * PAD + TITLE_H

    def frame(self, text, title):
        img = Image.new("RGB", (self.width, self.height), DEFAULT_BG)
        d = ImageDraw.Draw(img)
        self._chrome(d, title)
        lines = text.split("\n")[: self.rows]
        for y, line in enumerate(lines):
            for x, cell in enumerate(parse_line(line)[: self.cols]):
                self._cell(d, x, y, cell)
        return img

    def _chrome(self, d, title):
        d.rectangle([0, 0, self.width, TITLE_H], fill=TITLE_BG)
        for i, col in enumerate([(243, 139, 168), (249, 226, 175), (166, 227, 161)]):
            cx = 18 + i * 20
            d.ellipse([cx - 6, TITLE_H // 2 - 6, cx + 6, TITLE_H // 2 + 6], fill=col)
        tw = self.font.getlength(title)
        d.text(((self.width - tw) / 2, (TITLE_H - FONT_SIZE) / 2 - 1), title,
               font=self.font, fill=(147, 153, 178))

    def _cell(self, d, x, y, c):
        x0 = PAD + x * self.cw
        y0 = TITLE_H + PAD + y * self.ch
        x1, y1 = x0 + self.cw, y0 + self.ch
        bg = c.bg or DEFAULT_BG
        fg = c.fg or DEFAULT_FG
        if c.dim:
            fg = blend(fg, bg, 0.45)
        if c.bg:
            d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=bg)
        if self._block(d, c.ch, x0, y0, x1, y1, fg):
            return
        if c.ch != " ":
            d.text((x0, y0 + 1), c.ch, font=self.bold if c.bold else self.font, fill=fg)

    def _block(self, d, ch, x0, y0, x1, y1, fg):
        """Blok ve kutu karakterlerini doğrudan çiz; çizildiyse True."""
        xm, ym = (x0 + x1) // 2, (y0 + y1) // 2
        rects = {
            "█": [x0, y0, x1 - 1, y1 - 1], "▀": [x0, y0, x1 - 1, ym - 1],
            "▄": [x0, ym, x1 - 1, y1 - 1], "▌": [x0, y0, xm - 1, y1 - 1],
            "▐": [xm, y0, x1 - 1, y1 - 1],
        }
        if ch in rects:
            d.rectangle(rects[ch], fill=fg)
            return True
        segs = {
            "─": [(x0, ym, x1, ym)], "│": [(xm, y0, xm, y1)],
            "╭": [(xm, ym, x1, ym), (xm, ym, xm, y1)], "╮": [(x0, ym, xm, ym), (xm, ym, xm, y1)],
            "╰": [(xm, y0, xm, ym), (xm, ym, x1, ym)], "╯": [(xm, y0, xm, ym), (x0, ym, xm, ym)],
        }
        if ch in segs:
            for seg in segs[ch]:
                d.line(seg, fill=fg, width=1)
            return True
        return False


def read_frame(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read().rstrip("\n")


def main():
    mode, out, specs = sys.argv[1], sys.argv[2], sys.argv[3:]
    cols, rows = 100, 34
    title = "Terminal Setup"
    r = Renderer(cols, rows)
    if mode == "png":
        r.frame(read_frame(specs[0]), title).save(out, optimize=True)
        return
    frames, durations = [], []
    for spec in specs:
        path, ms = spec.rsplit(":", 1)
        img = r.frame(read_frame(path), title)
        frames.append(img.quantize(colors=128, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE))
        durations.append(int(ms))
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=durations,
                   loop=0, optimize=True, disposal=1)


if __name__ == "__main__":
    main()
