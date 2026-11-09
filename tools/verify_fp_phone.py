"""Physical-device first-person campaign QA; restores the real profile in finally."""
import argparse,json,os,re,subprocess,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build'
ADB=str(Path(os.environ['LOCALAPPDATA'])/'Android/Sdk/platform-tools/adb.exe')
PKG='space.easypeasymatch.cosmorace'
KINDS=[['jet'],['board'],['jet','board'],['jet'],['jet','board'],['jet','board'],['jet','board'],['jet','board'],['jet','board','spiral'],['jet','board','spiral']]
class Device:
    def __init__(self):
        entries=subprocess.check_output([ADB,'devices'],text=True).splitlines()[1:]
        serials=[e.split()[0] for e in entries if '\tdevice' in e and not e.startswith('emulator-')]
        if len(serials)!=1:raise RuntimeError('Exactly one physical phone must be connected')
        self.base=[ADB,'-s',serials[0]]
    def adb(self,*args,data=None):return subprocess.run(self.base+list(args),input=data,capture_output=True,check=True).stdout
    def live(self):
        for _ in range(200):
            try:return json.loads(self.adb('exec-out','run-as',PKG,'cat','files/mobile_metrics.json'))
            except (subprocess.CalledProcessError,json.JSONDecodeError):time.sleep(.15)
        raise RuntimeError('No device telemetry')
    def command(self,action,**kwargs):
        payload=dict(action=action,id=time.time_ns()//1000000,**kwargs)
        self.adb('shell',f"run-as {PKG} sh -c 'cat > files/mobile_command.json'",data=json.dumps(payload).encode())
        return self.wait(lambda d:d['command']==payload['id'],60)
    def wait(self,predicate,timeout=30):
        end=time.monotonic()+timeout
        while time.monotonic()<end:
            d=self.live()
            if predicate(d):return d
            time.sleep(.25)
        raise RuntimeError('Timeout: '+str({k:d.get(k) for k in ['state','planet','distance','height','lives','loop_kind']}))
    def shot(self,name):
        p=OUT/(name+'.png');p.write_bytes(self.adb('exec-out','screencap','-p'))
        from PIL import Image
        im=Image.open(p);im.thumbnail((432,960));im.save(p.with_stem(p.stem+'-preview'))
def profile_tool(mode):subprocess.run([sys.executable,str(ROOT/'tools/mobile_perf.py'),mode],cwd=ROOT,check=True)
def run_world(device,world,result,diagnostic_only=False):
    print('WORLD',world,'preparing',flush=True)
    device.command('campaign_run',planet=world)
    phases=[]
    for kind in KINDS[world]+['round','rectangular','elevated']:
        device.command('audit',enabled=True)
        if kind in ['jet','board','spiral']:
            start={'jet':400,'board':1400,'spiral':2850}[kind]
            device.command('feature',kind=kind+'_loop',planet=world,pilot=True)
            device.wait(lambda d:d['loop_kind']==kind,12)
            if world in [0,1,9]:device.shot('fp-phone-w%d-%s'%(world,kind))
            d=device.wait(lambda d:not d['loop_kind'] and d['distance']>=start+55,18)
        elif kind=='elevated':
            device.command('feature',kind='tunnel',planet=world)
            device.wait(lambda d:d['regions'].get('elevated',{}).get('frames',0)>0,8)
            d=device.wait(lambda d:d['height']<.1 and d['distance']>690,15)
        else:
            device.command('feature',kind='basement',planet=world,index=0 if kind=='round' else 1)
            device.wait(lambda d:d['height']< -3,10)
            device.shot('fp-phone-w%d-%s'%(world,kind))
            d=device.wait(lambda d:d['height']>=-.05,14)
        audit=d['camera_audit'];phases.append({'kind':kind,'audit':audit})
        if kind in ['round','rectangular']:
            cleared=sum(v.get('kind')=='glove' and v.get('cleared',False) for v in d['coverage'].values())
            if cleared<2:raise RuntimeError('Both gloves must be cleared in targeted basement: '+kind)
        result['diagnostics']=phases
        print('WORLD',world,kind,'camera',audit,flush=True)
        if audit.get('collisions'):raise RuntimeError('Camera intersects geometry: world%d %s'%(world,kind))
        if not audit.get('samples'):raise RuntimeError('Camera audit collected no samples')
        device.command('audit',enabled=False)
    if diagnostic_only:return
    device.command('campaign_run',planet=world)
    end=time.monotonic()+320;next_update=0
    while time.monotonic()<end:
        d=device.live()
        if time.monotonic()>next_update:
            print('WORLD',world,'run',round(d['distance']),d['state'],'FPS',d['states'].get('run',{}).get('fps'),flush=True);next_update=time.monotonic()+20
        if d['state']!='run':break
        time.sleep(1)
    if d['state']!='explore':raise RuntimeError('Full run did not finish: '+str({k:d.get(k) for k in ['state','distance','lives']}))
    result.update({'finished':True,'lives':d['lives'],'stars':d['stars'],'metrics':d['states'].get('run'),'regions':d['regions'],'coverage':d['coverage'],'vehicles':d['vehicle_evidence']})
    for kind in KINDS[world]:
        if not d['coverage'].get(kind,{}).get('completed'):raise RuntimeError('Loop not completed: '+kind)
    if not d['coverage'].get('front_camera',{}).get('seen') or not d['coverage'].get('fp_restored',{}).get('seen'):raise RuntimeError('Automatic front view and first-person restoration not observed')
    print('WORLD',world,'COMPLETE',result['metrics'],flush=True)
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--worlds',nargs='+',type=int,default=list(range(10)));parser.add_argument('--diagnostic-only',action='store_true');parser.add_argument('--report',default='fp-phone-campaign.json');args=parser.parse_args()
    os.chdir(ROOT);sys.stdout.reconfigure(encoding='utf-8');device=Device();prepared=False
    report={'worlds':{},'errors':[],'profile_restored':False};target=OUT/args.report
    try:
        profile_tool('prepare');prepared=True;device.wait(lambda d:d['screen']=='menu',45)
        for world in args.worlds:
            report['worlds'][str(world)]={}
            run_world(device,world,report['worlds'][str(world)],args.diagnostic_only)
            target.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    except Exception as error:
        report['errors'].append(str(error));raise
    finally:
        if prepared:profile_tool('restore');report['profile_restored']=True
        target.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
if __name__=='__main__':main()
