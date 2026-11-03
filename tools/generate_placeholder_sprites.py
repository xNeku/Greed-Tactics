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

SPRITES.update({
    "lyra": {
        "palette": {
            "h": (120, 70, 190), "H": (78, 44, 130), "y": (236, 226, 170),
            "s": (246, 205, 170), "S": (214, 160, 128), "e": (30, 30, 50),
            "r": (64, 104, 200), "R": (40, 66, 140), "g": (240, 196, 70),
            "t": (130, 88, 52), "b": (70, 50, 80),
        },
        "art": [
            "..........hh..........",
            ".........hhhh.........",
            "........hhhhh.........",
            ".......hhhhhhh........",
            "......hhhhhhhh........",
            ".....hhhhhhhhhh.......",
            "...HHHHHHHHHHHHHH.....",
            "..HHHHHHHHHHHHHHHH.gg.",
            ".....yyysssssyy...gggg",
            ".....yyssssesss....gg.",
            ".....yysssseSss....t..",
            ".....yyyssssss.....t..",
            "......yy.SSSS......t..",
            ".....rrrrrrrrrr....t..",
            "....rrRrrrrrrRrr..st..",
            "....rrRrrggrrRrrsss...",
            "....rrRrrrrrrrRr...t..",
            "....rrRrrrrrrrRr...t..",
            "...rrrRrrrrrrrRrr..t..",
            "...rrRrrrrrrrrrRr..t..",
            "...rrRrrrrrrrrrrRr.t..",
            "..rrrRrrrrrrrrrrRrrt..",
            "..rrRRRRRRRRRRRRRRrt..",
            "......bbb...bbb....t..",
            ".....bbbb...bbbb......",
        ],
    },
    "nyx": {
        "palette": {
            "h": (70, 60, 96), "H": (44, 38, 64), "s": (236, 196, 166), "S": (200, 150, 120),
            "e": (200, 60, 90), "m": (180, 40, 60), "c": (52, 46, 74), "C": (32, 28, 48),
            "w": (220, 228, 240), "b": (96, 64, 44), "p": (40, 36, 56),
        },
        "art": [
            "......................",
            ".........hhhh.........",
            ".......hhhhhhhh.......",
            "......hhhhhhhhhh......",
            ".....hhhhhhhhhhhh.....",
            ".....hhhhHsssssHh.....",
            "....hhhhHssssesSh.....",
            "....hhhhHsssseSSh.....",
            ".....hhhHmmmmmmmh.....",
            ".....hhhhmmmmmmhh.....",
            "......hhhhmmmmhh......",
            "........cccccc...w....",
            "......cccccccccc.w....",
            ".....cCccccccccCsw....",
            ".....cCcccccccCssS....",
            ".....cCcbbbbbbbb......",
            "....w.CcccccccC.......",
            "...ws.CcccccccC.......",
            "....s..pppppppp.......",
            ".......pppp.pppp......",
            ".......ppp...ppp......",
            ".......ppp...ppp......",
            ".......bbb...bbb......",
            "......bbbb...bbbb.....",
        ],
    },
    "bat": {
        "palette": {"W": (92, 70, 120), "b": (60, 46, 82), "e": (250, 210, 80), "w": (240, 240, 250)},
        "art": [
            "..W..............W....",
            "..WW....bb.bb...WW....",
            "..WWW...bbbbb..WWW....",
            "..WWWW.bbbbbbb.WWWW...",
            "..WWWWWbbebbebbWWWW...",
            "...WWWWWbbbbbbWWWWW...",
            "...WWWWWWbwwbWWWWW....",
            "....WWW.WbbbbW.WWW....",
            ".....W...bbbb....W....",
            "..........bb..........",
            "......................",
            "......................",
            "......................",
            "......................",
            "......................",
            "......................",
        ],
    },
    "wolf": {
        "palette": {"g": (150, 150, 160), "G": (100, 100, 112), "e": (250, 200, 60), "n": (30, 30, 36), "d": (80, 80, 90)},
        "art": [
            "....................gg....",
            "...................gggg...",
            "..................ggggggg.",
            "..................ggggeggn",
            "..gg.............ggggggggg",
            ".ggg..ggggggggggggggggg...",
            ".gg..gggggggggggggggggg...",
            "....GggggggggggggggGGg....",
            "....GGgggggggggggggGG.....",
            "....GG.GG......GG..GG.....",
            "....GG.GG......GG..GG.....",
            "....dd.dd......dd..dd.....",
        ],
    },
    "boar": {
        "palette": {"b": (130, 84, 52), "B": (88, 56, 34), "e": (30, 20, 20), "p": (230, 150, 150), "W": (245, 240, 220), "h": (50, 36, 30)},
        "art": [
            "......bbbbbbbbbbbb........",
            "....bbbbbbbbbbbbbbbbb.....",
            "...bbbbbbbbbbbbbbbbbbbb...",
            "..bbbbbbbbbbbbbbbbbbbebb..",
            "..bbbbbbbbbbbbbbbbbbbbbbpp",
            "..BbbbbbbbbbbbbbbbbbbbbWpp",
            "..BBbbbbbbbbbbbbbbbbbbW...",
            "...BBbbbbbbbbbbbbbbbB.....",
            "....BB.BB......BB.BB......",
            "....BB.BB......BB.BB......",
            "....hh.hh......hh.hh......",
        ],
    },
    "scorpion": {
        "flip": True,
        "palette": {"s": (214, 140, 60), "S": (160, 96, 40), "c": (190, 110, 50), "e": (30, 20, 20), "t": (230, 170, 80), "l": (120, 70, 30)},
        "art": [
            "..............ttt.....",
            "................tt....",
            ".................t....",
            ".................tt...",
            "..........ssssss.ts...",
            "..cc....sssssssssss...",
            ".ccc..sssssssssssss...",
            ".cc.esssssssssssss....",
            "..ccsssssSSSSSSSs.....",
            "...l.l.l.l.l.l.l......",
            "..l.l.l.l.l.l.l.l.....",
        ],
    },
    "ogre": {
        "palette": {
            "s": (140, 160, 96), "S": (100, 118, 66), "e": (230, 60, 40), "m": (60, 30, 30), "W": (240, 236, 210),
            "r": (120, 84, 56), "R": (86, 58, 38), "b": (70, 50, 36), "t": (150, 104, 60),
        },
        "art": [
            "..........ssssssss..........",
            ".........ssssssssss.........",
            "........sssssssssssss.......",
            "........sssseessseess.......",
            "........ssssssssssssss......",
            "........sssmmmmmmmsss.......",
            ".........ssWsssssWss........",
            "......SSSSSSSSSSSSSSSSS.....",
            "....SSssssssssssssssssSSS...",
            "...SSsssssssssssssssssssSS..",
            "...Sssssrrrrrrrrrrrrsssssss.",
            "..SSsssrrrrrrrrrrrrrrssssSSt",
            "..Sssssrrrrrrrrrrrrrrssssttt",
            "..ssss.rrrrrrrrrrrrrr..stttt",
            "..sss..rRrrrrrrrrrrRr..tttt.",
            "..sss..bbbbbbbbbbbbbb..ttt..",
            ".......rRrrrrrrrrrRrr..tt...",
            ".......rRrrrrr.rrrRrr.......",
            ".......ssssss...ssssss......",
            ".......SSsss.....sssSS......",
            ".......SSsss.....sssSS......",
            "......bbbbbb.....bbbbbb.....",
        ],
    },
    "treant": {
        "palette": {"g": (84, 168, 80), "G": (52, 118, 58), "b": (120, 84, 54), "B": (82, 56, 36), "y": (250, 230, 90)},
        "art": [
            "......gggggggggggg..........",
            "....gggggGgggggggggg........",
            "...ggggGggggggggGggggg......",
            "..gggggggggGggggggggggg.....",
            "..ggGgggggggggggggGgggg.....",
            "...gggggggggggggggggggg.....",
            "....ggggbbbbbbbbgggggg......",
            "......bbbbbbbbbbbbb.........",
            "......bbbybbbbbybbb.........",
            "......bbbbbbbbbbbbb.........",
            "...bb.bbBbbbbbbBbbb.bb......",
            "..bb..bbbbbBBbbbbbb..bb.....",
            ".bb...bbbbbbbbbbbbb...bb....",
            ".gg...bbBbbbbbbBbbb....gg...",
            "......bbbbbbbbbbbbb.........",
            "......bbbBbbbbbbbbb.........",
            ".....bbbbb.....bbbbb........",
            "....bbbbb.......bbbbb.......",
            "...BBBB...........BBBB......",
        ],
    },
    "sandworm": {
        "palette": {"p": (220, 130, 130), "W": (250, 246, 230), "m": (110, 30, 40), "s": (214, 176, 110), "S": (170, 132, 80), "a": (232, 204, 140)},
        "art": [
            "..........pppppp..........",
            "........pppppppppp........",
            ".......ppWppWppWppp.......",
            "......ppmmmmmmmmmmpp......",
            "......pmmmmmmmmmmmmp......",
            "......ppmmmmmmmmmmpp......",
            ".......ppWppWppWppp.......",
            "........pppppppppp........",
            "........sSssssssSs........",
            ".......ssSsssssssSs.......",
            ".......sssssssssssss......",
            "......sSsssssssssSss......",
            "......ssssssssssssss......",
            ".....sSssssssssssssSs.....",
            ".....ssssssssssssssss.....",
            "....aaaaaaaaaaaaaaaaaa....",
            "..aaaaaaaaaaaaaaaaaaaaaa..",
        ],
    },
})

