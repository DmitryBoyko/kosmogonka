"""Original synthesized action SFX. No voice recordings or external samples changed."""
import math,random,struct,wave
from pathlib import Path
RATE=24000
OUT=Path(__file__).resolve().parents[1]/'assets'/'audio'
def save(name,frames,fade=True):
    peak=max(abs(v) for pair in frames for v in pair)
    pcm=bytearray()
    for i,pair in enumerate(frames):
        edge=min(1.,i/(RATE*.008),(len(frames)-1-i)/(RATE*.025)) if fade else 1.
        pcm.extend(struct.pack('<hh',*(round(v/peak*.75*max(0.,edge)*32767) for v in pair)))
    with wave.open(str(OUT/(name+'.wav')),'wb') as stream:
        stream.setnchannels(2);stream.setsampwidth(2);stream.setframerate(RATE);stream.writeframes(pcm)
    print(name,len(frames)/RATE,'seconds')
rng=random.Random(501)
frames=[];low=0.
for i in range(int(.68*RATE)):
    t=i/RATE;white=rng.uniform(-1,1);low=.82*low+.18*white
    hiss=(white-low)*math.exp(-t*7)*min(1.,t*65)*.36
    servo=math.sin(math.tau*(210*t-85*t*t))*math.sin(math.pi*min(1.,t/.45))*.13 if t<.45 else 0.
    u=max(0.,t-.39);clunk=(math.sin(math.tau*88*u)+.35*math.sin(math.tau*470*u))*math.exp(-u*38)*.28 if t>=.39 else 0.
    value=hiss+servo+clunk;frames.append((value*.98,value))
save('glove_extend',frames)
frames=[]
for i in range(int(.85*RATE)):
    t=i/RATE;value=0.
    for start,f in [(0.,659.25),(.085,830.61),(.17,987.77),(.29,1318.51)]:
        u=t-start
        if u>=0:value+=(math.sin(math.tau*f*u)+.19*math.sin(math.tau*f*2.01*u))*(1-math.exp(-u*950))*math.exp(-u*9)
    frames.append((value,value*.96))
save('purchase_confirm',frames)
rng=random.Random(7001)
partials=[(rng.randrange(250,13000)/2.,rng.random()*math.tau,rng.random()*math.tau) for _ in range(36)]
frames=[]
for i in range(2*RATE):
    t=i/RATE;core=.18*math.sin(math.tau*92*t+1.6*math.sin(math.tau*.5*t))+.07*math.sin(math.tau*184*t)
    air=[sum(math.sin(math.tau*f*t+phases[channel]) for f,*phases in partials)/math.sqrt(len(partials)) for channel in range(2)]
    frames.append((core+air[0]*.11,core+air[1]*.11))
save('loop_jet',frames,False)
rng=random.Random(9007);frames=[];low=0.
for i in range(int(.9*RATE)):
    t=i/RATE;white=rng.uniform(-1,1);low=.90*low+.10*white
    value=.45*low*math.exp(-t*5)+.19*math.sin(math.tau*58*t)*math.exp(-t*11)+.07*white*math.exp(-t*22)
    frames.append((value,value*.93))
save('firework_burst',frames)
for variant in range(3):
    frames=[];phase=0.
    duration=[.56,.68,.49][variant]
    for i in range(int(duration*RATE)):
        t=i/RATE;u=t/duration
        frequency=[320.,470.,230.][variant]*(1.+.25*math.sin(math.tau*(3.+variant)*t)+.4*math.sin(math.pi*u))
        phase+=math.tau*frequency/RATE
        envelope=math.sin(math.pi*u)**.7*(.4+.6*max(0.,math.sin(math.tau*(5+variant)*t)))
        value=(math.sin(phase+1.3*math.sin(phase*.5))+.22*math.sin(phase*2.03))*envelope
        frames.append((value,value*.97))
    save('alien_chatter_'+str(variant),frames)
