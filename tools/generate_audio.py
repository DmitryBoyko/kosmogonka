"""Original deterministic gameplay SFX only; human voices are never overwritten.
No external models, recordings, services or dependencies are used.
"""
import math
import random
import wave
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
RATE = 24000

def save(name, duration, fn):
    rng = random.Random(name)
    samples = []
    for i in range(int(duration * RATE)):
        t = i / RATE
        edge = min(1.0, t / 0.008, (duration - t) / 0.025)
        v = max(-0.92, min(0.92, fn(t, t / duration, rng) * edge))
        samples.append(int(v * 32767))
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(struct.pack('<' + 'h' * len(samples), *samples))

def tone(t, hz):
    return math.sin(2 * math.pi * hz * t)

ROOT.mkdir(parents=True, exist_ok=True)
save('star', .19, lambda t, x, r: .26 * (tone(t, 1046.5) + .35*tone(t, 1568)) * (1-x)**2)
save('jump', .23, lambda t, x, r: .3*math.sin(2*math.pi*(250*t+650*t*t))*(1-x))
save('land', .16, lambda t, x, r: (.2*tone(t, 90)+r.uniform(-.10,.10))*(1-x)**3)
save('step', .09, lambda t, x, r: (.07*tone(t, 170)+r.uniform(-.04,.04))*(1-x)**3)
save('slide', .28, lambda t, x, r: r.uniform(-.19,.19)*(1-x)**1.8)
save('hit', .33, lambda t, x, r: (.30*tone(t, 70)+.15*tone(t, 107)+r.uniform(-.12,.12))*(1-x)**2)
save('click', .09, lambda t, x, r: .2*tone(t, 740)*(1-x)**2)
save('boost', .55, lambda t, x, r: .24*math.sin(2*math.pi*(180*t+1100*t*t))*(1-x)+.09*r.uniform(-1,1)*(1-x))
save('warning', .62, lambda t, x, r: .19*tone(t, 660 if x<.45 else 880)*math.sin(math.pi*x)**2)
save('win', 1.25, lambda t, x, r: .25*tone(t, [523.25,659.25,783.99,1046.5][min(3,int(x*4))])*(.8-.4*x))
save('engine', 1.0, lambda t, x, r: .08*tone(t,96)+.05*tone(t,192)+.03*r.uniform(-1,1))
save('whoosh', .85, lambda t, x, r: r.uniform(-.23,.23)*math.sin(math.pi*x)**2+.06*tone(t,100+300*x))
for variant in range(3):
    save(f'honk{variant}', .3, lambda t,x,r,v=variant: .15*(tone(t,230+v*93)+.45*tone(t,345+v*140))*math.sin(math.pi*x)**2)

print('Generated 15 original SFX clips. Human voices are maintained by tools/prepare_voices.py.')
