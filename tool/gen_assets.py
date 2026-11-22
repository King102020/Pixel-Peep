"""Generates enemy sprite sheets and chiptune audio for Pixel Peep.

Usage (from repo root):  python tool/gen_assets.py
Requires Pillow. Outputs are committed; re-run only to regenerate.
"""
import math
import random
import struct
import wave
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ENEMIES = ROOT / "assets" / "images" / "Enemies"
SFX = ROOT / "assets" / "audio" / "sfx"
MUSIC = ROOT / "assets" / "audio" / "music"
FRAME = 32
OUTLINE = (34, 32, 52, 255)
WHITE = (255, 255, 255, 255)
HIT = (255, 255, 255, 255)

# --------------------------------------------------------------------------- sprites


def strip(frames):
    sheet = Image.new("RGBA", (FRAME * len(frames), FRAME), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * FRAME, 0))
    return sheet


def save(sheet, enemy, state):
    out = ENEMIES / enemy
    out.mkdir(parents=True, exist_ok=True)
    sheet.save(out / f"{state} (32x32).png")


def eye(d, x, y):
    d.rectangle([x, y, x + 2, y + 3], fill=WHITE)
    d.rectangle([x + 1, y + 1, x + 2, y + 3], fill=OUTLINE)


def slime_frame(t, body=(92, 214, 92, 255), shade=(48, 150, 64, 255), flash=False):
    """t in [0,1): squash/stretch phase."""
    img = Image.new("RGBA", (FRAME, FRAME))
    d = ImageDraw.Draw(img)
    s = math.sin(t * 2 * math.pi)
    w = int(22 + 3 * s)
    h = int(16 - 3 * s)
    x0, y1 = (FRAME - w) // 2, 30
    y0 = y1 - h
    fill = HIT if flash else body
    d.ellipse([x0 - 1, y0 - 1, x0 + w + 1, y1 + 1], fill=OUTLINE)
    d.ellipse([x0, y0, x0 + w, y1], fill=fill)
    if not flash:
        d.rectangle([x0 + 2, y1 - 3, x0 + w - 2, y1 - 1], fill=shade)
        d.rectangle([x0 + 4, y0 + 2, x0 + 6, y0 + 3], fill=(200, 255, 200, 255))
    eye(d, FRAME // 2 - 5, y0 + h // 3)
    eye(d, FRAME // 2 + 2, y0 + h // 3)
    return img


def bat_frame(t, flash=False):
    img = Image.new("RGBA", (FRAME, FRAME))
    d = ImageDraw.Draw(img)
    body = HIT if flash else (130, 80, 190, 255)
    wing = HIT if flash else (90, 50, 140, 255)
    cy = 15 + int(2 * math.sin(t * 2 * math.pi))
    flap = int(7 * math.sin(t * 2 * math.pi))
    for side in (-1, 1):
        tip = (16 + side * 15, cy - flap)
        pts = [(16 + side * 4, cy - 2), tip, (16 + side * 11, cy + 4), (16 + side * 6, cy + 3)]
        d.polygon(pts, fill=wing, outline=OUTLINE)
    d.ellipse([10, cy - 6, 22, cy + 6], fill=body, outline=OUTLINE)
    d.polygon([(11, cy - 5), (12, cy - 9), (14, cy - 5)], fill=body, outline=OUTLINE)
    d.polygon([(18, cy - 5), (20, cy - 9), (21, cy - 5)], fill=body, outline=OUTLINE)
    d.rectangle([13, cy - 2, 14, cy - 1], fill=(255, 220, 60, 255))
    d.rectangle([18, cy - 2, 19, cy - 1], fill=(255, 220, 60, 255))
    d.point([(15, cy + 3), (17, cy + 3)], fill=WHITE)
    return img


def golem_frame(t, flash=False):
    img = Image.new("RGBA", (FRAME, FRAME))
    d = ImageDraw.Draw(img)
    rock = HIT if flash else (140, 128, 116, 255)
    dark = HIT if flash else (96, 86, 78, 255)
    step = math.sin(t * 2 * math.pi)
    bob = int(abs(step) * 1.5)
    # legs
    d.rectangle([9, 24, 14, 31 - max(0, int(2 * step))], fill=dark, outline=OUTLINE)
    d.rectangle([18, 24, 23, 31 - max(0, int(-2 * step))], fill=dark, outline=OUTLINE)
    # body
    d.rectangle([6, 9 - bob, 26, 26 - bob], fill=rock, outline=OUTLINE)
    # arms swing
    a = int(2 * step)
    d.rectangle([2, 13 - bob + a, 6, 23 - bob + a], fill=dark, outline=OUTLINE)
    d.rectangle([26, 13 - bob - a, 30, 23 - bob - a], fill=dark, outline=OUTLINE)
    if not flash:
        d.line([(10, 20 - bob), (14, 23 - bob)], fill=dark)
        d.line([(20, 11 - bob), (23, 15 - bob)], fill=dark)
    # glowing eyes
    d.rectangle([10, 13 - bob, 13, 15 - bob], fill=(255, 120, 40, 255))
    d.rectangle([19, 13 - bob, 22, 15 - bob], fill=(255, 120, 40, 255))
    return img


def hit_frames(fn, n=5):
    return [fn(i / n, flash=(i % 2 == 0)) for i in range(n)]


def make_sprites():
    save(strip([slime_frame(i / 6) for i in range(6)]), "Slime", "Idle")
    save(strip([slime_frame(i / 6 * 2 % 1) for i in range(6)]), "Slime", "Run")
    save(strip(hit_frames(slime_frame)), "Slime", "Hit")
    save(strip([bat_frame(i / 6) for i in range(6)]), "Bat", "Fly")
    save(strip(hit_frames(bat_frame)), "Bat", "Hit")
    save(strip([golem_frame(i / 8) for i in range(8)]), "Rock Golem", "Walk")
    save(strip(hit_frames(golem_frame)), "Rock Golem", "Hit")


# --------------------------------------------------------------------------- audio

RATE = 22050


def square(f, t, duty=0.5):
    return 1.0 if (t * f) % 1.0 < duty else -1.0


def tone(freqs, dur, vol=0.35, duty=0.5, decay=4.0, wave_fn=square):
    """freqs: callable(progress)->Hz or constant."""
    n = int(RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        p = i / n
        f = freqs(p) if callable(freqs) else freqs
        phase += f / RATE
        env = math.exp(-decay * p) * min(1.0, i / 80)
        out.append(vol * env * (1.0 if phase % 1.0 < duty else -1.0))
    return out


def noise(dur, vol=0.35, decay=6.0):
    rnd = random.Random(7)
    n = int(RATE * dur)
    return [vol * math.exp(-decay * i / n) * rnd.uniform(-1, 1) for i in range(n)]


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def mix(a, b):
    n = max(len(a), len(b))
    return [(a[i] if i < len(a) else 0) + (b[i] if i < len(b) else 0) for i in range(n)]


def write_wav(path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32000)) for s in samples))


