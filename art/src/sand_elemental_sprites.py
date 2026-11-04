"""Sand elemental (summon of the Troll elemental de arena): a swirling column of
sand with glowing eyes, narrowing into a small dune. Palette taken from Neku's
troll. Usage: python3 art/src/sand_elemental_sprites.py"""
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "assets" / "sprites" / "units"
PAL = {"#": (4, 4, 4), "L": (232, 200, 120), "M": (204, 160, 80), "D": (160, 118, 54),
       "K": (112, 80, 38), "Y": (255, 226, 90), "o": (232, 200, 120)}
FRONT = [
    ".....o..........",
    "..o...####......",
    "....##LLLL##..o.",
    "...#LLLMMLLL#...",
    "..#LLMMMMMMLL#..",
    "..#LMMKMMKMML#..",
    "..#MMYKMMKYMM#..",
    ".o#MMMMDDMMMM#..",
    "..#DMMLLLLMMD#o.",
    ".#LDDMMMMMMDDL#.",
    "#LL#DDLLLLDD#LL#",
    "#M#.#DDMMDD#.#M#",
    ".#...#MMLM#...#.",
    "....#LMDDML#....",
    "....#MDLLDM#..o.",
    ".o...#DMMD#.....",
    ".....#LDDL#.....",
    "....#MMKKMM#....",
    "...#DDMMMMDD#...",
    "..##########....",
]
SIDE = [
    "......o.......",
    "....####......",
    "...#LLLL##..o.",
    "..#LLLMMLL#...",
    ".#LLMMMMMML#..",
    ".#MKYMMMMML#..",
    ".#MMMMMMMMM#..",
    ".#DMMMDDMMM#o.",
    "..#DDLLLLMD#..",
    ".#LDMMMMMDD#..",
    "#LL#DDLLDD#...",
    "#M#.#DMMD#....",
    ".#...#MLM#....",
    "....#LMDDM#...",
    "....#MDLLD#.o.",
    ".o...#DMMD#...",
    ".....#LDDL#...",
    "....#MMKKMM#..",
    "...#DDMMMMDD#.",
    "..###########.",
]


def render(rows):
    width = max(len(r) for r in rows)
    image = Image.new("RGBA", (width, len(rows)), (0, 0, 0, 0))
    pixels = image.load()
    for y, row in enumerate(rows):
        for x, key in enumerate(row):
            if key != ".":
                pixels[x, y] = PAL[key] + (255,)
    return image


if __name__ == "__main__":
    render(FRONT).save(OUT / "sand_elemental.png")
    render(SIDE).save(OUT / "sand_elemental_side.png")
    print("wrote sand_elemental.png and sand_elemental_side.png")
