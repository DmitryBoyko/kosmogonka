"""Vector wordmark from the game's OFL Russo One font; no runtime font dependency."""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

ROOT = Path(__file__).resolve().parents[1]
font = TTFont(ROOT / 'assets/fonts/RussoOne-Regular.ttf')
glyphs = font.getGlyphSet()
cmap = font.getBestCmap()
scale = 100 / font['head'].unitsPerEm
word = 'КОСМОГОНКА'
colors = ['#55d9ff', '#859bff', '#ff88c5', '#ffdf70', '#61e5b7', '#77d9ff', '#ffbc65', '#e2a6ff', '#63e9ff', '#ffb678']
widths = [font['hmtx'].metrics[cmap[ord(c)]][0] * scale + 3 for c in word]
width = sum(widths) + 24
defs, shapes = [], []
for i, color in enumerate(colors):
    defs.append(f'<linearGradient id="letter{i}" x1="0" y1="0" x2="0.2" y2="1"><stop stop-color="#ffffff"/><stop offset=".25" stop-color="{color}"/><stop offset="1" stop-color="{color}"/></linearGradient>')
for i, palette in enumerate([('#dff9ff','#40bfff','#354cba'),('#b9fff1','#25c5bf','#155e9c'),('#fff4b2','#efaa50','#b84f8e')]):
    defs.append(f'<radialGradient id="planet{i}" cx=".32" cy=".24" r=".8"><stop stop-color="{palette[0]}"/><stop offset=".5" stop-color="{palette[1]}"/><stop offset="1" stop-color="{palette[2]}"/></radialGradient>')
x, planet = 12., 0
for i, char in enumerate(word):
    advance = widths[i]
    if char == 'О':
        cx, cy, r = x + advance / 2 - 1, 65, min(34, advance * .43)
        defs.append(f'<clipPath id="clip{planet}"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath>')
        ring = f'<ellipse cx="{cx}" cy="{cy}" rx="{r+8}" ry="10" transform="rotate(-23 {cx} {cy})" fill="none" stroke="#aeecff" stroke-width="3"/>'
        shapes.append(ring if planet != 1 else '')
        shapes.append(f'<circle cx="{cx+2}" cy="{cy+5}" r="{r+2}" fill="#111c48"/><circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#planet{planet})" stroke="#d6f5ff" stroke-width="1.8"/>')
        if planet == 1:
            shapes.append(f'<g clip-path="url(#clip{planet})" fill="#95e7a4" opacity=".85"><path d="M {cx-26},{cy-18} l 17,-8 10,8 -4,10 10,6 -9,11 -10,-5 -2,-13 -12,-1 Z"/><path d="M {cx+13},{cy+5} l 19,-3 8,13 -17,17 -13,-12 Z"/></g>')
        else:
            shapes.append(f'<g clip-path="url(#clip{planet})" fill="none" stroke="#fff2dc" stroke-width="5" opacity=".32"><path d="M {cx-r},{cy-14} Q {cx},{cy+2} {cx+r},{cy-12} M {cx-r},{cy+3} Q {cx},{cy+20} {cx+r},{cy+7}"/></g>')
            shapes.append(f'<path d="M {cx-r-6},{cy+11} Q {cx},{cy+22} {cx+r+6},{cy-14}" fill="none" stroke="#c3eeff" stroke-width="3"/>')
        shapes.append(f'<ellipse cx="{cx-r*.36}" cy="{cy-r*.43}" rx="7" ry="3" transform="rotate(-35 {cx-r*.36} {cy-r*.43})" fill="white" opacity=".65"/>')
        planet += 1
    elif i == len(word) - 1:
        cx = x + advance / 2
        shapes.append(f'''<g stroke="#142147" stroke-width="3" stroke-linejoin="round">
        <path d="M {cx},27 Q {cx-19},48 {cx-20},78 L {cx-31},102 L {cx-14},99 L {cx},82 L {cx+14},99 L {cx+31},102 L {cx+20},78 Q {cx+19},48 {cx},27 Z" fill="url(#letter9)"/>
        <path d="M {cx-17},72 L {cx-33},102 L {cx-20},99 L {cx-9},77 M {cx+17},72 L {cx+33},102 L {cx+20},99 L {cx+9},77" fill="#fa78b9"/>
        <path d="M {cx-8},99 Q {cx-12},112 {cx},126 Q {cx+13},112 {cx+8},99" fill="#ff9a35" stroke="none"/>
        <path d="M {cx-4},99 Q {cx-7},109 {cx},117 Q {cx+7},109 {cx+4},99" fill="#fff4a6" stroke="none"/>
        <circle cx="{cx}" cy="60" r="8" fill="#36c9ee" stroke="#ecffff" stroke-width="3"/>
        <path d="M {cx-13},82 H {cx+13}" stroke="#fff2bd" stroke-width="6"/>
        </g>''')
    else:
        pen = SVGPathPen(glyphs)
        glyphs[cmap[ord(char)]].draw(pen)
        path = pen.getCommands()
        shapes.append(f'<path d="{path}" transform="translate({x+2} 105) scale({scale} {-scale})" fill="#142147" stroke="#142147" stroke-width="{4/scale}" stroke-linejoin="round"/>')
        shapes.append(f'<path d="{path}" transform="translate({x} 100) scale({scale} {-scale})" fill="url(#letter{i})" stroke="#e6faff" stroke-width="{.8/scale}" stroke-linejoin="round"/>')
    x += advance
svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{width*2}" height="260" viewBox="0 0 {width} 130"><title>КОСМОГОНКА: три О-планеты и А-ракета</title><defs>{"".join(defs)}</defs>{"".join(shapes)}</svg>'
(ROOT / 'assets/branding/menu-title.svg').write_text(svg, encoding='utf-8')
