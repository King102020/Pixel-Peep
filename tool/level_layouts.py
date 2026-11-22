"""Authoring helpers + layouts for levels 3-16. Writes tool/levels/lNN.txt.

Run:  python tool/level_layouts.py && python tool/gen_levels.py
Each level is 23 rows tall. The player spawns on row 16; the floor's top is
row 17. Main routes only need 3-tile steps and 3-tile gaps so every hero can
finish; secrets are tuned to one hero each:
  Bubble Trouper  - fruit 5+ tiles up (double jump / float)
  Final Call      - crates (dash) and long gaps
  Masti Time      - crates and golems guarding fruit
  Blue Ninja      - narrow wall-jump shafts and spike corridors (phase)
"""
from pathlib import Path

OUT = Path(__file__).resolve().parent / "levels"
H = 23
FLOOR = 17


class Map:
    def __init__(self, width, **meta):
        self.w = width
        self.meta = meta
        self.g = [[" "] * width for _ in range(H)]
        for c in range(width):
            self.g[0][c] = "#"
        for r in range(H):
            self.g[r][0] = self.g[r][width - 1] = "#"
        self.ground(0, width - 1, FLOOR)

    def ground(self, x0, x1, top):
        """Solid ground from column x0..x1 (inclusive), top row `top` to bottom."""
        for c in range(x0, x1 + 1):
            for r in range(top, H):
                self.g[r][c] = "#"
        return self

    def pit(self, x0, x1):
        for c in range(x0, x1 + 1):
            for r in range(1, H):
                if self.g[r][c] == "#":
                    self.g[r][c] = " "
        return self

    def block(self, x0, x1, r0, r1):
        for c in range(x0, x1 + 1):
            for r in range(r0, r1 + 1):
                self.g[r][c] = "#"
        return self

    def plat(self, x, r, n, ch="="):
        for c in range(x, x + n):
            self.g[r][c] = ch
        return self

    def put(self, x, r, s):
        for i, ch in enumerate(s):
            self.g[r][x + i] = ch
        return self

    def fruits(self, x, r, n, step=2):
        for i in range(n):
            self.g[r][x + i * step] = "F"
        return self

    def save(self, name):
        meta = " ".join(f"{k}={v}" for k, v in self.meta.items())
        rows = ["".join(r) for r in self.g]
        (OUT / f"{name}.txt").write_text(meta + "\n" + "\n".join(rows) + "\n")


def top(m, x):
    """Row of the first solid tile in column x (where things stand on)."""
    for r in range(1, H):
        if m.g[r][x] == "#":
            return r
    return FLOOR


def on(m, x, ch):
    m.g[top(m, x) - 1][x] = ch


# ------------------------------------------------------------------ world 1

def l03():
    m = Map(90, theme="grass", bg="Green", time=60, name="Bouncy_Hills")
    m.put(3, 16, "P")
    m.fruits(8, 15, 3)
    m.ground(16, 22, 15).fruits(17, 14, 3)
    on(m, 26, "g")
    m.fruits(24, 15, 3, 3)
    m.put(33, 16, "T").fruits(33, 9, 1)            # trampoline up to a ledge
    m.ground(36, 44, 12).fruits(37, 11, 4)
    m.put(42, 11, "C")
    m.pit(46, 48)
    m.ground(50, 62, 14)
    on(m, 56, "g")
    m.fruits(51, 13, 3)
    m.plat(54, 8, 4).fruits(54, 7, 2)             # Bubble: high platform
    m.put(64, 16, "T")
    m.ground(68, 76, 11)
    m.put(70, 10, "X")                             # crate (dash/punch)
    m.put(80, 16, "E")
    m.fruits(78, 15, 1)
    m.save("l03")


# ------------------------------------------------------------------ world 2

