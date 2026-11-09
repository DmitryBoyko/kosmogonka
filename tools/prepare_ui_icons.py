"""Vendor the small ISC/MIT Lucide subset used by the game's action buttons."""
from pathlib import Path
from urllib.request import urlopen
from concurrent.futures import ThreadPoolExecutor
ROOT=Path(__file__).resolve().parents[1]/'assets/ui/icons'
ROOT.mkdir(parents=True,exist_ok=True)
NAMES=['eye','person-standing','play','settings-2','rocket','orbit','house','rotate-ccw','check','shirt','shopping-bag','shopping-cart','x','backpack','layers','flower-2']
def download(name):
    url='https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/'+name+'.svg'
    data=urlopen(url,timeout=30).read().decode().replace('currentColor','#d8f7ff').replace('width="24"','width="96"').replace('height="24"','height="96"')
    (ROOT/(name+'.svg')).write_text(data,encoding='utf-8')
    return name
with ThreadPoolExecutor(max_workers=6) as pool:print(list(pool.map(download,NAMES)))
(ROOT/'LICENSE.txt').write_bytes(urlopen('https://raw.githubusercontent.com/lucide-icons/lucide/main/LICENSE',timeout=30).read())
(ROOT/'SOURCE.txt').write_text('Lucide official repository: https://github.com/lucide-icons/lucide\nISC/MIT notices: LICENSE.txt\nProduction changes: mint-white stroke, 96 px SVG rasterization size.\n',encoding='utf-8')
