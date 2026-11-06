"""Tileable pixel-art textures for the terrain and props (v0.9).

32 px per world unit (one cell), the pixel density of the characters, nearest
filtered in game. Each material is drawn with a small palette ramp (dark ->
light) so it reads as hand-made pixel art, not noise.

python3 art/src/terrain_textures.py  ->  assets/textures/terrain/<name>.png
"""
from pathlib import Path

import numpy as np
from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "assets/textures/terrain"
N = 32


def ramp(*hexes: str) -> np.ndarray:
    return np.array([[int(h[i:i + 2], 16) for i in (1, 3, 5)] for h in hexes], dtype=np.uint8)


GRASS = ramp("#1d3524", "#2b5230", "#3c7034", "#55913b", "#78b04a", "#a3cf5f")
DIRT = ramp("#24160f", "#3a2418", "#523421", "#6d4a2c", "#8c6339", "#ab7f4b")
STONE = ramp("#1f1f27", "#2f2f3a", "#444451", "#5c5c6b", "#787888", "#9a9aa8")
WARM_STONE = ramp("#28221f", "#3b332c", "#52473d", "#6b5e50", "#877765", "#a7967f")
SANDSTONE = ramp("#42291b", "#633f27", "#865a34", "#a87645", "#c8975e", "#e3bb83")
SAND = ramp("#7d5c35", "#9c7848", "#b8935b", "#cfab70", "#e2c58c", "#f0dcaa")
CAVE = ramp("#10131c", "#181d2a", "#232a3c", "#313b52", "#43506b", "#5a6886")
CARPET = ramp("#240a0f", "#431017", "#6a1820", "#922429", "#b8383a", "#d9b257")
WOOD = ramp("#241509", "#3a2414", "#53351e", "#6d4729", "#8a5d36", "#a77846")
METAL = ramp("#16191b", "#24292c", "#353d41", "#4b5559", "#667276", "#8a9699")
RUST = ramp("#2e1a12", "#462618", "#5f341d", "#7a4524", "#94592f", "#ad6e3c")
CONCRETE = ramp("#262624", "#383835", "#4d4d49", "#64645e", "#7e7e77", "#9c9c93")
MOSS = ramp("#1c2c18", "#2a4222", "#3b5a2c", "#4f7535")


