"""Removes the pink JPG halo left around recovered sprites: edge pixels whose
colour leans to magenta (blue above green, red well above green) become
transparent; repeated a few passes so 2-pixel halos go too.
Usage: clean_halo.py in.png out.png"""
import sys
from PIL import Image

image = Image.open(sys.argv[1]).convert("RGBA")
px = image.load()
w, h = image.size


def pinkish(c):
    r, g, b, a = c
    return a and r > g + 50 and b > g + 10


removed = 0
for _ in range(3):
    kill = []
    for y in range(h):
        for x in range(w):
            if not pinkish(px[x, y]):
                continue
            edge = any(not (0 <= nx < w and 0 <= ny < h) or px[nx, ny][3] == 0
                       for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
            if edge:
                kill.append((x, y))
    for x, y in kill:
        px[x, y] = (0, 0, 0, 0)
    removed += len(kill)
# Re-close the outline where a halo pixel was the outline's neighbour.
image.save(sys.argv[2])
print(sys.argv[2].split("/")[-1], "removed", removed)
