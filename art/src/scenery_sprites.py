"""Pixel-art scenery sprites (v0.9): trees for HD-2D billboards, banners.

python3 art/src/scenery_sprites.py  ->  assets/sprites/scenery/<name>.png
Trees stand on the bottom edge (like the characters) and are lit in game.
"""
import math
from pathlib import Path

import numpy as np
from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "assets/sprites/scenery"


def hexes(*h: str) -> list[tuple[int, int, int, int]]:
    return [(int(x[1:3], 16), int(x[3:5], 16), int(x[5:7], 16), 255) for x in h]


LEAF = hexes("#13261a", "#1d3a23", "#2a542c", "#3b7034", "#558f3e", "#78ad4c")
PINE = hexes("#0f2019", "#163023", "#1f4430", "#2b5a3b", "#3b7449")
AUTUMN = hexes("#2a1410", "#4a2016", "#73341c", "#a0501f", "#c97a2a", "#e3a540")
BARK = hexes("#1d130d", "#2d1e14", "#43301f", "#5c432b")
OUTLINE = (14, 12, 16, 255)


def blob_tree(seed: int, leaf: list, w: int = 44, h: int = 62) -> Image.Image:
    """Round broad-leaf tree: clumps of foliage lit from the top-left."""
    rng = np.random.default_rng(seed)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    # Trunk.
    tx = w // 2
    for y in range(h - 26, h):
        half = 2 if y < h - 4 else 3 + (h - y == 1)
        for x in range(tx - half, tx + half + 1):
            shade = 3 if x < tx - half + 2 else (1 if x > tx + half - 2 else 2)
            px[x, y] = BARK[shade]
    # Clumps of leaves.
    clumps = [(tx + rng.integers(-12, 13), rng.integers(10, 34), rng.integers(8, 12)) for _ in range(9)]
    clumps.append((tx, 20, 14))
    solid = np.zeros((h, w), dtype=bool)
    tone = np.zeros((h, w))
    for cx, cy, r in clumps:
        for y in range(max(0, cy - r), min(h, cy + r + 1)):
            for x in range(max(0, cx - r), min(w, cx + r + 1)):
                d = math.hypot(x - cx, (y - cy) * 1.1)
                if d <= r - (rng.random() < 0.15):
                    solid[y, x] = True
                    # Light from the top-left of each clump.
                    light = 1.0 - (((x - cx) + (y - cy)) / (2 * r) + 0.5)
                    tone[y, x] = max(tone[y, x], light + rng.random() * 0.12)
    for y in range(h):
        for x in range(w):
            if solid[y, x]:
                k = int(np.clip(tone[y, x] * (len(leaf) - 1) + 0.3, 0, len(leaf) - 1))
                px[x, y] = leaf[k]
    _outline(img, solid)
    return img


def pine(seed: int, w: int = 34, h: int = 70) -> Image.Image:
    """Layered conifer."""
    rng = np.random.default_rng(seed)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    tx = w // 2
    for y in range(h - 12, h):
        for x in range(tx - 1, tx + 2):
            px[x, y] = BARK[2 if x == tx - 1 else 1]
    solid = np.zeros((h, w), dtype=bool)
    tiers = 6
    for t in range(tiers):
        top = 2 + t * 9
        bottom = top + 14
        for y in range(top, min(bottom, h - 10)):
            frac = (y - top) / (bottom - top)
            half = int(2 + frac * (4 + t * 2.1)) + (rng.random() < 0.3)
            for x in range(tx - half, tx + half + 1):
                if 0 <= x < w:
                    solid[y, x] = True
                    side = (x - tx) / max(half, 1)
                    k = 3 if side < -0.3 else (1 if side > 0.45 else 2)
                    if frac > 0.85:
                        k = max(k - 1, 0)
                    if (x + y) % 5 == 0 and side < 0:
                        k = 4
                    px[x, y] = PINE[k]
    _outline(img, solid)
    return img


def banner(seed: int, base: str, light: str, emblem: str, w: int = 18, h: int = 36) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    b, l, e = hexes(base)[0], hexes(light)[0], hexes(emblem)[0]
    dark = tuple(int(c * 0.6) for c in b[:3]) + (255,)
    for y in range(2, h):
        for x in range(1, w - 1):
            # Swallow-tail cut at the bottom.
            if y > h - 7 and abs(x - w // 2) < (y - (h - 7)):
                continue
            px[x, y] = l if x < 4 else (dark if x > w - 5 else b)
    for x in range(0, w):  # Rod.
        px[x, 0] = (60, 48, 36, 255)
        px[x, 1] = (96, 78, 58, 255)
    # Emblem: a simple crown / star.
    cx, cy = w // 2, h // 2 - 3
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            if abs(dx) + abs(dy) <= 4 and (abs(dx) == abs(dy) or dx == 0 or dy == 0):
                px[cx + dx, cy + dy] = e
    # Trim.
    for y in range(2, h - 7):
        px[1, y] = e
        px[w - 2, y] = e
    _outline(img, np.array([[img.getpixel((x, y))[3] > 0 for x in range(w)] for y in range(h)]))
    return img


def _outline(img: Image.Image, solid: np.ndarray) -> None:
    px = img.load()
    h, w = solid.shape
    for y in range(h):
        for x in range(w):
            if solid[y, x]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < w and 0 <= yy < h and solid[yy, xx]:
                    px[x, y] = OUTLINE
                    break


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    blob_tree(1, LEAF).save(OUT / "tree_oak.png")
    blob_tree(2, LEAF, 40, 56).save(OUT / "tree_oak_small.png")
    blob_tree(3, AUTUMN).save(OUT / "tree_autumn.png")
    pine(4).save(OUT / "tree_pine.png")
    banner(5, "#7a1820", "#a8323a", "#e2b54a").save(OUT / "banner_red.png")
    banner(6, "#1f2f5c", "#34508a", "#d8dce8").save(OUT / "banner_blue.png")
    print("ok")


if __name__ == "__main__":
    main()