class Canvas:
    def __init__(self, seed: int) -> None:
        self.rng = np.random.default_rng(seed)
        self.idx = np.zeros((N, N), dtype=np.int32)  # Ramp index per pixel.
        self.pal = np.zeros((N, N), dtype=np.int32)  # Which ramp (0 = main).
        self.ramps: list[np.ndarray] = []

    def noise(self, scale: int, amp: float = 1.0) -> np.ndarray:
        """Tileable value noise, `scale` lattice cells across the tile."""
        g = self.rng.random((scale, scale))
        y, x = np.mgrid[0:N, 0:N] * (scale / N)
        x0 = np.floor(x).astype(int)
        y0 = np.floor(y).astype(int)
        fx, fy = x - x0, y - y0
        fx = fx * fx * (3 - 2 * fx)
        fy = fy * fy * (3 - 2 * fy)
        a = g[y0 % scale, x0 % scale]
        b = g[y0 % scale, (x0 + 1) % scale]
        c = g[(y0 + 1) % scale, x0 % scale]
        d = g[(y0 + 1) % scale, (x0 + 1) % scale]
        return ((a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy) * amp

    def image(self) -> Image.Image:
        out = np.zeros((N, N, 3), dtype=np.uint8)
        for k, r in enumerate(self.ramps):
            mask = self.pal == k
            out[mask] = r[np.clip(self.idx[mask], 0, len(r) - 1)]
        return Image.fromarray(out, "RGB")


def voronoi(c: Canvas, count: int, jitter: float = 1.0):
    """Tileable Voronoi: returns (owner id, distance to border) per pixel."""
    pts = c.rng.random((count, 2)) * N
    y, x = np.mgrid[0:N, 0:N] + 0.5
    best = np.full((N, N), 1e9)
    second = np.full((N, N), 1e9)
    owner = np.zeros((N, N), dtype=np.int32)
    for i, (px, py) in enumerate(pts):
        for ox in (-N, 0, N):
            for oy in (-N, 0, N):
                d = np.hypot(x - (px + ox), (y - (py + oy)) * jitter)
                closer = d < best
                second = np.where(closer, best, np.minimum(second, d))
                owner = np.where(closer, i, owner)
                best = np.where(closer, d, best)
    return owner, (second - best) * 0.5


def shade_edges(c: Canvas, solid: np.ndarray, base: np.ndarray, light: int = 1, dark: int = 1) -> None:
    """Light on the top-left rim of each shape, dark on the bottom-right."""
    up = np.roll(solid, 1, axis=0)
    left = np.roll(solid, 1, axis=1)
    down = np.roll(solid, -1, axis=0)
    right = np.roll(solid, -1, axis=1)
    rim_light = solid & (~up | ~left)
    rim_dark = solid & (~down | ~right)
    c.idx[:] = base
    c.idx[rim_light] += light
    c.idx[rim_dark & ~rim_light] -= dark


def cobble(seed: int, r: np.ndarray, moss: bool = False) -> Image.Image:
    c = Canvas(seed)
    c.ramps = [r, MOSS]
    owner, edge = voronoi(c, 11, 1.15)
    stone = edge > 0.9
    tone = c.rng.integers(2, 5, owner.max() + 1)
    base = tone[owner] + (c.noise(8) > 0.72).astype(int) - (c.noise(16) > 0.85).astype(int)
    shade_edges(c, stone, base)
    c.idx[~stone] = 0
    c.idx[~stone & (c.noise(6) > 0.6)] = 1
    if moss:
        m = (~stone) & (c.noise(4) > 0.55)
        c.pal[m] = 1
        c.idx[m] = 1 + (c.noise(12)[m] > 0.5).astype(int)
    return c.image()


def flagstones(seed: int, r: np.ndarray, size: int = 16) -> Image.Image:
    """Big square tiles (castle floor, concrete slabs)."""
    c = Canvas(seed)
    c.ramps = [r]
    y, x = np.mgrid[0:N, 0:N]
    row = y // size
    shift = (row % 2) * (size // 2)
    col = (x + shift) // size
    tile_id = row * 7 + col
    tone = c.rng.integers(2, 4, 100)
    solid = ((x + shift) % size != 0) & (y % size != 0)
    base = tone[tile_id % 100] + (c.noise(8) > 0.75).astype(int)
    shade_edges(c, solid, base)
    c.idx[~solid] = 0
    cracks = (np.abs(c.noise(5) - 0.5) < 0.018) & solid
    c.idx[cracks] = 1
    chips = (c.rng.random((N, N)) > 0.985) & solid
    c.idx[chips] = 1
    return c.image()


def bricks(seed: int, r: np.ndarray, bw: int = 16, bh: int = 8, moss: bool = False) -> Image.Image:
    c = Canvas(seed)
    c.ramps = [r, MOSS]
    y, x = np.mgrid[0:N, 0:N]
    row = y // bh
    shift = (row % 2) * (bw // 2)
    brick = row * 13 + (x + shift) // bw
    solid = ((x + shift) % bw != 0) & (y % bh != 0)
    tone = c.rng.integers(2, 4, 200)
    base = tone[brick % 200] + (c.noise(8) > 0.78).astype(int) - (c.noise(16) > 0.88).astype(int)
    shade_edges(c, solid, base)
    c.idx[~solid] = 0
    # Chipped corners.
    chips = solid & (c.rng.random((N, N)) > 0.97)
    c.idx[chips] = 1
    if moss:
        m = c.noise(4) > 0.62
        c.pal[m & ~solid] = 1
        c.idx[m & ~solid] = 2
    return c.image()


def grass(seed: int) -> Image.Image:
    c = Canvas(seed)
    c.ramps = [GRASS, ramp("#e8d25a", "#f2efe0", "#d9617a")]
    n = c.noise(4) * 0.6 + c.noise(8) * 0.4
    c.idx[:] = 2 + (n > 0.45).astype(int) + (n > 0.65).astype(int)
    c.idx[(c.noise(16) > 0.8)] -= 1
    # Blades: 2-pixel vertical strokes, light on top, dark under.
    for _ in range(46):
        x, y = c.rng.integers(0, N, 2)
        c.idx[y % N, x] = 4 + int(c.rng.random() > 0.6)
        c.idx[(y + 1) % N, x] = 3
        c.idx[(y + 2) % N, x] = 1
    # A few flowers.
    for _ in range(3):
        x, y = c.rng.integers(0, N, 2)
        c.pal[y, x] = 1
        c.idx[y, x] = int(c.rng.integers(0, 3))
    return c.image()


def strata(seed: int, r: np.ndarray, pebbles: int = 6, roots: bool = False) -> Image.Image:
    """Cliff side: wavy horizontal layers with embedded stones."""
    c = Canvas(seed)
    c.ramps = [r, STONE]
    y, x = np.mgrid[0:N, 0:N]
    wave = c.noise(4) * 6 + y
    band = (wave // 5).astype(int) % 4
    c.idx[:] = np.array([2, 3, 2, 1])[band] + (c.noise(16) > 0.7).astype(int)
    # Dark seams between layers.
    seam = (wave % 5) < 0.8
    c.idx[seam] = 1
    for _ in range(pebbles):
        px, py = c.rng.integers(0, N, 2)
        w, h = c.rng.integers(3, 6), c.rng.integers(2, 4)
        for dy in range(h):
            for dx in range(w):
                yy, xx = (py + dy) % N, (px + dx) % N
                c.pal[yy, xx] = 1
                edge = dy == 0 or dx == 0
                c.idx[yy, xx] = 4 if edge and dy == 0 else (2 if dy == h - 1 or dx == w - 1 else 3)
    if roots:
        for _ in range(3):
            x0 = int(c.rng.integers(0, N))
            yy = int(c.rng.integers(0, 10))
            for step in range(int(c.rng.integers(5, 12))):
                c.pal[yy % N, x0 % N] = 0
                c.idx[yy % N, x0 % N] = 0
                yy += 1
                x0 += int(c.rng.integers(-1, 2))
    return c.image()


def rock(seed: int, r: np.ndarray) -> Image.Image:
    c = Canvas(seed)
    c.ramps = [r]
    owner, edge = voronoi(c, 6, 0.8)
    tone = c.rng.integers(2, 5, owner.max() + 1)
    solid = edge > 0.6
    shade_edges(c, solid, tone[owner], 1, 1)
    c.idx[~solid] = 1
    c.idx[(c.noise(16) > 0.82) & solid] -= 1
    return c.image()


def sand(seed: int) -> Image.Image:
    c = Canvas(seed)
    c.ramps = [SAND]
    y, x = np.mgrid[0:N, 0:N]
    ripple = np.sin((x * 0.35 + y * 0.9 + c.noise(4) * 6) * (2 * np.pi / 8))
    c.idx[:] = 3 + (ripple > 0.55).astype(int) - (ripple < -0.7).astype(int)
    c.idx[c.rng.random((N, N)) > 0.97] = 1
    return c.image()


def planks(seed: int, r: np.ndarray, ph: int = 8) -> Image.Image:
    c = Canvas(seed)
    c.ramps = [r, METAL]
    y, x = np.mgrid[0:N, 0:N]
    row = y // ph
    shift = c.rng.integers(0, N, N // ph + 1)[row]
    seam = ((x + shift) % N == 0) | (y % ph == 0)
    grain = (np.sin((x + shift) * 0.7 + c.noise(4) * 8) > 0.6).astype(int)
    tone = c.rng.integers(2, 4, N // ph + 1)[row]
    c.idx[:] = tone + grain
    c.idx[y % ph == 1] += 1
    c.idx[seam] = 0
    for k in range(N // ph):  # Nails.
        for nx in (3, 19):
            yy, xx = k * ph + ph // 2, (nx + int(shift[k * ph, 0])) % N
            c.pal[yy, xx] = 1
            c.idx[yy, xx] = 4
    return c.image()


def metal_plate(seed: int, rust_amount: float = 0.35) -> Image.Image:
    c = Canvas(seed)
    c.ramps = [METAL, RUST]
    y, x = np.mgrid[0:N, 0:N]
    solid = (x % 16 != 0) & (y % 16 != 0)
    base = 3 + (c.noise(4) > 0.6).astype(int) - (c.noise(8) > 0.8).astype(int)
    shade_edges(c, solid, base)
    c.idx[~solid] = 0
    # Rivets in the corners of each plate.
    for py in (0, 16):
        for px in (0, 16):
            for rx, ry in ((3, 3), (12, 3), (3, 12), (12, 12)):
                c.idx[py + ry, px + rx] = 5
                c.idx[py + ry + 1, px + rx] = 1
    # Scratches.
    for _ in range(4):
        x0, y0 = c.rng.integers(0, N, 2)
        for k in range(int(c.rng.integers(4, 9))):
            c.idx[(y0 + k // 2) % N, (x0 + k) % N] = 4
    rust = (c.noise(4) * 0.7 + c.noise(16) * 0.3) > 1 - rust_amount
    c.pal[rust & solid] = 1
    c.idx[rust & solid] = 2 + (c.noise(8)[rust & solid] > 0.5).astype(int)
    return c.image()


def grating(seed: int) -> Image.Image:
    c = Canvas(seed)
    c.ramps = [METAL, RUST]
    y, x = np.mgrid[0:N, 0:N]
    bar = (x % 4 == 0) | (y % 8 == 0)
    c.idx[:] = 0
    c.idx[bar] = 3
    c.idx[bar & ((x % 4 == 0) & (y % 8 == 1))] = 4
    c.idx[(x % 4 == 1) & ~bar] = 1  # Depth under the bars.
    rust = bar & (c.noise(4) > 0.78)
    c.pal[rust] = 1
    c.idx[rust] = 2
    return c.image()


def corrugated(seed: int) -> Image.Image:
    c = Canvas(seed)
    c.ramps = [METAL, RUST]
    y, x = np.mgrid[0:N, 0:N]
    rib = np.array([1, 2, 3, 4, 4, 3, 2, 2])[x % 8]
    c.idx[:] = rib
    streak = (c.noise(16)[0][x] > 0.72) & (y > c.noise(4) * 24)
    rust = (c.noise(4) > 0.7) | streak
    c.pal[rust] = 1
    c.idx[rust] = rib[rust] - 1 + (c.noise(16)[rust] > 0.6).astype(int)
    c.idx[(y % 16 == 0)] = 0  # Panel seam.
    return c.image()


def concrete(seed: int) -> Image.Image:
    c = Canvas(seed)
    c.ramps = [CONCRETE, RUST]
    c.idx[:] = 3 + (c.noise(4) > 0.6).astype(int) - (c.noise(8) > 0.7).astype(int)
    c.idx[c.rng.random((N, N)) > 0.95] = 2
    crack = np.abs(c.noise(3) - 0.5) < 0.02
    c.idx[crack] = 1
    stain = c.noise(4) > 0.72
    c.idx[stain] = np.maximum(c.idx[stain] - 1, 1)
    return c.image()


def carpet(seed: int) -> Image.Image:
    """Red runner with a gold border on two sides (laid along x)."""
    c = Canvas(seed)
    c.ramps = [CARPET]
    y, x = np.mgrid[0:N, 0:N]
    c.idx[:] = 3 + ((x + y) % 8 == 0).astype(int) - ((x - y) % 8 == 0).astype(int)
    diamond = (np.abs((x % 16) - 8) + np.abs((y % 16) - 8)) == 4
    c.idx[diamond] = 4
    border = (y < 3) | (y > N - 4)
    c.idx[border] = 2
    c.idx[(y == 1) | (y == N - 2)] = 5
    return c.image()


def cave_floor(seed: int) -> Image.Image:
    return cobble(seed, CAVE)


def oil(seed: int) -> Image.Image:
    c = Canvas(seed)
    c.ramps = [ramp("#07080a", "#0e1114", "#171c22", "#24303a", "#3d4f5e", "#6a5a8a")]
    n = c.noise(4) * 0.6 + c.noise(8) * 0.4
    c.idx[:] = 1 + (n > 0.55).astype(int)
    sheen = (n > 0.62) & (n < 0.66)
    c.idx[sheen] = 3
    c.idx[(n > 0.635) & (n < 0.645)] = 5
    return c.image()


TEXTURES = {
    "grass_top": lambda: grass(1),
    "dirt_side": lambda: strata(2, DIRT, roots=True),
    "dirt_top": lambda: cobble(3, DIRT),
    "cobble_top": lambda: cobble(4, STONE),
    "cobble_moss_top": lambda: cobble(5, STONE, moss=True),
    "stone_brick_side": lambda: bricks(6, STONE),
    "stone_brick_moss_side": lambda: bricks(7, STONE, moss=True),
    "rock_top": lambda: rock(8, STONE),
    "rock_side": lambda: strata(9, STONE, pebbles=3),
    "sand_top": lambda: sand(10),
    "sandstone_top": lambda: flagstones(11, SANDSTONE, 16),
    "sandstone_side": lambda: strata(12, SANDSTONE, pebbles=2),
    "sandstone_brick_side": lambda: bricks(13, SANDSTONE, 16, 8),
    "cave_floor_top": lambda: cave_floor(14),
    "cave_wall_side": lambda: rock(15, CAVE),
    "castle_floor_top": lambda: flagstones(16, WARM_STONE, 16),
    "castle_wall_side": lambda: bricks(17, WARM_STONE, 16, 8),
    "carpet_top": lambda: carpet(18),
    "wood_top": lambda: planks(19, WOOD),
    "metal_top": lambda: metal_plate(20, 0.16),
    "grating_top": lambda: grating(21),
    "corrugated_side": lambda: corrugated(22),
    "concrete_top": lambda: concrete(23),
    "concrete_side": lambda: flagstones(24, CONCRETE, 16),
    "oil_top": lambda: oil(25),
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, make in TEXTURES.items():
        make().save(OUT / f"{name}.png")
    # Contact sheet to review them.
    names = list(TEXTURES)
    sheet = Image.new("RGB", (len(names) * (N * 4 + 4), N * 8 + 4), (0, 0, 0))
    for i, name in enumerate(names):
        img = Image.open(OUT / f"{name}.png")
        tiled = Image.new("RGB", (N * 2, N * 2))
        for ty in range(2):
            for tx in range(2):
                tiled.paste(img, (tx * N, ty * N))
        sheet.paste(tiled.resize((N * 4, N * 4), Image.NEAREST), (i * (N * 4 + 4), 0))
    sheet.save(Path("/tmp") / "terrain_sheet.png") if False else None
    print(len(names), "textures")


if __name__ == "__main__":
    main()
