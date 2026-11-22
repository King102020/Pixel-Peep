"""Checks every ASCII level can be finished by the weakest jumper.

Run:  python tool/check_levels.py
A conservative grid search: from each standing spot a hero can walk, fall,
or jump up to 3 tiles high and 3 tiles across (4 when not going up).
Trampolines and fans allow 8 tiles up. Reports levels where the exit (E)
can't be reached from the spawn (P). Not a physics sim; it catches layouts
with ledges that are too tall or gaps too wide.
"""
import sys
from collections import deque
from pathlib import Path

SRC = Path(__file__).resolve().parent / "levels"
SOLID = "#"
STAND_ON = "#=_X"
UP, ACROSS, ACROSS_FLAT, BOOST = 3, 3, 4, 8


def load(path):
    rows = path.read_text().rstrip("\n").split("\n")[1:]
    w = max(map(len, rows))
    g = [list(r.ljust(w)) for r in rows]
    floor = max(i for i, r in enumerate(rows) if "P" in r) + 1
    for c in range(w):  # mirror gen_levels: floor gaps are bottomless
        if g[floor][c] == " ":
            for r in range(floor, len(g)):
                g[r][c] = " "
    return g


def standable(g, r, c):
    return (0 <= r < len(g) - 1 and 0 <= c < len(g[0])
            and g[r][c] not in SOLID + "X" and g[r + 1][c] in STAND_ON)


def fall(g, r, c):
    while r < len(g) - 1 and g[r][c] not in SOLID:
        if g[r + 1][c] in STAND_ON:
            return r
        r += 1
    return None


def reachable(g):
    h, w = len(g), len(g[0])
    find = lambda ch: next((r, c) for r in range(h) for c in range(w) if g[r][c] == ch)
    start, end = find("P"), find("E")
    seen, q = {start}, deque([start])
    while q:
        r, c = q.popleft()
        if (r, c) == end or (abs(r - end[0]) <= 1 and c == end[1]):
            return True
        boost = g[r][c] in "TW" or (r + 1 < h and g[r + 1][c] in "TW")
        up = BOOST if boost else UP
        for dr in range(-up, h):
            for dc in range(-ACROSS_FLAT, ACROSS_FLAT + 1):
                if dr < 0 and abs(dc) > ACROSS and not boost:
                    continue
                nr, nc = r + dr, c + dc
                if not (0 <= nr < h and 0 <= nc < w):
                    continue
                if dr > 0 and abs(dc) > 0:
                    # Only consider landing by falling from an air column.
                    landing = fall(g, r, nc) if g[r][nc] not in SOLID else None
                    if landing != nr:
                        continue
                if standable(g, nr, nc) and (nr, nc) not in seen:
                    seen.add((nr, nc))
                    q.append((nr, nc))
    return False


if __name__ == "__main__":
    bad = [p.stem for p in sorted(SRC.glob("*.txt")) if not reachable(load(p))]
    print("unreachable exits:", ", ".join(bad) if bad else "none")
    sys.exit(1 if bad else 0)


def furthest(g):
    """Column furthest right the search reached (for debugging layouts)."""
    h = len(g)
    start = next((r, c) for r in range(h) for c in range(len(g[0])) if g[r][c] == "P")
    seen, q = {start}, deque([start])
    while q:
        r, c = q.popleft()
        boost = g[r][c] in "TW" or (r + 1 < h and g[r + 1][c] in "TW")
        up = BOOST if boost else UP
        for dr in range(-up, h):
            for dc in range(-ACROSS_FLAT, ACROSS_FLAT + 1):
                if dr < 0 and abs(dc) > ACROSS and not boost:
                    continue
                nr, nc = r + dr, c + dc
                if not (0 <= nr < h and 0 <= nc < len(g[0])):
                    continue
                if dr > 0 and abs(dc) > 0:
                    landing = fall(g, r, nc) if g[r][nc] not in SOLID else None
                    if landing != nr:
                        continue
                if standable(g, nr, nc) and (nr, nc) not in seen:
                    seen.add((nr, nc))
                    q.append((nr, nc))
    return max(seen, key=lambda p: p[1])
