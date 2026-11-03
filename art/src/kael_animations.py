#!/usr/bin/env python3
"""Builds Kael's (brawler) animation sheet from the two base views.

Input:  assets/sprites/units/kael.png (front) and kael_side.png (side, facing right).
Output: assets/sprites/units/kael_sheet.png + kael_sheet.json, consumed by
        tools/build_sprite_frames.gd to create content/units/heroes/kael_frames.tres.

Animations are made by moving regions of the base sprites (head, arms, legs)
pixel by pixel and drawing a few overlays (punching arm, fist), so they stay
pixel perfect and in the original palette. Usage: python3 art/src/kael_animations.py
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
UNITS = ROOT / "assets" / "sprites" / "units"
CELL = (26, 30)  # every frame canvas; feet on the last row

OUTLINE = (1, 1, 1, 255)
SKIN = (198, 139, 106, 255)
SKIN_DARK = (163, 102, 74, 255)
WRAP = (226, 220, 204, 255)
WRAP_DARK = (176, 170, 158, 255)


def load(name):
    return Image.open(UNITS / name).convert("RGBA")


def place(sprite, dx=0, dy=0, anchor_x=None):
    """Sprite on a CELL canvas, feet on the bottom row, centered (or at anchor_x)."""
    canvas = Image.new("RGBA", CELL, (0, 0, 0, 0))
    x = (CELL[0] - sprite.width) // 2 if anchor_x is None else anchor_x
    canvas.alpha_composite(sprite, (x + dx, CELL[1] - sprite.height + dy))
    return canvas


def move_region(img, box, dx, dy):
    """Cuts box=(x0, y0, x1, y1) and pastes it shifted (alpha composited on top)."""
    out = img.copy()
    piece = img.crop(box)
    out.paste((0, 0, 0, 0), box)
    out.alpha_composite(piece, (box[0] + dx, box[1] + dy))
    return out


def move_regions(img, boxes, dx, dy):
    """Like move_region but for a piece made of several boxes (moved together)."""
    out = img.copy()
    pieces = [(box, img.crop(box)) for box in boxes]
    for box, _ in pieces:
        out.paste((0, 0, 0, 0), box)
    for box, piece in pieces:
        out.alpha_composite(piece, (box[0] + dx, box[1] + dy))
    return out


def pad(img, left=0, top=0, right=0, bottom=0):
    out = Image.new("RGBA", (img.width + left + right, img.height + top + bottom), (0, 0, 0, 0))
    out.alpha_composite(img, (left, top))
    return out


def draw(img, pixels, color):
    out = img.copy()
    for x, y in pixels:
        if 0 <= x < out.width and 0 <= y < out.height:
            out.putpixel((x, y), color)
    return out


def front_frames(front):
    w, h = front.size  # 19x27
    head = (0, 0, w, 14)
    # Arms: wide at the shoulder, narrow at the wrist/hand (rows 19-20).
    left_arm = [(0, 12, 5, 19), (0, 19, 4, 21)]
    right_arm = [(14, 12, w, 19), (15, 19, w, 21)]
    left_leg, right_leg = (3, 19, 10, h), (10, 19, 16, h)
    base = front
    breathe = move_region(base, head, 0, 1)
    step_l = move_regions(move_region(base, left_leg, 0, -1), right_arm, 0, -1)
    step_r = move_regions(move_region(base, right_leg, 0, -1), left_arm, 0, -1)
    guard = move_regions(move_regions(base, left_arm, 0, -2), right_arm, 0, -2)
    # Punch towards the camera: right arm swings in and up, ending in a big
    # wrapped fist in front of the chest (foreshortened).
    punch = move_regions(guard, right_arm, -2, -1)
    punch = draw(punch, [(x, y) for x in range(9, 16) for y in range(11, 18)], OUTLINE)
    punch = draw(punch, [(x, y) for x in range(10, 15) for y in range(12, 17)], WRAP)
    punch = draw(punch, [(x, 16) for x in range(10, 15)] + [(14, y) for y in range(12, 17)], WRAP_DARK)
    punch = draw(punch, [(11, 12), (13, 12)], SKIN)
    hit = move_regions(move_region(base, head, 1, 1), left_arm + right_arm, 0, 1)
    return {
        "idle_front": [base, breathe],
        "walk_front": [step_l, base, step_r, base],
        "attack_front": [guard, punch, guard],
        "hit_front": [hit],
    }


def side_frames(side):
    side = pad(side, right=6)  # room for the punching arm
    w, h = side.size  # 20x27, facing right
    upper = (0, 0, w, 22)
    back_arm = (3, 12, 8, 20)
    base = side
    breathe = move_region(base, (0, 0, w, 14), 0, 1)
    hop = move_region(base, upper, 0, -1)
    swing = move_region(base, back_arm, 1, 0)
    wind_up = move_region(base, upper, -1, 0)
    # Straight punch forward at chest height from the front of the torso.
    punch = move_region(base, upper, 1, 0)
    y = 15
    arm = [(x, yy) for x in range(9, 17) for yy in (y - 1, y + 2)]
    punch = draw(punch, arm, OUTLINE)
    punch = draw(punch, [(x, yy) for x in range(9, 14) for yy in (y, y + 1)], SKIN)
    punch = draw(punch, [(x, y + 1) for x in range(9, 13)], SKIN_DARK)
    punch = draw(punch, [(x, yy) for x in range(14, 17) for yy in (y, y + 1)], WRAP)
    punch = draw(punch, [(17, y), (17, y + 1), (14, y - 1), (14, y + 2)], OUTLINE)
    punch = draw(punch, [(16, y + 1)], WRAP_DARK)
    hit = move_region(base, upper, -1, 1)
    return {
        "idle_side": [base, breathe],
        "walk_side": [hop, swing, hop, base],
        "attack_side": [wind_up, punch, base],
        "hit_side": [hit],
    }


ANIMS = [
    # name, fps, loop
    ("idle_front", 2.2, True),
    ("idle_side", 2.2, True),
    ("walk_front", 8.0, True),
    ("walk_side", 8.0, True),
    ("attack_front", 10.0, False),
    ("attack_side", 10.0, False),
    ("hit_front", 4.0, False),
    ("hit_side", 4.0, False),
]


def main():
    front = load("kael.png")
    side = load("kael_side.png")
    frames = {**front_frames(front), **side_frames(side)}
    columns = max(len(f) for f in frames.values())
    sheet = Image.new("RGBA", (CELL[0] * columns, CELL[1] * len(ANIMS)), (0, 0, 0, 0))
    meta = {"cell": list(CELL), "animations": []}
    for row, (name, fps, loop) in enumerate(ANIMS):
        is_side = name.endswith("_side")
        for col, img in enumerate(frames[name]):
            cell = place(img, anchor_x=3 if is_side else None)
            sheet.alpha_composite(cell, (col * CELL[0], row * CELL[1]))
        meta["animations"].append({"name": name, "row": row, "frames": len(frames[name]), "fps": fps, "loop": loop})
    sheet.save(UNITS / "kael_sheet.png")
    (UNITS / "kael_sheet.json").write_text(json.dumps(meta, indent=2))
    print("wrote kael_sheet.png", sheet.size)


if __name__ == "__main__":
    main()
