"""Physical-device QA. Isolates the user's profile; native taps use the live UI rectangles."""
import hashlib,json,os,subprocess,sys,time
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build'
ADB=str(Path(os.environ['LOCALAPPDATA'])/'Android/Sdk/platform-tools/adb.exe')
devices=subprocess.check_output([ADB,'devices'],text=True).splitlines()[1:]
devices=[line.split()[0] for line in devices if '\tdevice' in line and not line.startswith('emulator-')]
if len(devices)!=1: raise SystemExit('Exactly one authorized physical phone is required')
BASE=[ADB,'-s',devices[0]]
PKG='space.easypeasymatch.cosmorace'
BACKUP=OUT/'mobile-opt-original.cfg'
META=OUT/'mobile-opt-backup.json'
def adb(*args,data=None,check=True): return subprocess.run(BASE+list(args),input=data,capture_output=True,check=check)
def read(name):
    for attempt in range(120):
        data=adb('exec-out','run-as',PKG,'cat','files/'+name).stdout
        if data and not data.startswith(b"cat:"):
            if name.endswith(".json"):
                try: json.loads(data)
                except json.JSONDecodeError: time.sleep(.1); continue
            return data
        time.sleep(.25)
    raise RuntimeError('QA file is empty: '+name)
def write(name,data): adb('shell',f"run-as {PKG} sh -c 'cat > files/{name}'",data=data)
def launch(): adb('shell','am','start','-n',PKG+'/com.godot.game.GodotAppLauncher')
mode=sys.argv[1]
if mode=='prepare':
    adb('shell','am','force-stop',PKG)
    if META.exists() and not json.loads(META.read_text()).get('restored',False): raise SystemExit('Unrestored backup exists; restore it first')
    original=read('cosmorace.cfg'); BACKUP.write_bytes(original)
    META.write_text(json.dumps({'device':devices[0],'sha256':hashlib.sha256(original).hexdigest(),'restored':False}))
    sys.path.insert(0,str(ROOT/'tools'))
    # Isolated QA profile. User data is restored byte-for-byte afterwards.
    text='[game]\nhero=0\n\n[campaign]\nunlocked=9\nselected=0\nbank=25000\n\n[view]\nquality=true\nreduced_motion=false\n'
    write('cosmorace.cfg',text.encode()); write('mobile_probe.json',b'{}'); launch()
    print('Original profile backed up; isolated QA profile activated')
elif mode=='restore':
    meta=json.loads(META.read_text()); assert meta['device']==devices[0]
    original=BACKUP.read_bytes(); assert hashlib.sha256(original).hexdigest()==meta['sha256']
    adb('shell','am','force-stop',PKG)
    write('cosmorace.cfg',original)
    for name in ['mobile_probe.json','mobile_command.json','mobile_metrics.json']: adb('shell','run-as',PKG,'rm','-f','files/'+name)
    assert read('cosmorace.cfg')==original
    meta['restored']=True; META.write_text(json.dumps(meta)); launch(); print('Original profile restored and verified byte-for-byte')
elif mode=='command':
    payload=json.loads(sys.argv[2]); payload['id']=time.time_ns()//1000000
    write('mobile_command.json',json.dumps(payload).encode())
    for attempt in range(120):
        try:
            if json.loads(read('mobile_metrics.json'))['command']==payload['id']: break
        except (subprocess.CalledProcessError,json.JSONDecodeError): pass
        time.sleep(.25)
    else: raise RuntimeError('QA command did not complete')
    print(payload['id'])
elif mode=='status':
    data=read('mobile_metrics.json'); (OUT/'mobile-live.json').write_bytes(data)
    result=json.loads(data)
    print(json.dumps(result,ensure_ascii=False,indent=2))
elif mode=='snapshot':
    data=read('mobile_metrics.json'); (OUT/(sys.argv[2]+'.json')).write_bytes(data)
    result=json.loads(data); print(json.dumps({'state':result['state'],'distance':result['distance'],'bank':result['bank'],'gear':result['gear'],'states':result['states']},ensure_ascii=False))
elif mode=='tap':
    for attempt in range(40):
        result=json.loads(read('mobile_metrics.json')); button=next((b for b in result['buttons'] if b['command']==sys.argv[2] and not b['disabled']),None)
        if button: break
        time.sleep(.25)
    else: raise RuntimeError('Enabled button not found: '+sys.argv[2])
    rect=button['rect']; import re
    dimensions=adb('shell','wm','size').stdout.decode(); width,height=map(int,re.search(r'(\d+)x(\d+)',dimensions).groups())
    x=(rect[0]+rect[2]/2)*width/result['ui_size'][0]; y=(rect[1]+rect[3]/2)*height/result['ui_size'][1]
    adb('shell','input','tap',str(round(x)),str(round(y))); print('Tapped',sys.argv[2])
elif mode=='shot':
    target=OUT/(sys.argv[2]+'.png'); target.write_bytes(adb('exec-out','screencap','-p').stdout)
    from PIL import Image
    im=Image.open(target); im.thumbnail((432,960)); im.save(target.with_name(target.stem+'-preview.png')); print(target)
elif mode=='save_check': (OUT/'mobile-purchase-check.cfg').write_bytes(read('cosmorace.cfg')); print('Purchase profile checkpoint saved')
elif mode=='verify_save':
    assert read('cosmorace.cfg')==(OUT/'mobile-purchase-check.cfg').read_bytes(); print('Purchased inventory and both hero outfits persist byte-for-byte')
elif mode=='restart': adb('shell','am','force-stop',PKG); launch()
elif mode=='measure':
    adb('shell','dumpsys','SurfaceFlinger','--timestats','-enable','-clear')
    time.sleep(float(sys.argv[3]) if len(sys.argv)>3 else 10)
    data=adb('shell','dumpsys','SurfaceFlinger','--timestats','-dump').stdout.decode()
    (OUT/(sys.argv[2]+'-surface.txt')).write_text(data,encoding='utf-8')
    import re
    matches=re.findall(r'layerName = ([^\n]*cosmorace[^\n]*SurfaceView[^\n]*|[^\n]*SurfaceView[^\n]*cosmorace[^\n]*)\n(.*?)(?=\n\ndisplayRefreshRate|\Z)',data,re.S)
    for name,block in matches:
        fields={k:v for k,v in re.findall(r'^(averageFPS|totalFrames|jankyFrames|droppedFrames) = ([^\n]+)',block,re.M)}
        print(json.dumps({'layer':name,**fields}))
else: raise SystemExit('prepare/restore/command/status/tap/shot/restart/measure')
