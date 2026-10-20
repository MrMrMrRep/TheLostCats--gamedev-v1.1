"""Placeholder chiptune music and sound effects for The Lost Cats, synthesised
from scratch (no samples, no AI): square / triangle / sine voices and noise.
  audio/music/map_calm.wav     the world map and the base (90 BPM, lo-fi, loops)
  audio/music/level_tense.wav  levels (120 BPM, D minor, driving, loops)
  audio/sfx/*.wav              jump, land, hit, death, pickup, coin, door,
                               switch, bass, hack, lever, break, pound, punch,
                               squeak, talk, sleep
Re-run to rebuild: python3 tools/make_audio.py
"""
import math, os, random, struct, wave

RATE = 22050
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
random.seed(7)


def note(n):  # MIDI note -> Hz
    return 440.0 * 2 ** ((n - 69) / 12.0)


def write(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    gain = min(1.0, 0.9 / peak)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * gain)) * 32000)) for s in samples))
    print(os.path.relpath(path, ROOT), "%.1fs" % (len(samples) / RATE))


def osc(kind, phase):
    p = phase % 1.0
    if kind == "square":
        return 1.0 if p < 0.5 else -1.0
    if kind == "pulse":
        return 1.0 if p < 0.25 else -1.0
    if kind == "tri":
        return 4 * p - 1 if p < 0.5 else 3 - 4 * p
    if kind == "saw":
        return 2 * p - 1
    return math.sin(2 * math.pi * p)


def add(buf, start, length, freq, kind="square", vol=0.2, attack=0.005, decay=None, release=0.03, slide=0.0, vib=0.0):
    """One note into buf at sample `start`; `decay` = exponential decay time (s)."""
    n = int(length * RATE)
    ph = 0.0
    for i in range(n):
        t = i / RATE
        f = freq * (1 + slide * t) * (1 + vib * math.sin(2 * math.pi * 5.5 * t))
        ph += f / RATE
        env = min(1.0, t / attack) if attack > 0 else 1.0
        if decay:
            env *= math.exp(-t / decay)
        if t > length - release:
            env *= max(0.0, (length - t) / release)
        k = start + i
        if 0 <= k < len(buf):
            buf[k] += osc(kind, ph) * vol * env


def noise(buf, start, length, vol=0.2, decay=0.05, lowpass=0.0):
    n = int(length * RATE)
    last = 0.0
    for i in range(n):
        t = i / RATE
        s = random.uniform(-1, 1)
        last = last * lowpass + s * (1 - lowpass)
        k = start + i
        if 0 <= k < len(buf):
            buf[k] += last * vol * math.exp(-t / decay)


def drums(buf, beat, bars, kick_beats, snare_beats, hat_every, hat_vol=0.04, kick_vol=0.5, snare_vol=0.18):
    for bar in range(bars):
        for b in kick_beats:
            s = int((bar * 4 + b) * beat * RATE)
            add(buf, s, 0.18, 110, "sine", kick_vol, 0.001, 0.06, 0.02, slide=-2.5)
        for b in snare_beats:
            noise(buf, int((bar * 4 + b) * beat * RATE), 0.18, snare_vol, 0.06, 0.3)
        k = 0.0
        while k < 4:
            noise(buf, int((bar * 4 + k) * beat * RATE), 0.04, hat_vol, 0.012, 0.0)
            k += hat_every


def map_calm():
    bpm = 90
    beat = 60 / bpm
    bars = 8
    buf = [0.0] * int(bars * 4 * beat * RATE)
    # Cmaj7 - Am7 - Fmaj7 - G6, twice
    chords = [[48, 52, 55, 59], [45, 48, 52, 55], [41, 45, 48, 52], [43, 47, 50, 52]] * 2
    for bar, ch in enumerate(chords):
        t0 = bar * 4 * beat
        for b in (0, 2.5):                                    # soft electric-piano stabs
            for n in ch[1:]:
                add(buf, int((t0 + b * beat) * RATE), beat * 1.4, note(n + 12), "sine", 0.06, 0.01, 0.5)
        add(buf, int(t0 * RATE), beat * 1.8, note(ch[0] - 12), "tri", 0.22, 0.01, 0.9)          # bass
        add(buf, int((t0 + 2 * beat) * RATE), beat * 1.6, note(ch[0] - 12 + 7), "tri", 0.18, 0.01, 0.8)
        arp = ch + [ch[1] + 12]
        for k in range(8):                                     # a lazy arpeggio
            add(buf, int((t0 + k * beat / 2) * RATE), beat * 0.45, note(arp[k % len(arp)] + 24), "pulse", 0.025, 0.004, 0.12)
    # a small melody in the second half
    mel = [76, 74, 72, 74, 76, 79, 76, 74, 72, 69, 72, 74, 71, 72, 74, 72]
    for i, m in enumerate(mel):
        add(buf, int((16 * beat + i * beat) * RATE), beat * 0.9, note(m), "tri", 0.07, 0.01, 0.4, vib=0.004)
    drums(buf, beat, bars, [0, 2.5], [1, 3], 0.5, hat_vol=0.025, kick_vol=0.35, snare_vol=0.07)
    return buf