def l04():
    m = Map(90, theme="orange", bg="Blue", time=70, name="Fan_Factory")
    m.put(3, 16, "P").fruits(6, 15, 3)
    m.put(14, 16, "W").fruits(14, 10, 1)
    m.ground(17, 26, 10).fruits(18, 9, 4)
    m.pit(28, 30)
    m.ground(32, 40, 14)
    on(m, 36, "g")
    m.put(38, 12, "C")
    m.put(43, 16, "W").put(44, 16, "W")
    m.plat(46, 8, 6).fruits(46, 7, 3)
    m.put(55, 16, "_"[0:0] + "W")
    m.plat(58, 10, 3, "_").plat(63, 9, 3, "_")
    m.ground(68, 80, 12).fruits(69, 11, 3)
    m.put(74, 11, "X")
    m.plat(70, 5, 4).fruits(70, 4, 2)              # Bubble: way up top
    m.put(84, 16, "E")
    m.save("l04")


def l05():
    m = Map(95, theme="orange", bg="Blue", time=75, name="Spin_Cycle")
    m.put(3, 16, "P").fruits(6, 15, 4)
    m.put(16, 13, "S").fruits(14, 12, 3)
    m.ground(24, 30, 14)
    m.pit(32, 34)
    m.ground(36, 48, 14)
    on(m, 42, "g")
    m.put(46, 12, "C")
    m.put(52, 16, "T")
    m.plat(55, 9, 5).fruits(55, 8, 3)
    m.put(62, 11, "s")
    m.ground(66, 72, 14)
    m.block(75, 76, 4, 12)                         # Ninja: shaft between walls
    m.block(79, 80, 4, 12)
    m.fruits(77, 5, 1).fruits(77, 9, 1)
    m.put(77, 16, " ")
    m.ground(82, 93, 15)
    m.put(88, 14, "E")
    m.save("l05")


def l06():
    m = Map(100, theme="orange", bg="Purple", time=80, name="Factory_Floor")
    m.put(3, 16, "P")
    on(m, 12, "g")
    m.fruits(8, 15, 4)
    m.put(20, 16, "W").put(21, 16, "W")
    m.ground(24, 34, 10)
    on(m, 29, "b")
    m.fruits(25, 9, 4)
    m.plat(36, 10, 2, "_").plat(40, 10, 2, "_").plat(44, 10, 2, "_")
    m.ground(48, 58, 12).put(55, 11, "C")
    m.put(50, 11, "X").put(52, 11, "X")
    m.pit(60, 62)
    m.ground(64, 70, 15)
    m.put(66, 12, "S")
    m.put(74, 16, "T")
    m.plat(76, 6, 6).fruits(76, 5, 3)
    on(m, 84, "g")
    m.fruits(82, 15, 3)
    m.put(94, 16, "E")
    m.save("l06")


# ------------------------------------------------------------------ world 3

def l07():
    m = Map(90, theme="grass", bg="Gray", time=70, name="Spike_Caverns")
    m.put(3, 16, "P").fruits(6, 15, 3)
    m.put(12, 16, "^^^")
    m.ground(18, 24, 14).put(19, 13, "^").fruits(20, 13, 2)
    m.put(28, 16, "^^^")
    m.plat(27, 12, 6).fruits(28, 11, 3)
    m.put(38, 16, "C")
    m.put(45, 16, "^^^")                           # short enough for anyone
    m.fruits(44, 14, 3, 2)
    m.plat(44, 11, 8)
    m.ground(56, 64, 14)
    on(m, 60, "g")
    m.pit(66, 68)
    m.ground(70, 74, 14)
    m.plat(76, 9, 3).fruits(77, 8, 1)
    m.put(84, 16, "E")
    m.save("l07")


