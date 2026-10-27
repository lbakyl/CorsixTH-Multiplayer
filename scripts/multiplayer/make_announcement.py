#!/usr/bin/env python3
"""Make CorsixTH/Sounds/mp_player_left.wav, the multiplayer announcement
"Warning! A player has left the game." (a two-tone chime, then the voice
through a loudspeaker-like filter).

The voice is Piper (pip install piper-tts scipy) with en_GB-cori-high from
https://huggingface.co/rhasspy/piper-voices (trained on public domain
LibriVox recordings). Usage: make_announcement.py OUT.wav en_GB-cori-high.onnx
"""
import io
import sys
import wave

import numpy as np
from scipy import signal
from piper import PiperVoice

out = sys.argv[1]
voice = PiperVoice.load(sys.argv[2])
buf = io.BytesIO()
with wave.open(buf, "wb") as w:
    try:
        from piper import SynthesisConfig
        voice.synthesize_wav("Warning! A player has left the game.", w,
                             syn_config=SynthesisConfig(length_scale=1.08, noise_scale=0.6))
    except ImportError:
        voice.synthesize_wav("Warning! A player has left the game.", w)
buf.seek(0)
with wave.open(buf) as w:
    sr = w.getframerate()
    x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768
# Target rate 22050 like the game's own sounds.
SR = 22050
if sr != SR:
    x = signal.resample_poly(x, SR, sr)
# Trim silence.
idx = np.where(np.abs(x) > 0.01)[0]
x = x[max(0, idx[0] - 200): idx[-1] + 400]
# Loudspeaker: band-pass, a little drive, a small hall.
b, a = signal.butter(4, [380, 3600], btype="band", fs=SR)
y = signal.lfilter(b, a, x)
y = np.tanh(2.2 * y / np.max(np.abs(y))) / np.tanh(2.2)
rng = np.random.default_rng(7)
n = int(0.35 * SR)
ir = rng.standard_normal(n) * np.exp(-np.arange(n) / (0.07 * SR))
ir[0] = 0
wet = np.pad(signal.fftconvolve(y, ir), (0, 1))[: len(y) + n] * 0.035
y = np.concatenate([y, np.zeros(n)]) + wet
# Two-tone chime before it (bell-like partials, decaying).
def tone(f, dur):
    t = np.arange(int(dur * SR)) / SR
    env = np.exp(-t * 3.2) * np.minimum(1, t * 400)
    s = sum(amp * np.sin(2 * np.pi * f * k * t) for k, amp in ((1, 1), (2, 0.35), (3, 0.12), (4.2, 0.06)))
    return s * env
chime = np.concatenate([tone(784, 0.42), tone(622, 0.9)])
chime = chime / np.max(np.abs(chime)) * 0.55
gap = np.zeros(int(0.12 * SR))
z = np.concatenate([np.zeros(int(0.03 * SR)), chime, gap, y * 0.9, np.zeros(int(0.1 * SR))])
z = z / np.max(np.abs(z)) * 0.89
pcm = (z * 32767).astype(np.int16)
with wave.open(out, "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
print(out, len(pcm) / SR, "s")