def level_tense():
    bpm = 120
    beat = 60 / bpm
    bars = 8
    buf = [0.0] * int(bars * 4 * beat * RATE)
    roots = [38, 34, 36, 33, 38, 34, 36, 37]                   # Dm Bb C A, then Dm Bb C C#dim
    minor = {38: [50, 53, 57], 34: [46, 50, 53], 36: [48, 52, 55], 33: [45, 49, 52], 37: [49, 52, 55]}
    for bar, r in enumerate(roots):
        t0 = bar * 4 * beat
        for k in range(8):                                     # driving eighth-note bass
            add(buf, int((t0 + k * beat / 2) * RATE), beat * 0.42, note(r - 12 + (12 if k % 4 == 3 else 0)), "square", 0.09, 0.002, 0.18)
        ch = minor[r]
        for k in range(16):                                    # staccato arpeggio, 16ths
            add(buf, int((t0 + k * beat / 4) * RATE), beat * 0.2, note(ch[k % 3] + 12), "pulse", 0.03, 0.002, 0.05)
    lead = [74, None, 72, 74, 77, None, 76, 74, 70, None, 69, 70, 72, 69, None, None]
    for i, m in enumerate(lead * 2):
        if m:
            add(buf, int((i * beat) * RATE), beat * 0.9, note(m), "square", 0.05, 0.01, 0.6, vib=0.006)
    drums(buf, beat, bars, [0, 1.5, 2, 3.5], [1, 3], 0.5, hat_vol=0.03, kick_vol=0.5, snare_vol=0.16)
    return buf


def sfx(length):
    return [0.0] * int(length * RATE)


def effects():
    out = {}
    b = sfx(0.18); add(b, 0, 0.16, 300, "square", 0.3, 0.002, 0.08, slide=3.0); out["jump"] = b
    b = sfx(0.12); noise(b, 0, 0.1, 0.5, 0.03, 0.6); add(b, 0, 0.08, 90, "sine", 0.4, 0.001, 0.03); out["land"] = b
    b = sfx(0.25); noise(b, 0, 0.12, 0.6, 0.04, 0.2); add(b, 0, 0.2, 180, "square", 0.3, 0.001, 0.06, slide=-1.5); out["hit"] = b
    b = sfx(0.8)
    for i, n in enumerate([72, 67, 63, 60]):
        add(b, int(i * 0.15 * RATE), 0.2, note(n), "square", 0.22, 0.003, 0.15)
    out["death"] = b
    b = sfx(0.22); add(b, 0, 0.08, note(84), "pulse", 0.25, 0.002); add(b, int(0.08 * RATE), 0.12, note(91), "pulse", 0.25, 0.002, 0.08); out["pickup"] = b
    b = sfx(0.35); add(b, 0, 0.07, note(88), "square", 0.2, 0.002); add(b, int(0.07 * RATE), 0.25, note(95), "square", 0.2, 0.002, 0.12); out["coin"] = b
    b = sfx(0.4); noise(b, 0, 0.3, 0.3, 0.12, 0.85); add(b, int(0.22 * RATE), 0.15, 70, "sine", 0.5, 0.001, 0.05); out["door"] = b
    b = sfx(0.1); add(b, 0, 0.08, note(79), "pulse", 0.22, 0.002, 0.04, slide=1.0); out["switch"] = b
    b = sfx(0.6); add(b, 0, 0.55, 55, "saw", 0.4, 0.01, 0.3, slide=0.6, vib=0.03); add(b, 0, 0.55, 110, "sine", 0.3, 0.01, 0.25, vib=0.03); out["bass"] = b
    b = sfx(0.5)
    for i in range(10):
        add(b, int(i * 0.045 * RATE), 0.035, note(random.choice([84, 86, 89, 91, 96])), "square", 0.15, 0.001)
    out["hack"] = b
    b = sfx(0.25); noise(b, 0, 0.05, 0.4, 0.015, 0.0); add(b, int(0.05 * RATE), 0.15, 140, "square", 0.25, 0.001, 0.05); out["lever"] = b
    b = sfx(0.5); noise(b, 0, 0.45, 0.6, 0.12, 0.4); add(b, 0, 0.2, 120, "square", 0.25, 0.001, 0.08, slide=-1.0); out["break"] = b
    b = sfx(0.5); add(b, 0, 0.4, 70, "sine", 0.8, 0.001, 0.15, slide=-0.8); noise(b, 0, 0.3, 0.5, 0.08, 0.7); out["pound"] = b
    b = sfx(0.15); noise(b, 0, 0.1, 0.5, 0.025, 0.3); add(b, 0, 0.08, 160, "square", 0.25, 0.001, 0.03); out["punch"] = b
    b = sfx(0.25); add(b, 0, 0.2, 1500, "square", 0.12, 0.002, 0.08, slide=1.8, vib=0.05); out["squeak"] = b
    b = sfx(0.05); add(b, 0, 0.04, note(76), "pulse", 0.12, 0.001, 0.02); out["talk"] = b
    b = sfx(1.2)
    for i, n in enumerate([67, 64, 60]):
        add(b, int(i * 0.25 * RATE), 0.6, note(n), "tri", 0.2, 0.05, 0.4)
    out["sleep"] = b
    return out


def main():
    write(os.path.join(ROOT, "audio/music/map_calm.wav"), map_calm())
    write(os.path.join(ROOT, "audio/music/level_tense.wav"), level_tense())
    for name, b in effects().items():
        write(os.path.join(ROOT, f"audio/sfx/{name}.wav"), b)


if __name__ == "__main__":
    main()