def l08():
    m = Map(95, theme="grass", bg="Gray", time=80, name="Crumbling_Path")
    m.put(3, 16, "P").fruits(6, 15, 3)
    m.pit(12, 40)
    m.plat(13, 14, 2, "_").plat(17, 13, 2, "_").plat(21, 12, 2, "_")
    m.plat(25, 12, 2, "_").plat(29, 13, 2, "_").plat(33, 14, 2, "_")
    m.plat(37, 14, 2, "_")
    m.fruits(17, 12, 1).fruits(25, 11, 1)
    m.put(38, 13, "S")
    m.ground(41, 52, 14).put(48, 13, "C")
    on(m, 46, "b")
    m.put(55, 16, "^^^")
    m.block(60, 61, 3, 12).block(64, 65, 3, 12)    # Ninja shaft
    m.fruits(62, 4, 1).fruits(62, 8, 1)
    m.ground(68, 75, 14)
    m.put(70, 13, "X")
    m.put(78, 16, "T")
    m.plat(80, 7, 4).fruits(80, 6, 2)
    m.put(88, 16, "E")
    m.save("l08")


def l09():
    m = Map(100, theme="pink", bg="Gray", time=85, name="Needle_Run")
    m.put(3, 16, "P").fruits(6, 15, 3)
    m.put(12, 13, "S").put(20, 13, "S")
    m.ground(26, 32, 14).put(28, 13, "^^")
    m.plat(34, 11, 4)
    m.put(41, 16, "^^^").plat(39, 12, 2, "_").plat(43, 12, 2, "_")
    m.ground(48, 58, 13).put(56, 12, "C")
    on(m, 52, "g")
    m.put(62, 12, "s").put(68, 12, "s")
    m.fruits(64, 13, 3, 2)
    m.ground(72, 80, 14)
    m.put(74, 13, "^^")
    m.plat(82, 6, 4).fruits(82, 5, 2)
    m.put(92, 16, "E")
    m.save("l09")


# ------------------------------------------------------------------ world 4

def l10():
    m = Map(95, theme="grass", bg="Brown", time=80, name="Rock_Ruins")
    m.put(3, 16, "P").fruits(6, 15, 3)
    on(m, 16, "G")
    m.fruits(14, 15, 3)
    m.ground(24, 34, 14)
    m.put(26, 13, "X").put(28, 13, "X").put(30, 13, "X")
    m.put(40, 16, "C")
    on(m, 50, "G")
    m.plat(46, 12, 8).fruits(47, 11, 4)
    m.pit(58, 60)
    m.ground(62, 72, 14)
    on(m, 67, "g")
    m.put(76, 16, "W")
    m.plat(78, 7, 4).fruits(78, 6, 2)
    m.put(88, 16, "E")
    m.save("l10")


def l11():
    m = Map(100, theme="pink", bg="Brown", time=90, name="Golem_Gate")
    m.put(3, 16, "P").fruits(6, 15, 3)
    m.ground(14, 20, 14)
    on(m, 26, "G")
    on(m, 34, "g")
    m.fruits(24, 15, 6, 2)
    m.ground(40, 50, 14).put(47, 13, "C")
    m.put(42, 13, "X").put(44, 13, "X")
    on(m, 46, "b")
    m.pit(52, 54)
    m.ground(56, 63, 14)
    m.put(66, 16, "T").plat(68, 6, 5).fruits(68, 5, 3)
    on(m, 76, "G")
    m.fruits(74, 15, 3)
    m.block(82, 83, 4, 12).block(86, 87, 4, 12)    # Ninja shaft
    m.fruits(84, 5, 1)
    m.put(94, 16, "E")
    m.save("l11")


def l12():
    m = Map(105, theme="grass", bg="Brown", time=95, name="Crate_Canyon")
    m.put(3, 16, "P")
    m.put(8, 15, "X").put(11, 15, "X").put(14, 15, "X")
    m.ground(18, 26, 14)
    on(m, 22, "G")
    m.pit(28, 31)
    m.plat(28, 12, 4, "_")
    m.ground(33, 44, 12).put(41, 11, "C")
    m.put(35, 11, "X").put(37, 11, "X")
    m.put(48, 16, "^^^").put(47, 12, "S")
    m.ground(55, 62, 14)
    on(m, 66, "g")
    m.put(70, 16, "W").put(71, 16, "W")
    m.plat(73, 6, 6).fruits(73, 5, 3)
    on(m, 84, "G")
    m.fruits(80, 15, 4)
    m.put(98, 16, "E")
    m.save("l12")


