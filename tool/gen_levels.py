"""Builds Tiled (.tmx) levels from ASCII layouts in tool/levels/*.txt.

Usage (from repo root):  python tool/gen_levels.py
Levels stay fully editable in Tiled afterwards; the ASCII files are just a
fast way to block out layouts.

Legend
  #  ground (grass/sand/pink top picked per theme)   =  one-way platform
  P  player spawn       F  fruit          C  checkpoint     E  end flag
  ^  spikes             S  saw (horiz.)   s  saw (vertical) T  trampoline
  W  fan (blows up)     _  falling platf. f  fire           X  breakable box
  g  slime              b  bat            G  rock golem     B  boss golem
First line of each file:  key=value pairs, e.g.  theme=grass bg=Green time=60
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "tool" / "levels"
OUT = ROOT / "assets" / "tiles"
TILE = 16
COLS = 22  # columns in Terrain (16x16).png

THEMES = {  # top-left tile (row, col) of each 3x3 ground block
    "grass": (0, 6),
    "orange": (4, 6),
    "pink": (8, 6),
}
PLATFORM = [40, 41, 42]  # thin wooden strip

OBJECTS = {
    "P": ("Player", 32, 32), "F": ("Fruit", 32, 32), "C": ("Checkpoint", 64, 64),
    "E": ("End", 64, 64), "^": ("Spikes", 16, 16), "S": ("Saw", 32, 32),
    "s": ("Saw", 32, 32), "T": ("Trampoline", 28, 28), "W": ("Fan", 24, 8),
    "_": ("FallingPlatform", 32, 10), "f": ("Fire", 16, 32), "X": ("Box", 28, 24),
    "g": ("Slime", 32, 32), "b": ("Bat", 32, 32), "G": ("Golem", 32, 32),
    "B": ("Boss", 64, 64),
}
FRUITS = ["Apple", "Bananas", "Cherries", "Kiwi", "Melon", "Orange", "Pineapple", "Strawberry"]


def gid(row, col):
    return row * COLS + col + 1


def ground_tile(grid, r, c, theme):
    tr, tc = THEMES[theme]
    def solid(rr, cc):
        # Out of bounds above or sideways counts as solid, so border walls
        # render as dirt rather than grass.
        if rr < 0 or cc < 0 or cc >= len(grid[0]):
            return True
        return rr < len(grid) and grid[rr][cc] == "#"
    row = 0 if not solid(r - 1, c) else (2 if not solid(r + 1, c) else 1)
    col = 0 if not solid(r, c - 1) else (2 if not solid(r, c + 1) else 1)
    return gid(tr + row, tc + col)


def build(path):
    lines = path.read_text().rstrip("\n").split("\n")
    meta = dict(kv.split("=") for kv in lines[0].split())
    rows = lines[1:]
    width = max(len(r) for r in rows)
    grid = [list(r.ljust(width)) for r in rows]
    # A gap in the floor row is a bottomless pit: clear everything below it.
    floor = max(i for i, r in enumerate(rows) if "P" in r) + 1
    for c in range(width):
        if grid[floor][c] == " ":
            for r in range(floor, len(grid)):
                grid[r][c] = " "
    height = len(grid)
    theme = meta.get("theme", "grass")

    tiles = []
    for r in range(height):
        row = []
        for c in range(width):
            ch = grid[r][c]
            if ch == "#":
                row.append(ground_tile(grid, r, c, theme))
            elif ch == "=":
                left = c > 0 and grid[r][c - 1] == "="
                right = c + 1 < width and grid[r][c + 1] == "="
                row.append(PLATFORM[1] if left and right else PLATFORM[0] if right else PLATFORM[2] if left else PLATFORM[1])
            else:
                row.append(0)
        tiles.append(row)

    objects, oid = [], 1
    # Collisions: merge horizontal runs per row.
    for r in range(height):
        c = 0
        while c < width:
            ch = grid[r][c]
            if ch in "#=":
                start = c
                while c < width and grid[r][c] == ch:
                    c += 1
                kind = ' type="Platform"' if ch == "=" else ""
                h = 5 if ch == "=" else TILE
                objects.append(("Collisions", f'<object id="{oid}"{kind} x="{start*TILE}" y="{r*TILE}" width="{(c-start)*TILE}" height="{h}"/>'))
                oid += 1
            else:
                c += 1

    fruit_i = 0
    for r in range(height):
        for c in range(width):
            ch = grid[r][c]
            if ch not in OBJECTS:
                continue
            name, w, h = OBJECTS[ch]
            # Anchor: objects sit on the bottom of their tile, centred horizontally.
            x = c * TILE + (TILE - w) / 2
            y = (r + 1) * TILE - h
            props = {}
            if name == "Fruit":
                props["fruit"] = FRUITS[fruit_i % len(FRUITS)]
                fruit_i += 1
                y = r * TILE - 8
            if name == "Saw":
                props["isVertical"] = "true" if ch == "s" else "false"
                props["offNeg"] = "3"
                props["offPos"] = "3"
                y = r * TILE - 8
            if name in ("Bat", "Spikes", "FallingPlatform", "Fan"):
                if name == "FallingPlatform":
                    y = r * TILE
            prop_xml = ""
            if props:
                prop_xml = "<properties>" + "".join(
                    f'<property name="{k}" value="{v}"/>' for k, v in props.items()) + "</properties>"
            objects.append(("spawnPoints", f'<object id="{oid}" name="{name}" type="{name}" x="{x:g}" y="{y:g}" width="{w}" height="{h}">{prop_xml}</object>'))
            oid += 1

    csv = ",\n".join(",".join(map(str, row)) for row in tiles)
    groups = ""
    for i, layer in enumerate(("Collisions", "spawnPoints")):
        body = "\n  ".join(o for l, o in objects if l == layer)
        groups += f' <objectgroup id="{i+2}" name="{layer}">\n  {body}\n </objectgroup>\n'
    level_props = "".join(f'<property name="{k}" value="{v}"/>' for k, v in meta.items())
    xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.11.0" orientation="orthogonal" renderorder="right-down" width="{width}" height="{height}" tilewidth="16" tileheight="16" infinite="0" nextlayerid="4" nextobjectid="{oid}">
 <properties>{level_props}</properties>
 <tileset firstgid="1" source="Pixel peep.tsx"/>
 <layer id="1" name="Terrain" width="{width}" height="{height}">
  <data encoding="csv">
{csv}
</data>
 </layer>
{groups}</map>
'''
    out = OUT / f"{path.stem}.tmx"
    out.write_text(xml)
    return out


if __name__ == "__main__":
    for f in sorted(SRC.glob("*.txt")):
        print("built", build(f).relative_to(ROOT))