def note(n):
    """MIDI note -> Hz."""
    return 440.0 * 2 ** ((n - 69) / 12)


def make_sfx():
    write_wav(SFX / "jump.wav", tone(lambda p: 300 + 500 * p, 0.15, duty=0.25))
    write_wav(SFX / "double_jump.wav", seq(tone(lambda p: 400 + 400 * p, 0.08, duty=0.25),
                                          tone(lambda p: 600 + 600 * p, 0.12, duty=0.25)))
    write_wav(SFX / "collect_fruit.wav", seq(tone(note(84), 0.06, decay=1), tone(note(91), 0.14)))
    write_wav(SFX / "hit.wav", mix(tone(lambda p: 220 - 150 * p, 0.25, duty=0.5), noise(0.2, 0.25)))
    write_wav(SFX / "enemy_defeat.wav", seq(tone(lambda p: 600 - 400 * p, 0.12), noise(0.15, 0.3)))
    write_wav(SFX / "dash.wav", noise(0.18, 0.3, decay=3))
    write_wav(SFX / "checkpoint.wav", seq(*[tone(note(n), 0.08, decay=1.5) for n in (72, 76, 79)]))
    write_wav(SFX / "level_complete.wav",
              seq(*[tone(note(n), d, decay=1.5) for n, d in ((72, .1), (76, .1), (79, .1), (84, .35))]))
    write_wav(SFX / "button_click.wav", tone(note(88), 0.04, decay=6, duty=0.25))


def loop(melody, bass, bpm):
    beat = 60 / bpm / 2  # eighth notes
    lead = seq(*[tone(note(n), beat, 0.18, duty=0.25, decay=2) if n else [0] * int(RATE * beat)
                 for n in melody])
    low = seq(*[tone(note(n), beat * 2, 0.16, duty=0.5, decay=1) for n in bass])
    return mix(lead, low)


def make_music():
    menu_mel = [72, 0, 76, 79, 81, 79, 76, 0, 74, 0, 77, 81, 79, 77, 74, 0] * 2
    menu_bass = [48, 48, 55, 55, 50, 50, 53, 53] * 2
    write_wav(MUSIC / "menu_loop.wav", loop(menu_mel, menu_bass, 110))
    lvl_mel = [76, 76, 0, 76, 0, 72, 76, 0, 79, 0, 0, 0, 67, 0, 0, 0,
               72, 0, 67, 0, 64, 0, 69, 71, 70, 69, 67, 76, 79, 81, 77, 79] * 2
    lvl_bass = [48, 52, 55, 52, 43, 47, 50, 47, 45, 48, 52, 48, 41, 45, 48, 43]
    write_wav(MUSIC / "level_loop.wav", loop(lvl_mel, lvl_bass, 140))


if __name__ == "__main__":
    make_sprites()
    make_sfx()
    make_music()
    print("Assets generated.")