# Palette swaps of existing silhouettes.
SPRITES["bandit"] = {"art_of": "kael", "palette": dict(SPRITES["kael"]["palette"], **{
    "h": (150, 40, 40), "H": (100, 26, 26), "a": (200, 170, 120), "A": (150, 120, 80),
    "c": (90, 60, 40), "C": (60, 40, 26), "p": (110, 90, 60), "g": (200, 200, 210)})}
SPRITES["mummy"] = {"art_of": "kael", "palette": dict(SPRITES["kael"]["palette"], **{
    "h": (220, 214, 190), "H": (170, 164, 140), "s": (200, 194, 170), "S": (160, 152, 130), "e": (60, 220, 120),
    "a": (226, 220, 196), "A": (176, 170, 146), "c": (150, 140, 110), "C": (110, 100, 80),
    "p": (190, 184, 160), "b": (120, 110, 90), "w": (150, 140, 120), "g": (120, 110, 90)})}
SPRITES["goblin_archer"] = {"art_of": "pablo", "palette": dict(SPRITES["pablo"]["palette"], **{
    "h": (110, 80, 50), "H": (80, 56, 34), "s": (124, 186, 82), "S": (84, 136, 58), "e": (230, 60, 50),
    "t": (90, 70, 50), "T": (64, 50, 34)})}


