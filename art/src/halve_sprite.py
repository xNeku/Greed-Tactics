"""Halves a pixel-art sprite drawn at double density (2x2 blocks -> 1 pixel),
keeping the black outline: a block with any outline pixel becomes outline only
if it sits on the silhouette edge; otherwise the most common colour wins.
Usage: halve_sprite.py in.png out.png"""
import sys
from collections import Counter
from PIL import Image

src = Image.open(sys.argv[1]).convert("RGBA")
w, h = (src.width + 1) // 2, (src.height + 1) // 2
px = src.load()
out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
op = out.load()
dark = lambda c: c[3] and sum(c[:3]) < 60
for y in range(h):
    for x in range(w):
        block = [px[x * 2 + dx, y * 2 + dy] for dx in (0, 1) for dy in (0, 1)
                 if x * 2 + dx < src.width and y * 2 + dy < src.height]
        solid = [c for c in block if c[3]]
        if len(solid) < 2:
            continue
        if any(dark(c) for c in solid) and len(solid) < len(block):
            op[x, y] = next(c for c in solid if dark(c))
            continue
        colors = Counter(solid).most_common()
        op[x, y] = colors[0][0]
# Close the outline: transparent neighbours of a filled non-outline pixel get outline.
fill = out.copy(); fp = fill.load()
for y in range(h):
    for x in range(w):
        if op[x, y][3] and not dark(op[x, y]):
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < w and 0 <= ny < h and not op[nx, ny][3]:
                    fp[nx, ny] = (4, 4, 4, 255)
fill.save(sys.argv[2])
print(sys.argv[2].split("/")[-1], fill.size)
