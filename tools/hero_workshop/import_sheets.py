#!/usr/bin/env python3
"""Imports Neku's sprite edits from the hero workshop artifact into assets/.

Input: a folder with the workshop database dumped as JSON (ArtifactData `list`
with `out_dir`): <dump>/heroes/<id>.json and <dump>/enemies/<id>.json.
Writes assets/sprites/units/<id>.png (front) and <id>_side.png (side) when they
differ from the current files, and rebuilds Kael's animation sheet if needed
(then run tools/build_sprite_frames.gd, see the printed hint).
Weapons, passives and unlocks are design notes for now: they are only listed.

Usage: python3 tools/hero_workshop/import_sheets.py <dump folder>
"""
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
UNITS = ROOT / "assets" / "sprites" / "units"
SYMBOLS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
ANIMATED = {"kael": "art/src/kael_animations.py"}


def to_image(sprite: dict) -> Image.Image:
    image = Image.new("RGBA", (sprite["w"], sprite["h"]), (0, 0, 0, 0))
    pixels = image.load()
    for y, row in enumerate(sprite["rows"]):
        for x, symbol in enumerate(row):
            if symbol == ".":
                continue
            hex_color = sprite["palette"][SYMBOLS.index(symbol)].lstrip("#")
            pixels[x, y] = tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
    return image


def same(a: Image.Image, b: Image.Image) -> bool:
    return a.size == b.size and a.tobytes() == b.tobytes()


def main() -> None:
    dump = Path(sys.argv[1])
    rebuild = set()
    for doc_path in sorted(dump.glob("*/*.json")):
        doc = json.loads(doc_path.read_text())
        sprites = doc.get("sprites") or {}
        for view, suffix in (("front", ""), ("side", "_side")):
            sprite = sprites.get(view)
            if not sprite or not any(c != "." for row in sprite["rows"] for c in row):
                continue
            target = UNITS / f"{doc['id']}{suffix}.png"
            image = to_image(sprite)
            if target.exists() and same(Image.open(target).convert("RGBA"), image):
                continue
            image.save(target)
            print(f"updated {target.relative_to(ROOT)}")
            if doc["id"] in ANIMATED:
                rebuild.add(doc["id"])
        weapon = doc.get("weapon") or {}
        if weapon.get("sprite") and any(c != "." for row in weapon["sprite"]["rows"] for c in row):
            print(f"note: {doc['id']} has a weapon sprite ({weapon.get('name')}) - not wired into the game yet")
        for key in ("passives", "unlocks"):
            if doc.get(key) and doc_path.parent.name == "heroes" and key == "passives":
                print(f"note: {doc['id']} has {len(doc[key])} passives designed")
    for hero in sorted(rebuild):
        subprocess.run([sys.executable, str(ROOT / ANIMATED[hero])], check=True)
        print(f"rebuilt {hero} animations: now run\n  godot --headless --script res://tools/build_sprite_frames.gd -- "
              f"res://assets/sprites/units/{hero}_sheet.png res://content/units/heroes/{hero}_frames.tres")


if __name__ == "__main__":
    main()
