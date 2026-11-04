"""Original arcade bell synthesis; no sampled game sounds or external assets."""
from pathlib import Path
import math, wave, struct
RATE=44100
ROOT=Path(__file__).resolve().parents[1]/'assets'/'audio'
def render(name, notes, duration):
    frames=[]
    for i in range(int(duration*RATE)):
        t=i/RATE; left=right=0.
        for start,freq,gain,pan in notes:
            u=t-start
            if u<0: continue
            attack=1-math.exp(-u*1800)
            release=min(1.,max(0.,(duration-t)/.025))
            bell=(math.sin(math.tau*freq*u)*math.exp(-u*18)
                  +.28*math.sin(math.tau*freq*2*u)*math.exp(-u*32)
                  +.09*math.sin(math.tau*freq*3.01*u)*math.exp(-u*52))
            value=bell*attack*release*gain
            left+=value*(1-pan*.25);right+=value*(1+pan*.25)
        frames.extend((left,right))
    peak=max(abs(v) for v in frames)
    assert peak>0
    pcm=b''.join(struct.pack('<h',round(v/peak*.75*32767)) for v in frames)
    with wave.open(str(ROOT/(name+'.wav')),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(pcm)
    print(name, duration, 'seconds; stereo; peak -2.5 dBFS')
render('pickup_gold',[(0,1046.5,1,0)],.19)
render('pickup_double',[(0,783.99,.75,-.5),(.045,1174.66,1,.5),(0,1567.98,.18,.2)],.32)
render('pickup_mega',[(0,783.99,.7,-.5),(.045,987.77,.75,0),(.09,1567.98,1,.5),(0,391.995,.24,0)],.43)
