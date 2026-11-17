"""Synthesize three distinct arcade pickup timbres without sampled audio."""
from pathlib import Path
from math import exp, sin, tau
from array import array
import wave

RATE = 44100
ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio"

def render(name, duration, strikes):
    frames = []
    for i in range(round(duration * RATE)):
        t = i / RATE
        left = right = 0.
        for start, pan, modes in strikes:
            age = t - start
            if age < 0:
                continue
            value = sum(level * sin(tau * frequency * age) * exp(-age * damping)
                        for frequency, level, damping in modes)
            value *= min(1., age * 1450) * min(1., (duration-t) * 100)
            left += value * (1 - pan)
            right += value * (1 + pan)
        frames.extend((left, right))
    gain = .74 * 32767 / max(map(abs, frames))
    with wave.open(str(ROOT / (name + ".wav")), "wb") as output:
        output.setparams((2, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(array("h", (round(sample * gain) for sample in frames)).tobytes())

coin = [(1360, .86, 29), (2510, .53, 46), (3820, .38, 78), (5920, .23, 171)]
glass = [(1730, .92, 13), (2790, .31, 29), (4160, .36, 34), (6250, .14, 76)]
render("pickup_gold", .19, [(0, -.17, coin), (.022, .13, [(f*1.1, a*.32, d) for f,a,d in coin])])
render("pickup_double", .31, [(0, -.18, glass), (.052, .21, [(f*1.22,a*.42,d) for f,a,d in glass])])
render("pickup_mega", .46, [
    (0, -.19, [(882, .52, 8), (1944, .29, 17), (3551, .14, 32)]),
    (.042, .13, [(1320, .57, 8), (2836, .23, 19), (4681, .16, 45)]),
    (.086, .04, [(1790, .72, 10), (3723, .21, 22), (5690, .12, 53)]),
])
