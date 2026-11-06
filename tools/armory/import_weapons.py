#!/usr/bin/env python3
"""Imports the armory (tools/armory/armeria.html) into the game.

Input: a folder with the armory database as JSON files (weapons/<id>.json and
hands/<hero>.json), e.g. the out_dir of an ArtifactData read.
Output:
  assets/sprites/weapons/<id>.png        weapon pixel art (drawn weapons only)
  content/weapons/<id>.tres              WeaponData with grip and poses
  content/units/heroes/<hero>.tres       weapon + hand pixels of its owner

Usage: python3 tools/armory/import_weapons.py <armory_dump_dir>
Then: godot --headless --import && godot --headless --script res://tools/resave_resources.gd
"""
import json
import re
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SYMBOLS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
KINDS = {
    "Puños": "FISTS", "Daga": "DAGGER", "Espada": "SWORD", "Sable": "SABRE",
    "Mandoble": "GREATSWORD", "Hacha": "AXE", "Hacha a dos manos": "GREATAXE",
    "Martillo": "HAMMER", "Arco": "BOW", "Pistola": "PISTOL", "Bastón": "STAFF",
    "Varita": "WAND", "Manos (magia)": "MAGIC_HANDS",
}
KIND_INDEX = {name: i for i, name in enumerate(
    ["FISTS", "DAGGER", "SWORD", "SABRE", "GREATSWORD", "AXE", "GREATAXE", "HAMMER", "BOW", "PISTOL", "STAFF", "WAND", "MAGIC_HANDS"])}
# Weapon types carried one in each hand unless the armory says otherwise.
DUAL_TYPES = {"Daga", "Pistola"}


def decode(sprite: dict) -> Image.Image | None:
    if not sprite or not sprite.get("rows"):
        return None
    img = Image.new("RGBA", (sprite["w"], sprite["h"]), (0, 0, 0, 0))
    for y, row in enumerate(sprite["rows"]):
        for x, ch in enumerate(row):
            if ch != ".":
                hexa = sprite["palette"][SYMBOLS.index(ch)].lstrip("#")
                img.putpixel((x, y), tuple(int(hexa[i:i + 2], 16) for i in (0, 2, 4)) + (255,))
    return img if img.getbbox() else None


def esc(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"')


def pose_block(sub_id: str, pose: dict) -> str:
    lines = [f'[sub_resource type="Resource" id="{sub_id}"]', 'script = ExtResource("2_pose")']
    rot = float(pose.get("rot", 0)) % 360.0
    if rot > 180.0:
        rot -= 360.0
    if rot:
        lines.append(f"rotation_degrees = {rot:g}")
    if float(pose.get("scale", 1)) != 1.0:
        lines.append(f"scale = {float(pose['scale']):g}")
    if pose.get("flip"):
        lines.append("flip = true")
    if pose.get("layer") == "back":
        lines.append("behind = true")
    return "\n".join(lines) + "\n"


def write_weapon(w: dict) -> Path:
    wid = w["id"]
    img = decode(w.get("sprite"))
    ext = ['[ext_resource type="Script" path="res://core/data/weapon_data.gd" id="1_script"]',
           '[ext_resource type="Script" path="res://core/data/weapon_pose.gd" id="2_pose"]']
    subs = []
    props = ['script = ExtResource("1_script")', f'id = &"{wid}"', f'display_name = "{esc(w.get("name", wid))}"']
    kind = KINDS.get(w.get("type", ""), "SWORD")
    if KIND_INDEX[kind]:
        props.append(f"kind = {KIND_INDEX[kind]}")
    if w.get("description"):
        props.append(f'description = "{esc(w["description"])}"')
    if img is not None:
        png = ROOT / "assets/sprites/weapons" / f"{wid}.png"
        png.parent.mkdir(parents=True, exist_ok=True)
        img.save(png)
        ext.append(f'[ext_resource type="Texture2D" path="res://assets/sprites/weapons/{wid}.png" id="3_sprite"]')
        props.append('sprite = ExtResource("3_sprite")')
        grip = w.get("grip") or {"x": img.width // 2, "y": img.height // 2}
        props.append(f"grip = Vector2i({grip['x']}, {grip['y']})")
        poses = w.get("pose") or {}
        for view in ("front", "side"):
            pose = poses.get(view) or {"rot": 0, "scale": 1, "flip": bool(w.get("flip")), "layer": w.get("layer", "front")}
            subs.append(pose_block(f"Pose_{view}", pose))
            props.append(f'{view}_pose = SubResource("Pose_{view}")')
        if w.get("dual", w.get("type") in DUAL_TYPES):
            props.append("dual = true")
    out = ROOT / "content/weapons" / f"{wid}.tres"
    out.parent.mkdir(parents=True, exist_ok=True)
    text = '[gd_resource type="Resource" script_class="WeaponData" format=3]\n\n' + "\n".join(ext) + "\n\n"
    text += "".join(s + "\n" for s in subs)
    text += "[resource]\n" + "\n".join(props) + "\n"
    out.write_text(text)
    return out


def set_prop(text: str, name: str, value: str | None) -> str:
    """Sets (or removes, with None) a property line of the [resource] section."""
    head, body = text.split("[resource]\n", 1)
    body = re.sub(rf"^{name} = .*\n", "", body, flags=re.M)
    if value is not None:
        lines = body.split("\n")
        lines.insert(1, f"{name} = {value}")  # Right after `script = ...`.
        body = "\n".join(lines)
    return head + "[resource]\n" + body


def assign(hero: str, weapon_id: str | None, hands: dict) -> None:
    path = ROOT / "content/units/heroes" / f"{hero}.tres"
    if not path.exists():
        print(f"  ! no hero {hero}")
        return
    text = path.read_text()
    text = re.sub(r'\[ext_resource type="Resource" path="res://content/weapons/[^"]*" id="w_weapon"\]\n', "", text)
    if weapon_id:
        line = f'[ext_resource type="Resource" path="res://content/weapons/{weapon_id}.tres" id="w_weapon"]\n'
        text = text.replace("\n[resource]\n", "\n" + line + "\n[resource]\n", 1) if "\n\n[resource]" not in text else text.replace("\n\n[resource]\n", "\n" + line + "\n[resource]\n", 1)
    text = set_prop(text, "weapon", 'ExtResource("w_weapon")' if weapon_id else None)
    for view in ("front", "side"):
        hand = hands.get(view)
        text = set_prop(text, f"hand_{view}", f"Vector2i({hand['x']}, {hand['y']})" if hand else None)
        off = hands.get(f"{view}_off")
        text = set_prop(text, f"off_hand_{view}", f"Vector2i({off['x']}, {off['y']})" if off else None)
    path.write_text(text)


def main() -> None:
    dump = Path(sys.argv[1])
    weapons = [json.loads(p.read_text()) for p in sorted((dump / "weapons").glob("*.json"))]
    hands = {p.stem: json.loads(p.read_text()) for p in sorted((dump / "hands").glob("*.json"))}
    owners: dict[str, str] = {}
    for w in weapons:
        out = write_weapon(w)
        print(f"{w['id']}: {out.relative_to(ROOT)}")
        for hero in w.get("heroes", []):
            owners.setdefault(hero, w["id"])
    for hero in sorted(set(owners) | set(hands)):
        assign(hero, owners.get(hero), hands.get(hero, {}))
        print(f"  {hero}: {owners.get(hero)}")


if __name__ == "__main__":
    main()
