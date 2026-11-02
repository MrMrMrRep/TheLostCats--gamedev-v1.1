#!/usr/bin/env python3
"""The van radio's songs, rendered once into looping WAVs (audio/radio/), so
the game only plays files. Synthesising them live, sample by sample in
GDScript, cost a lot of every frame and stuttered on phones whenever a frame
ran long. Same synth as before (scripts/world/van_radio.gd's CHANNELS: drums,
square bass, triangle pad chords, a seeded pentatonic lead, a soft low-pass):
each song is its 4-bar loop (the melody repeats every 64 steps), taken from
the second pass so the loop point is seamless.

    python3 -I tools/make_radio.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "audio/radio")
MAJOR = [0, 2, 4, 7, 9]
MINOR = [0, 3, 5, 7, 10]
# (channel index, song index, bpm, root, prog, minor, lead, seed): keep in step with VanRadio.CHANNELS.
SONGS = [
    (0, 0, 112, 57, [0, 7, 9, 5], False, 0, 11), (0, 1, 128, 52, [0, 5, 7, 5], True, 1, 23), (0, 2, 96, 60, [0, 9, 5, 7], False, 2, 5),
    (1, 0, 120, 55, [0, 5, 9, 7], False, 1, 31), (1, 1, 124, 53, [0, 0, 5, 7], False, 0, 47), (1, 2, 88, 58, [0, 7, 5, 5], False, 2, 9),
    (2, 0, 84, 50, [0, 8, 3, 10], True, 2, 61), (2, 1, 104, 49, [0, 3, 8, 7], True, 1, 77),
    (3, 0, 132, 52, [0, 3, 10, 7], True, 0, 83), (3, 1, 92, 55, [0, 5, 0, 7], False, 2, 97),
    (4, 0, 118, 57, [0, 0, 8, 10], True, 1, 101),
]


def freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def mix(seed, step):
    """A deterministic hash for the melody (seed, step)."""
    h = (seed * 2654435761 + step * 40503 + 0x9E3779B9) & 0xFFFFFFFF
    h ^= h >> 15
    h = (h * 2246822519) & 0xFFFFFFFF
    h ^= h >> 13
    return h


def render(bpm, root, prog, minor, lead, seed):
    step_len = RATE * 60.0 / bpm / 4.0
    loop = int(round(step_len * 64))
    rng = random.Random(seed)
    s = dict(kick=0.0, kp=0.0, snare=0.0, hat=0.0, bass=0.0, bp=0.0, bf=55.0, pad=0.0, pp=[0.0] * 3,
             pf=[220.0] * 3, lead=0.0, lp_=0.0, lf=440.0, last=0.0, lp=0.0)
    out = []
    dt = 1.0 / RATE
    cur = -1
    for t in range(loop * 2):
        step = int(t / step_len)
        if step != cur:
            cur = step
            pos = step % 16
            bar = (step // 16) % 4
            chord = prog[bar]
            minor_chord = minor if chord == 0 else chord in (2, 4, 9)
            if pos in (0, 8):
                s["kick"], s["kp"] = 1.0, 0.0
            if pos in (4, 12):
                s["snare"] = 1.0
            if pos % 2 == 0:
                s["hat"] = 0.8 if pos % 4 == 2 else 0.45
            if pos in (0, 3, 6, 8, 10, 14):
                s["bass"], s["bf"] = 1.0, freq(root - 24 + chord)
            if pos == 0:
                s["pad"] = 1.0
                third = 3 if minor_chord else 4
                s["pf"] = [freq(root + chord + k) for k in (0, third, 7)]
            h = mix(seed, step % 64)
            if pos % 2 == 0 and h % 100 < 55:
                scale = MINOR if minor else MAJOR
                n = scale[(h // 100) % 5] + 12 * ((h // 1000) % 2)
                s["lead"], s["lf"] = 1.0, freq(root + 12 + n)
        v = 0.0
        if s["kick"] > 0.001:
            s["kp"] += (45.0 + 110.0 * s["kick"] ** 2) * dt
            v += math.sin(s["kp"] * math.tau) * s["kick"] * 0.7
            s["kick"] *= 0.99935
        noise = rng.uniform(-1.0, 1.0)
        if s["snare"] > 0.001:
            v += noise * s["snare"] * 0.32
            s["snare"] *= 0.9991
        if s["hat"] > 0.001:
            v += (noise - s["last"]) * s["hat"] * 0.09
            s["hat"] *= 0.9965
        s["last"] = noise
        if s["bass"] > 0.001:
            s["bp"] = (s["bp"] + s["bf"] * dt) % 1.0
            v += (1.0 if s["bp"] < 0.5 else -1.0) * s["bass"] * 0.16
            s["bass"] *= 0.99988
        if s["pad"] > 0.001:
            for k in range(3):
                s["pp"][k] = (s["pp"][k] + s["pf"][k] * dt) % 1.0
                v += (abs(s["pp"][k] * 4.0 - 2.0) - 1.0) * s["pad"] * 0.05
            s["pad"] *= 0.99996
        if s["lead"] > 0.001:
            s["lp_"] = (s["lp_"] + s["lf"] * dt) % 1.0
            ph = s["lp_"]
            if lead == 0:
                w = 1.0 if ph < 0.25 else -1.0
            elif lead == 1:
                w = abs(ph * 4.0 - 2.0) - 1.0
            else:
                w = math.sin(ph * math.tau) + 0.3 * math.sin(ph * math.tau * 2.0)
            v += w * s["lead"] * 0.12
            s["lead"] *= 0.99975
        s["lp"] += (v - s["lp"]) * 0.32
        out.append(max(-0.9, min(0.9, s["lp"])))
    return out[loop:]                       # the second pass: its start carries the first pass's tails


def static():
    rng = random.Random(3)
    n = int(RATE * 0.35)
    return [rng.uniform(-0.35, 0.35) * (0.6 + 0.4 * math.sin((n - i) / RATE * 90.0)) for i in range(n)]


def write(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(x * 32000)) for x in samples))
    print(os.path.relpath(path, ROOT), "%.1fs" % (len(samples) / RATE))


if __name__ == "__main__":
    for ch, sg, *spec in SONGS:
        write(os.path.join(OUT, "radio_%d_%d.wav" % (ch, sg)), render(*spec))
    write(os.path.join(OUT, "static.wav"), static())
