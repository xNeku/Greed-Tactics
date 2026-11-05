"""Supply cart (PROTECT objective): a small wooden cart with sacks.
Usage: python3 art/src/supply_cart_sprite.py"""
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "assets" / "sprites" / "units"
PAL = {"#": (12, 10, 8), "w": (150, 104, 60), "W": (110, 74, 42), "s": (222, 200, 150), "S": (184, 160, 112),
       "r": (176, 58, 46), "m": (120, 120, 128), "M": (80, 80, 88)}
ART = [
    "......####......",
    ".....#ssss#.....",
    "...##sSssSs##...",
    "..#ssSs##sSss#..",
    "..#sSsr#rsSss#..",
    ".##############.",
    "#wwWwwWwwWwwWww#",
    "#WwwWwwWwwWwwWw#",
    "#wwWwwWwwWwwWww#",
    "################",
    "..#mm#....#mm#..",
    ".#mMMm#..#mMMm#.",
    ".#mMMm#..#mMMm#.",
    "..#mm#....#mm#..",
    "...##......##...",
]
image = Image.new("RGBA", (len(ART[0]), len(ART)), (0, 0, 0, 0))
px = image.load()
for y, row in enumerate(ART):
    for x, key in enumerate(row):
        if key != ".":
            px[x, y] = PAL[key] + (255,)
image.save(OUT / "supply_cart.png")
print("wrote supply_cart.png")
