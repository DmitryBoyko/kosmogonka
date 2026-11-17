from pathlib import Path
from math import cos, sin, radians
from PIL import Image, ImageDraw, ImageFilter

# Coordinates are in a centred, unit-width square. Every arrow points right.
def path(*points):
    return points

def chevron(x, size=1., offset=0.):
    return path((x-.12*size,-.25*size+offset),(x+.12*size,offset),(x-.12*size,.25*size+offset))

def arc(radius, start, end):
    return [(radius*cos(radians(a)),radius*sin(radians(a))) for a in range(start,end+1,4)]

def curve(a,b,c,d):
    return [tuple((1-t)**3*a[k]+3*t*(1-t)**2*b[k]+3*t*t*(1-t)*c[k]+t**3*d[k] for k in range(2))
            for t in (i/16 for i in range(17))]

classic = path((-.34,0),(.30,0),(.08,-.21))
back = path((.30,0),(.08,.21))
outline = path((-.34,-.12),(.02,-.12),(.02,-.28),(.33,0),(.02,.28),(.02,.12),(-.34,.12),(-.34,-.12))
outlined_chevron = path((-.17,-.26),(-.07,-.30),(.21,-.045),(.21,.045),(-.07,.30),(-.17,.26),(.06,0),(-.17,-.26))
designs = [
    ("Линия", [classic,back], []),
    ("Двойной шеврон",[chevron(-.16),chevron(.14)],[]),
    ("Три шеврона",[chevron(x,.85) for x in [-.24,0,.24]],[]),
    ("Открытый треугольник",[path((-.19,.15),(-.19,-.26),(.32,0),(-.09,.21))],[]),
    ("Капсула",[outline],[]),
    ("Луч",[path((-.35,-.16),(.01,-.16),(.01,-.27),(.34,0),(.01,.27),(.01,.16),(-.23,.16)),path((-.38,0),(-.044,0))],[]),
    ("Кольцо",[arc(.30,22,322),chevron(.02,.68)],[]),
    ("Матрица",[],[(x*.105,y*.105,.018) for y,row in zip(range(-2,3),[range(1,2),range(-3,3),range(-3,4),range(-3,3),range(1,2)]) for x in row]),
    ("Точечный шеврон",[],[(x+.101*(2-abs(y)),y*.106,.023) for y in range(-2,3) for x in [-.29,-.17,-.05,.07]]),
    ("Крыло",[path((-.34,-.25),(.39,0),(-.34,.25),(-.10,0),(-.34,-.25))],[]),
    ("Волна",[curve((-.36,.25),(-.22,-.03),(-.07,-.20),(.07,-.19))+[(.07,-.30),(.36,-.10),(.07,.13),(.07,.04)]+curve((.07,.04),(-.02,.02),(-.23,.10),(-.36,.25))],[]),
    ("Импульс",[outline,path((-.44,-.10),(-.44,.10))],[]),
    ("Три дорожки",[path((-.32,y),(.14-abs(y)*.66,y)) for y in [-.16,0,.16]]+[chevron(.23,1.)],[]),
    ("Двойная рамка",[outline,[(x*.72,y*.68) for x,y in outline]],[]),
    ("Ускорение",[[(x-.16,y) for x,y in outlined_chevron],[(x+.16,y) for x,y in outlined_chevron]],[]),
    ("Навигатор",[path((-.34,-.26),(.05,-.26),(.35,0),(.05,.26),(-.34,.26)),chevron(-.13,.72),chevron(.075,.72)],[]),
    ("Разрыв",[path((-.38,-.11),(-.13,-.11),(-.01,-.24),(.31,0),(-.01,.24),(-.13,.11),(-.27,.11))],[(-.40,.11,.024)]),
    ("Зигзаг",[path((-.37,.20),(-.20,.20),(-.04,-.03),(.26,-.03)),path((.10,-.22),(.32,-.03),(.10,.16))],[]),
    ("Комета",[path((-.22,-.10),(.03,-.10),(.03,-.26),(.35,0),(.03,.26),(.03,.10),(-.22,.10))],[(-.34,-.095,.022),(-.39,0,.022),(-.34,.095,.022)]),
    ("Шеврон в рамке",[arc(.34,210,510),chevron(.06,.85)],[]),
]

CELL = 192
PALETTE = ["ff164c","00baff","ffe21b","83ff00","ff18f5","00c7ff","2872ff","ff10dc","ffab08","63ff2c",
           "00d9ff","d927ff","f2f7ff","8cff14","ff1cad","ff224f","ffad16","4b72ff","ff21f1","00dcff"]

def masks(paths, dots):
    core = Image.new("L",(CELL*2,CELL*2))
    draw = ImageDraw.Draw(core)
    size = CELL*2
    width = round(size*.026)
    def px(p):
        return tuple(round((v+.5)*size) for v in p)
    def circle(at,r):
        x,y = at
        draw.ellipse((x-r,y-r,x+r,y+r),fill=255)
    for points in paths:
        pixels = [px(p) for p in points]
        draw.line(pixels,fill=255,width=width,joint="curve")
        for at in pixels:
            circle(at,width/2)
    for x,y,r in dots:
        circle(px((x,y)),r*size)
    near = core.filter(ImageFilter.GaussianBlur(size*.032))
    far = core.filter(ImageFilter.GaussianBlur(size*.079))
    return [im.resize((CELL,CELL),Image.Resampling.LANCZOS) for im in (core,near,far)]

def main():
    root = Path(__file__).resolve().parents[1]
    atlas = Image.new("RGB",(5*CELL,4*CELL))
    for i,(_,paths,dots) in enumerate(designs):
        atlas.paste(Image.merge("RGB",masks(paths,dots)),(i%5*CELL,i//5*CELL))
    atlas.save(root/"assets/surfaces/neon_arrows.png",optimize=True)

if __name__ == "__main__":
    main()