# ------------------------------------------------------------------ world 5

def l13():
    m = Map(100, theme="orange", bg="Yellow", time=60, name="Fire_Rush")
    m.put(3, 16, "P").fruits(6, 15, 3)
    m.put(12, 16, "f f f")
    m.ground(20, 26, 14).put(22, 13, "f")
    m.pit(28, 30)
    m.ground(32, 40, 14).put(34, 13, "ff").put(38, 13, "C")
    m.put(44, 16, "f f f f")
    m.fruits(44, 12, 4)
    m.ground(54, 60, 14)
    m.put(62, 16, "T")
    m.plat(64, 6, 4).fruits(64, 5, 2)
    m.put(70, 16, "f  f")
    on(m, 80, "g")
    m.fruits(77, 15, 3)
    m.put(92, 16, "E")
    m.save("l13")


def l14():
    m = Map(105, theme="orange", bg="Yellow", time=70, name="Lava_Lane")
    m.put(3, 16, "P").fruits(6, 15, 3)
    m.pit(12, 34)
    m.plat(12, 14, 2, "_").plat(16, 13, 2, "_").plat(20, 13, 2, "_")
    m.plat(24, 14, 2, "_").plat(28, 13, 2, "_").plat(32, 14, 2, "_")
    m.fruits(16, 12, 1).fruits(24, 13, 1)
    m.ground(36, 46, 14).put(38, 13, "f f").put(44, 13, "C")
    on(m, 42, "b")
    m.put(50, 16, "WW")
    m.plat(53, 7, 5).fruits(53, 6, 3)
    m.ground(60, 68, 14).put(62, 13, "X").put(64, 13, "X")
    m.put(72, 16, "f^f^f")
    m.ground(80, 88, 14)
    on(m, 84, "G")
    m.put(98, 16, "E")
    m.save("l14")


def l15():
    m = Map(110, theme="pink", bg="Pink", time=80, name="Gauntlet")
    m.put(3, 16, "P").fruits(6, 15, 3)
    m.put(12, 13, "S").put(18, 16, "f")
    on(m, 24, "g")
    m.ground(30, 36, 14).put(32, 13, "^^")
    m.pit(38, 41).plat(38, 12, 4, "_")
    m.ground(43, 52, 13).put(50, 12, "C")
    on(m, 47, "G")
    m.put(56, 16, "T").plat(58, 7, 5).fruits(58, 6, 3)
    m.put(67, 16, "^^^")
    m.plat(66, 12, 5)
    m.block(74, 75, 3, 12).block(78, 79, 3, 12)    # Ninja shaft
    m.fruits(76, 4, 1)
    m.put(84, 16, "WW")
    m.ground(88, 96, 10).put(90, 9, "X")
    on(m, 94, "b")
    m.put(103, 16, "E")
    m.save("l15")


# ------------------------------------------------------------------ boss

def l16():
    m = Map(70, theme="pink", bg="Purple", time=120, name="Golem_King")
    m.put(12, 16, "P").fruits(15, 15, 3)
    # Dodge the charge from these ledges, then drop onto the dizzy king.
    # The king stops dizzy by a wall; step off the ledge onto his head.
    m.plat(5, 14, 5).fruits(6, 13, 2)
    m.plat(32, 14, 5).fruits(33, 13, 2)
    m.plat(60, 14, 5).fruits(61, 13, 2)
    m.plat(21, 10, 5).fruits(22, 9, 2)             # Bubble: high ledges
    m.plat(39, 10, 5).fruits(40, 9, 2)
    m.put(42, 16, "B")
    m.put(64, 16, "E")
    m.save("l16")


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    for fn in (l03, l04, l05, l06, l07, l08, l09, l10, l11, l12, l13, l14, l15, l16):
        fn()
    print("layouts written")
