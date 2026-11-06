"""Pixel art of the projectiles (facing RIGHT, travel direction = +x).

python3 art/src/projectile_sprites.py  ->  assets/sprites/vfx/<name>.png
"""
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "assets/sprites/vfx"

PALETTE = {
    "k": (20, 16, 18), "w": (236, 228, 214), "W": (255, 255, 255),
    "b": (122, 82, 48), "B": (84, 54, 32), "s": (168, 174, 184), "S": (98, 104, 116),
    "f": (214, 72, 58), "F": (150, 40, 36), "g": (96, 168, 72), "G": (52, 104, 46),
    "y": (255, 214, 92), "Y": (214, 150, 40), "o": (255, 150, 60),
    "r": (128, 118, 104), "R": (86, 78, 70), "t": (168, 156, 136),
    "i": (176, 236, 255), "I": (96, 170, 230), "j": (230, 250, 255),
    "d": (226, 196, 140), "D": (178, 140, 86),
}

SPRITES = {
    # Arrow: fletching, shaft, iron head.
    "arrow": [
        "ff..........k..",
        ".Ff........kSk.",
        "kffbbbbbbbbbsSk",
        ".Ff........kSk.",
        "ff..........k..",
    ],
    # Heavy arrow of the aimed shot: longer, glowing head.
    "arrow_heavy": [
        "ff.............k...",
        ".ff...........kyk..",
        "kFfbbbbbbbbbbbkyWyk",
        ".ff...........kyk..",
        "ff.............k...",
    ],
    # Lead ball of the flintlock.
    "bullet": [
        ".kk.",
        "kWsk",
        "ksSk",
        ".kk.",
    ],
    # Poisoned dart.
    "dart": [
        "g.......",
        "GgBBBBsW",
        "g.......",
    ],
    # Chunk of rubble.
    "rock": [
        "..kkk..",
        ".ktrrk.",
        "ktrrrRk",
        "krrRRRk",
        "kRrRRk.",
        ".kkkk..",
    ],
    # Ice shard.
    "ice_shard": [
        "......kk.....",
        "..kkkkijkk...",
        "kIIIiijjjjWkk",
        "..kkkkIijkk..",
        "......kk.....",
    ],
    # Spear of light.
    "light_spear": [
        "...............k...",
        "y.............kyk..",
        "YyyyyyyyyyyyyyyWWyk",
        "y.............kyk..",
        "...............k...",
    ],
    # Spike of packed sand.
    "sand_spike": [
        ".....kk...",
        "kkkkkdDkk.",
        "DddddddddW",
        "kkkkkDdkk.",
        ".....kk...",
    ],
    # Seed bomb.
    "seed": [
        ".kGk.",
        "kgggk",
        "kgGgk",
        ".kkk.",
    ],
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, rows in SPRITES.items():
        width = max(len(r) for r in rows)
        img = Image.new("RGBA", (width, len(rows)), (0, 0, 0, 0))
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch != ".":
                    img.putpixel((x, y), PALETTE[ch] + (255,))
        img.save(OUT / f"{name}.png")
        print(name, img.size)


if __name__ == "__main__":
    main()
