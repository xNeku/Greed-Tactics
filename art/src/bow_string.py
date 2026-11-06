"""Adds a 1-px string between the two tips of a fitted bow sprite (thin
details do not survive downscaling). Usage: bow_string.py in.png out.png"""
import sys
from PIL import Image

STRING = (205, 205, 200, 255)
im = Image.open(sys.argv[1]).convert("RGBA")
px = im.load()
solid = [(x, y) for y in range(im.height) for x in range(im.width) if px[x, y][3] and sum(px[x, y][:3]) > 90]
top = min(solid, key=lambda p: p[1] - p[0])      # upper-right tip
bottom = max(solid, key=lambda p: p[1] - p[0])   # lower-left tip
(x0, y0), (x1, y1) = (top[0] - 1, top[1] + 1), (bottom[0] + 1, bottom[1] - 1)
dx, dy = abs(x1 - x0), -abs(y1 - y0)
sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
err = dx + dy
while True:
    if 0 <= x0 < im.width and 0 <= y0 < im.height and not px[x0, y0][3]:
        px[x0, y0] = STRING
    if (x0, y0) == (x1, y1):
        break
    e2 = 2 * err
    if e2 >= dy:
        err += dy
        x0 += sx
    if e2 <= dx:
        err += dx
        y0 += sy
im.save(sys.argv[2])
print("string from", top, "to", bottom)
