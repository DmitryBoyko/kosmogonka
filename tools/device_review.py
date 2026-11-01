"""ADB visual QA with a temporary campaign profile; restore the user's profile afterwards.
Usage: prepare PLANET [FLIGHT_SOURCE], shot NAME, restore. Temporary files stay in build/.
"""
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build'
ADB = str(Path.home() / 'AppData/Local/Android/Sdk/platform-tools/adb.exe')
DEVICE = os.environ.get('COSMORACE_DEVICE')
if not DEVICE:
    devices = subprocess.check_output([ADB, 'devices'], text=True).splitlines()[1:]
    devices = [line.split()[0] for line in devices if '\tdevice' in line and not line.startswith('emulator-')]
    if len(devices) != 1:
        raise SystemExit('Set COSMORACE_DEVICE when there is not exactly one connected phone')
    DEVICE = devices[0]
PKG = 'space.easypeasymatch.cosmorace'
BACKUP = OUT / 'phone-original-profile.bin'
META = OUT / 'phone-profile-backup.json'

def adb(*args, data=None, check=True):
    return subprocess.run([ADB, '-s', DEVICE, *args], input=data, capture_output=True, check=check)

def write_profile(data):
    adb('shell', f"run-as {PKG} sh -c 'cat > files/cosmorace.cfg'", data=data)

def section_key(text, section, key, value):
    match = re.search(r'^\[' + re.escape(section) + r'\]\s*\n(.*?)(?=^\[|\Z)', text, re.M | re.S)
    if not match:
        return text.rstrip() + f'\n\n[{section}]\n{key}={value}\n'
    content = match.group(1)
    line = re.compile(r'^' + re.escape(key) + r'=.*$', re.M)
    content = line.sub(lambda _: f'{key}={value}', content) if line.search(content) else content.rstrip() + f'\n{key}={value}\n\n'
    return text[:match.start(1)] + content + text[match.end(1):]

mode = sys.argv[1]
if mode == 'prepare':
    adb('shell', 'am', 'force-stop', PKG)
    if META.exists() and json.loads(META.read_text(encoding='utf-8'))['device'] != DEVICE:
        raise RuntimeError('Existing backup belongs to another device; preserve it before continuing')
    if not META.exists() or json.loads(META.read_text(encoding='utf-8')).get('restored',False):
        result = adb('exec-out', 'run-as', PKG, 'cat', 'files/cosmorace.cfg', check=False)
        exists = result.returncode == 0
        BACKUP.write_bytes(result.stdout if exists else b'')
        META.write_text(json.dumps({'device': DEVICE, 'exists': exists}), encoding='utf-8')
    text = BACKUP.read_bytes().decode('utf-8-sig').replace('\r\n', '\n')
    for key, value in [('unlocked', '3'), ('selected', sys.argv[2])]:
        text = section_key(text, 'campaign', key, value)
    text = section_key(text, 'view', 'reduced_motion', 'true')
    flight = int(sys.argv[3]) if len(sys.argv) > 3 else None
    pending = '{}' if flight is None else '{"source": %d, "target": %d, "id": 900001}' % (flight, flight+1)
    text = section_key(text, 'campaign', 'pending_trip', pending)
    if flight is not None:
        text = section_key(text, 'campaign', 'trip_serial', '900001')
        text = section_key(text, 'campaign', 'last_trip_paid', '0')
    write_profile(text.encode('utf-8'))
    adb('shell', 'am', 'start', '-n', PKG + '/com.godot.game.GodotAppLauncher')
    time.sleep(3.5)
    print('Temporary QA profile; original backed up. Planet', sys.argv[2])
elif mode == 'shot':
    data = adb('exec-out', 'screencap', '-p').stdout
    target = OUT / (sys.argv[2] + '.png')
    target.write_bytes(data)
    try:
        from PIL import Image
        im = Image.open(target)
        im.thumbnail((432, 960))
        im.save(target.with_name(target.stem + '-preview.png'))
    except ImportError:
        pass
    print('Captured', target.name)
elif mode == 'restore':
    meta = json.loads(META.read_text(encoding='utf-8'))
    if meta['device'] != DEVICE:
        raise RuntimeError('Backup belongs to another device')
    adb('shell', 'am', 'force-stop', PKG)
    if meta['exists']:
        write_profile(BACKUP.read_bytes())
        actual = adb('exec-out', 'run-as', PKG, 'cat', 'files/cosmorace.cfg').stdout
        if actual != BACKUP.read_bytes():
            raise RuntimeError('Profile restoration verification failed')
    else:
        adb('shell', 'run-as', PKG, 'rm', '-f', 'files/cosmorace.cfg')
    meta['restored'] = True
    META.write_text(json.dumps(meta), encoding='utf-8')
    print('Original phone profile restored and verified.')
else:
    raise SystemExit('Use prepare, shot or restore')
