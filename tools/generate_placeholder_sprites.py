#!/usr/bin/env python3
"""Generates the placeholder unit sprites in assets/sprites/units/.

Each sprite is drawn as ASCII art (one char per pixel, facing RIGHT, feet on the
last row). A dark 1px outline is added automatically around opaque pixels.

Usage:  python3 tools/generate_placeholder_sprites.py
Needs:  pip install pillow
These are placeholders until the final art arrives (see docs/BACKLOG.md).
"""
from pathlib import Path

from PIL import Image

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sprites" / "units"
OUTLINE = (28, 24, 40, 255)

SPRITES = {
    "kael": {
        "palette": {
            "h": (70, 92, 170), "H": (48, 62, 128),
            "s": (246, 205, 170), "S": (214, 160, 128), "e": (30, 30, 50),
            "a": (205, 214, 228), "A": (140, 150, 172), "g": (240, 196, 70),
            "c": (196, 58, 64), "C": (140, 36, 48), "b": (110, 72, 48),
            "p": (60, 64, 92), "w": (232, 240, 255),
        },
        "art": [
            "......................",
            "........hhhhhh........",
            "......hhhhhhhhhh......",
            ".....hhhhhhhhhhhh.....",
            ".....hhhhhhhhhhhhh....",
            "....hhhhhhhssshhhh....",
            "....Hhhhhhsssssshh....",
            "....HHhhhssssesss.....",
            ".....HhhhssssesSs.....",
            ".....HHhhsssssssS.....",
            "......HHhSsssssS......",
            "........SSSSSS........",
            "......caaaaaaaac......",
            ".....ccaAaaaaaaAc...w.",
            ".....ccaAaagaaaAc..ww.",
            "....cccaAaaaasssS.ww..",
            "....cccaAaaaasssSgw...",
            "....cccbbbbbbbbbgg....",
            "....ccCaAaaaaaaA.g....",
            "....ccCaAaaaaaaAc.....",
            ".....cCpppppppppc.....",
            ".....CCpppp..pppC.....",
            "......Cppp...ppp......",
            ".......ppp...ppp......",
            ".......AAA...AAA......",
            "......AAAA...AAAA.....",
        ],
    },
    "pablo": {
        "palette": {
            "h": (78, 150, 84), "H": (48, 104, 60),
            "s": (240, 196, 158), "S": (204, 150, 116), "e": (30, 30, 50),
            "t": (150, 104, 62), "T": (110, 74, 44), "b": (84, 56, 36),
            "o": (176, 120, 60), "q": (232, 224, 200), "p": (70, 80, 60),
            "y": (230, 190, 90),
        },
        "art": [
            "......................",
            ".........hhhh.........",
            ".......hhhhhhhh.......",
            "......hhhhhhhhhh......",
            ".....hhhhhhhhhhhh.....",
            ".....hhhhhhssssshh....",
            "....HhhhhhssssssSh....",
            "....HHhhhsssssessh....",
            ".....HhhhssssseSs..o..",
            ".....HHhhsssssssS..oo.",
            "......HHhSsssssS...q.o",
            ".......HHSSSSSS....q.o",
            "....qq.tttttttttt..q.o",
            "....bqttTttttttTtt.q.o",
            "....bqtTttyyyttTsssq.o",
            "....bbtTttttttttsSSq.o",
            ".....btTtttttttt...q.o",
            ".....bbbbbbbbbbb...qoo",
            "......tTtttttttT...oo.",
            "......tTttttttttT..o..",
            ".......ppppppppp......",
            ".......pppp..pppp.....",
            ".......ppp....ppp.....",
            ".......ppp....ppp.....",
            ".......bbb....bbb.....",
            "......bbbb....bbbb....",
        ],
    },
    "goblin": {
        "palette": {
            "s": (124, 186, 82), "S": (84, 136, 58), "e": (230, 60, 50),
            "m": (40, 30, 30), "r": (128, 92, 64), "R": (92, 64, 44),
            "b": (70, 50, 36), "w": (210, 214, 224), "g": (190, 150, 60),
        },
        "art": [
            "......................",
            "......................",
            "......................",
            "........ssssss........",
            "......ssssssssss......",
            ".SS..sssssssssssss..SS",
            "..SSssssssssssssssssS.",
            "...SSssssssseesssssS..",
            ".....sssssssseessss...",
            ".....Ssssssssssssss...",
            "......Ssssssmmmsss....",
            ".......SSssssssSS.....",
            ".........SSSSSS.......",
            "......rrrrrrrrrr......",
            ".....rrRrrrrrrRrr.....",
            ".....rrRrrrrrrRrsss...",
            ".....SsRrrrrrrRrsSSw..",
            ".....SSbbbbbbbbbbg.ww.",
            "......rRrrrrrrrRr..w..",
            "......rRrrrrrrrrR.....",
            ".......ssss..ssss.....",
            ".......SSs....sSS.....",
            ".......SSs....sSS.....",
            ".......bbb....bbb.....",
            "......bbbb....bbbb....",
        ],
    },
    "slime": {
        "palette": {
            "s": (150, 110, 220), "S": (104, 72, 170), "l": (204, 180, 250),
            "e": (30, 24, 50), "w": (250, 250, 255), "m": (70, 40, 110),
        },
        "art": [
            "......................",
            "......................",
            "......................",
            "......................",
            "......................",
            "......................",
            "......................",
            "..........ss..........",
            ".........ssss.........",
            "........sslsss........",
            ".......sslllsss.......",
            "......sslllssssS......",
            ".....ssllsssssssS.....",
            "....sslssssweswesS....",
            "....slsssssweeweesS...",
            "...sslssssseessessS...",
            "...ssssssssssmmsssS...",
            "..sssssssssssssssssS..",
            "..ssssssssssssssssSS..",
            "..SssssssssssssssSSS..",
            "...SSssssssssssSSSS...",
            "....SSSSSSSSSSSSSS....",
        ],
    },
}


def render(spec: dict) -> Image.Image:
    rows = spec["art"]
    width = max(len(r) for r in rows) + 2
    height = len(rows) + 2
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    pixels = image.load()
    for y, row in enumerate(rows):
        for x, key in enumerate(row):
            if key != ".":
                pixels[x + 1, y + 1] = spec["palette"][key] + (255,)
    _add_outline(image)
    return image


def _add_outline(image: Image.Image) -> None:
    pixels = image.load()
    width, height = image.size
    solid = {(x, y) for x in range(width) for y in range(height) if pixels[x, y][3] > 0}
    for x in range(width):
        for y in range(height):
            if (x, y) in solid:
                continue
            if any((x + dx, y + dy) in solid for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                pixels[x, y] = OUTLINE


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, spec in SPRITES.items():
        path = OUT_DIR / f"{name}.png"
        render(spec).save(path)
        print(f"wrote {path.relative_to(OUT_DIR.parent.parent.parent)}")


if __name__ == "__main__":
    main()
