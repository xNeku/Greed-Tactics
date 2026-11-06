"""Fits a recovered weapon sprite to the game's pixel scale (heroes are ~28 px
tall): box-downsamples to [target] px on the longest side, snaps every pixel
back to the weapon's own palette and redraws a clean 1-px dark outline.
Usage: fit_weapon.py in.png out.png target [min_coverage]
(lower min_coverage keeps 1-px details such as bow strings)"""
import sys
from PIL import Image

OUTLINE = (12, 10, 12, 255)


def dark(c):
    return c[3] > 0 and sum(c[:3]) < 90


def main() -> None:
    src = Image.open(sys.argv[1]).convert("RGBA")
    target = int(sys.argv[3])
    min_coverage = float(sys.argv[4]) if len(sys.argv) > 4 else 0.35
    scale = target / max(src.size)
    w, h = max(1, round(src.width * scale)), max(1, round(src.height * scale))
    sp = src.load()
    palette = sorted({sp[x, y] for x in range(src.width) for y in range(src.height) if sp[x, y][3] and not dark(sp[x, y])})
    out = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    op = out.load()
    for ty in range(h):
        for tx in range(w):
            x0, x1 = int(tx / scale), max(int((tx + 1) / scale), int(tx / scale) + 1)
            y0, y1 = int(ty / scale), max(int((ty + 1) / scale), int(ty / scale) + 1)
            cells = [sp[x, y] for x in range(x0, min(x1, src.width)) for y in range(y0, min(y1, src.height))]
            solid = [c for c in cells if c[3]]
            if len(solid) < len(cells) * min_coverage:
                continue
            colour = [c for c in solid if not dark(c)]
            if len(colour) < len(solid) * 0.3:
                op[tx + 1, ty + 1] = OUTLINE
                continue
            mean = tuple(sum(c[i] for c in colour) / len(colour) for i in range(3))
            op[tx + 1, ty + 1] = min(palette, key=lambda p: sum((p[i] - mean[i]) ** 2 for i in range(3)))
    # Clean outline: every transparent pixel touching the shape becomes outline.
    edge = []
    for y in range(out.height):
        for x in range(out.width):
            if op[x, y][3]:
                continue
            if any(0 <= nx < out.width and 0 <= ny < out.height and op[nx, ny][3] and op[nx, ny] != OUTLINE
                   for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                edge.append((x, y))
    for x, y in edge:
        op[x, y] = OUTLINE
    bbox = out.getbbox()
    out.crop(bbox).save(sys.argv[2])
    print(sys.argv[2].split("/")[-1], out.crop(bbox).size)


if __name__ == "__main__":
    main()
