"""Rebuild human voice assets from the checked-in CC0 originals. Requires ffmpeg."""
import hashlib
import json
import math
from pathlib import Path
import struct
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]


def main():
    manifest = json.loads((ROOT / 'docs/audio_sources/manifest.json').read_text(encoding='utf8'))
    for clip in manifest['clips']:
        source = ROOT / 'docs/audio_sources/nox' / clip['source']
        if hashlib.sha256(source.read_bytes()).hexdigest() != clip['source_sha256']:
            raise ValueError(f'Source checksum mismatch: {source}')
        factor = 2 ** (clip['pitch_semitones'] / 12)
        # Change pitch while preserving duration. Keep breaths at the edges; only
        # trim digital silence. No synthesized syllables, cloned voices or words.
        filters = (
            'silenceremove=start_periods=1:start_duration=0.005:start_threshold=-55dB,'
            'areverse,silenceremove=start_periods=1:start_duration=0.005:start_threshold=-55dB,areverse,'
            f'asetrate=48000*{factor:.10f},aresample=48000,atempo={1/factor:.10f},'
            'aresample=24000,'
            'afade=t=in:d=0.006,areverse,afade=t=in:d=0.012,areverse'
        )
        output = ROOT / 'assets/audio' / clip['output']
        subprocess.run([
            'ffmpeg', '-nostdin', '-v', 'error', '-y', '-i', str(source),
            '-af', filters, '-ac', '1', '-ar', '24000', '-c:a', 'pcm_s16le',
            '-map_metadata', '-1', str(output)
        ], check=True)
        # Integrated LUFS gating is unreliable for sub-400 ms vocal barks.
        # Match RMS across clips instead, with headroom for laugh transients.
        with wave.open(str(output), 'rb') as wav:
            samples = struct.unpack('<' + 'h' * wav.getnframes(), wav.readframes(wav.getnframes()))
        peak = max(abs(value) for value in samples) / 32768
        rms = math.sqrt(sum((value / 32768) ** 2 for value in samples) / len(samples))
        if rms < 0.0001:
            raise ValueError(f'Silent voice: {output}')
        gain = min(10 ** (-22 / 20) / rms, 10 ** (-5 / 20) / peak)
        with wave.open(str(output), 'wb') as wav:
            wav.setparams((1, 2, 24000, 0, 'NONE', 'not compressed'))
            wav.writeframes(struct.pack('<' + 'h' * len(samples), *(round(value * gain) for value in samples)))
    print(f"Prepared {len(manifest['clips'])} human voice clips (NOX SOUND, CC0).")


if __name__ == '__main__':
    main()