# Status icons (assets/sprites/status/), 10x10 + outline.
ICONS = {
    "burn": {"palette": {"r": (230, 70, 40), "o": (255, 150, 40), "y": (255, 230, 110)}, "art": [
        "....r.....", "...rr.....", "...rro....", "..rroo.r..", "..roooorr.",
        ".rrooyoor.", ".rooyyoor.", ".rooyyyor.", "..rooyor..", "...rrrr...",
    ]},
    "poison": {"palette": {"g": (90, 200, 70), "G": (50, 140, 50), "l": (190, 255, 150)}, "art": [
        "....g.....", "...ggg....", "...ggg....", "..ggGgg...", ".gggGggg..",
        ".ggGlGgg..", ".gglllgg..", ".ggGlGgg..", "..ggggg...", "...ggg....",
    ]},
    "slow": {"palette": {"b": (110, 180, 255), "w": (235, 245, 255)}, "art": [
        "....b....", ".b..b..b.", "..b.b.b..", "...bbb...", "bbbbwbbbb",
        "...bbb...", "..b.b.b..", ".b..b..b.", "....b....",
    ]},
    "stun": {"palette": {"y": (255, 220, 70)}, "art": [
        "..y.......", ".yyy...y..", "..y...yyy.", ".......y..", "....y.....",
        "...yyy....", "....y.....",
    ]},
    "silence": {"palette": {"w": (235, 230, 250), "r": (220, 60, 80)}, "art": [
        ".wwwwwww.", "wwrwwwrww", "wwwrwrwww", "wwwwrwwww", "wwwrwrwww",
        "wwrwwwrww", ".wwwwwww.", "..ww.....", ".w.......",
    ]},
}


def render(spec: dict) -> Image.Image:
    rows = SPRITES[spec["art_of"]]["art"] if "art_of" in spec else spec["art"]
    width = max(len(r) for r in rows) + 2
    height = len(rows) + 2
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    pixels = image.load()
    for y, row in enumerate(rows):
        for x, key in enumerate(row):
            if key != ".":
                pixels[x + 1, y + 1] = spec["palette"][key] + (255,)
    _add_outline(image)
    if spec.get("flip"):
        image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
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
    icon_dir = OUT_DIR.parent / "status"
    icon_dir.mkdir(parents=True, exist_ok=True)
    for name, spec in ICONS.items():
        path = icon_dir / f"{name}.png"
        render(spec).save(path)
        print(f"wrote {path.relative_to(OUT_DIR.parent.parent.parent)}")


if __name__ == "__main__":
    main()
