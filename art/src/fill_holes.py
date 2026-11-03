"""Fills small transparent holes inside a recovered sprite (colours that were too
close to the pink background, e.g. blush) with a given colour.
Usage: fill_holes.py in.png out.png R G B [max_hole_size] [max_row]"""
import sys
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
color = tuple(int(v) for v in sys.argv[3:6]) + (255,)
max_size = int(sys.argv[6]) if len(sys.argv) > 6 else 4
## Only holes above this row (e.g. the face) are filled.
max_row = int(sys.argv[7]) if len(sys.argv) > 7 else 10**6
im = Image.open(src).convert('RGBA'); px = im.load(); w, h = im.size
seen = set()
filled = 0
for sx in range(w):
    for sy in range(h):
        if px[sx, sy][3] or (sx, sy) in seen:
            continue
        comp, stack, edge = [], [(sx, sy)], False
        seen.add((sx, sy))
        while stack:
            x, y = stack.pop(); comp.append((x, y))
            if x in (0, w - 1) or y in (0, h - 1):
                edge = True
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < w and 0 <= ny < h and not px[nx, ny][3] and (nx, ny) not in seen:
                    seen.add((nx, ny)); stack.append((nx, ny))
        if not edge and len(comp) <= max_size and all(y <= max_row for _, y in comp):
            for x, y in comp:
                px[x, y] = color
            filled += len(comp)
im.save(dst)
print(src.split('/')[-1], 'filled', filled)
