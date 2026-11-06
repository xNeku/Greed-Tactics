#!/usr/bin/env python3
"""Writes the scenery prop scenes (v0.9) as .tscn files.

Simple geometry (boxes, faceted cylinders) dressed with the pixel materials of
assets/materials (world triplanar, 32 px per unit, so they match the terrain)
plus fire, lights and billboard sprites. Re-run after changing a recipe, then
`godot --headless --script res://tools/resave_resources.gd`.

python3 tools/build_scenery_props.py
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "scenes/battle/props/scenery"


class Scene:
    def __init__(self, name: str, description: str) -> None:
        self.name = name
        self.description = description
        self.ext: list[tuple[str, str, str]] = []  # (type, path, id)
        self.sub: list[str] = []
        self.nodes: list[str] = []
        self._ids = 0

    def res(self, kind: str, path: str) -> str:
        for t, p, i in self.ext:
            if p == path:
                return i
        rid = f"{len(self.ext) + 1}_r"
        self.ext.append((kind, path, rid))
        return rid

    def mat(self, name: str) -> str:
        return self.res("Material", f"res://assets/materials/pixel_{name}.tres")

    def _sub(self, kind: str, body: str) -> str:
        self._ids += 1
        sid = f"{kind}_{self._ids}"
        self.sub.append(f'[sub_resource type="{kind}" id="{sid}"]\n{body}')
        return sid

    def box(self, node: str, size, pos, material: str, parent: str = ".", rot_y: float = 0.0) -> None:
        mid = self._sub("BoxMesh", f'material = ExtResource("{self.mat(material)}")\nsize = Vector3({size[0]}, {size[1]}, {size[2]})')
        self.nodes.append(self._mesh_node(node, mid, pos, parent, rot_y))

    def cylinder(self, node: str, radius: float, height: float, pos, material: str, parent: str = ".",
                 segments: int = 8, top: float | None = None, axis: str = "y") -> None:
        top = radius if top is None else top
        mid = self._sub("CylinderMesh", f'material = ExtResource("{self.mat(material)}")\ntop_radius = {top}\n'
                        f'bottom_radius = {radius}\nheight = {height}\nradial_segments = {segments}\nrings = 1')
        basis = {"y": "1, 0, 0, 0, 1, 0, 0, 0, 1", "x": "0, -1, 0, 1, 0, 0, 0, 0, 1", "z": "1, 0, 0, 0, 0, -1, 0, 1, 0"}[axis]
        self.nodes.append(f'[node name="{node}" type="MeshInstance3D" parent="{parent}"]\n'
                          f'transform = Transform3D({basis}, {pos[0]}, {pos[1]}, {pos[2]})\nmesh = SubResource("{mid}")')

    def _mesh_node(self, node: str, mid: str, pos, parent: str, rot_y: float) -> str:
        import math
        c, s = math.cos(rot_y), math.sin(rot_y)
        return (f'[node name="{node}" type="MeshInstance3D" parent="{parent}"]\n'
                f'transform = Transform3D({c:.4f}, 0, {-s:.4f}, 0, 1, 0, {s:.4f}, 0, {c:.4f}, {pos[0]}, {pos[1]}, {pos[2]})\n'
                f'mesh = SubResource("{mid}")')

    def flame(self, node: str, pos, size=(0.22, 0.36), seed: float = 0.0, parent: str = ".") -> None:
        shader = self.res("Shader", "res://assets/shaders/pixel_flame.gdshader")
        mat = self._sub("ShaderMaterial", f'render_priority = 3\nshader = ExtResource("{shader}")\nshader_parameter/seed = {seed}')
        quad = self._sub("QuadMesh", f'material = SubResource("{mat}")\nsize = Vector2({size[0]}, {size[1]})')
        self.nodes.append(f'[node name="{node}" type="MeshInstance3D" parent="{parent}"]\n'
                          f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {pos[0]}, {pos[1]}, {pos[2]})\n'
                          f'cast_shadow = 0\nmesh = SubResource("{quad}")')

    def light(self, node: str, pos, color, energy: float, light_range: float, flicker: float = 0.25,
              stutter: bool = False, shadows: bool = False, parent: str = ".") -> None:
        script = self.res("Script", "res://scenes/battle/props/flicker_light.gd")
        self.nodes.append(f'[node name="{node}" type="OmniLight3D" parent="{parent}"]\n'
                          f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {pos[0]}, {pos[1]}, {pos[2]})\n'
                          f'light_color = Color({color[0]}, {color[1]}, {color[2]}, 1)\nlight_energy = {energy}\n'
                          f'light_volumetric_fog_energy = 1.5\nshadow_enabled = {"true" if shadows else "false"}\n'
                          f'omni_range = {light_range}\nomni_attenuation = 1.4\nscript = ExtResource("{script}")\n'
                          f'base_energy = {energy}\nflicker = {flicker}\nstutter = {"true" if stutter else "false"}')

    def sprite(self, node: str, texture: str, pos, pixel_size: float = 0.036, parent: str = ".") -> None:
        tex = self.res("Texture2D", texture)
        self.nodes.append(f'[node name="{node}" type="Sprite3D" parent="{parent}"]\n'
                          f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {pos[0]}, {pos[1]}, {pos[2]})\n'
                          f'offset = Vector2(0, 0)\ncentered = true\npixel_size = {pixel_size}\nbillboard = 2\nshaded = true\n'
                          f'alpha_cut = 1\ntexture_filter = 0\ntexture = ExtResource("{tex}")')

    def embers(self, node: str, pos, amount: int = 10, parent: str = ".") -> None:
        shader = self.res("Shader", "res://assets/shaders/pixel_particle.gdshader")
        mat = self._sub("ShaderMaterial", f'render_priority = 3\nshader = ExtResource("{shader}")\nshader_parameter/energy = 2.0')
        quad = self._sub("QuadMesh", f'material = SubResource("{mat}")\nsize = Vector2(0.04, 0.04)')
        grad = self._sub("Gradient", 'offsets = PackedFloat32Array(0, 0.6, 1)\n'
                         'colors = PackedColorArray(1, 0.85, 0.4, 1, 1, 0.45, 0.15, 1, 0.6, 0.15, 0.05, 0)')
        self.nodes.append(f'[node name="{node}" type="CPUParticles3D" parent="{parent}"]\n'
                          f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {pos[0]}, {pos[1]}, {pos[2]})\n'
                          f'amount = {amount}\nlifetime = 1.2\nmesh = SubResource("{quad}")\nemission_shape = 1\n'
                          f'emission_sphere_radius = 0.08\ndirection = Vector3(0, 1, 0)\nspread = 25.0\n'
                          f'gravity = Vector3(0, 0.6, 0)\ninitial_velocity_min = 0.2\ninitial_velocity_max = 0.6\n'
                          f'color_ramp = SubResource("{grad}")')

    def write(self) -> None:
        lines = ["[gd_scene format=3]", ""]
        for kind, path, rid in self.ext:
            lines.append(f'[ext_resource type="{kind}" path="{path}" id="{rid}"]')
        lines.append("")
        for sub in self.sub:
            lines += [sub, ""]
        lines.append(f'[node name="{self.name}" type="Node3D"]\neditor_description = "{self.description}"\n')
        for node in self.nodes:
            lines += [node, ""]
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / f"{_snake(self.name)}.tscn").write_text("\n".join(lines))


def _snake(name: str) -> str:
    out = ""
    for i, ch in enumerate(name):
        if ch.isupper() and i:
            out += "_"
        out += ch.lower()
    return out


def pillar(name: str, material: str, broken: bool) -> Scene:
    s = Scene(name, "Stone column on a cell (blocks sight).")
    s.box("Base", (0.78, 0.22, 0.78), (0, 0.11, 0), material)
    s.box("Plinth", (0.62, 0.14, 0.62), (0, 0.29, 0), material)
    shaft = 1.3 if broken else 2.3
    s.cylinder("Shaft", 0.24, shaft, (0, 0.36 + shaft / 2, 0), material, segments=8)
    if broken:
        s.box("Chunk", (0.32, 0.22, 0.28), (0.36, 0.11, -0.22), material, rot_y=0.6)
        s.box("Chip", (0.18, 0.12, 0.16), (-0.33, 0.06, 0.3), material, rot_y=1.1)
        s.cylinder("Top", 0.24, 0.12, (0.03, 0.36 + shaft + 0.04, 0.02), material, segments=8, top=0.16)
    else:
        s.box("Capital", (0.7, 0.18, 0.7), (0, 0.36 + shaft + 0.09, 0), material)
        s.box("Abacus", (0.82, 0.1, 0.82), (0, 0.36 + shaft + 0.23, 0), material)
    return s


def build() -> None:
    pillar("PillarRuin", "brick_moss", True).write()
    pillar("PillarStone", "brick", False).write()
    pillar("PillarCastle", "castle", False).write()
    pillar("PillarSandstone", "sandstone", True).write()

    s = Scene("Crates", "Stacked wooden crates (low cover).")
    s.box("Big", (0.66, 0.6, 0.66), (0, 0.3, 0), "wood", rot_y=0.2)
    s.box("Small", (0.44, 0.4, 0.44), (0.12, 0.8, -0.05), "wood", rot_y=-0.35)
    s.write()

    s = Scene("Barrels", "Two barrels bound with iron.")
    for i, (x, z) in enumerate(((-0.17, 0.08), (0.2, -0.1))):
        s.cylinder(f"Barrel{i}", 0.25, 0.72, (x, 0.36, z), "wood", segments=10, top=0.25)
        s.cylinder(f"Hoop{i}a", 0.265, 0.05, (x, 0.18, z), "metal", segments=10)
        s.cylinder(f"Hoop{i}b", 0.265, 0.05, (x, 0.56, z), "metal", segments=10)
    s.write()

    s = Scene("WallTorch", "Torch on a wall face: fire, embers and a flickering light.")
    s.box("Bracket", (0.08, 0.08, 0.22), (0, 0, -0.11), "metal")
    s.cylinder("Stick", 0.04, 0.34, (0, 0.12, 0.02), "wood", segments=6)
    s.flame("Flame", (0, 0.42, 0.04), seed=1.7)
    s.embers("Embers", (0, 0.42, 0.04), 6)
    s.light("Light", (0, 0.5, 0.35), (1.0, 0.62, 0.3), 1.6, 4.5, 0.3)
    s.write()

    s = Scene("Brazier", "Iron brazier with a big fire (blocks the cell).")
    for i, a in enumerate((0.0, 2.09, 4.19)):
        import math
        s.box(f"Leg{i}", (0.06, 0.62, 0.06), (math.cos(a) * 0.2, 0.31, math.sin(a) * 0.2), "metal", rot_y=a)
    s.cylinder("Bowl", 0.34, 0.24, (0, 0.72, 0), "metal", segments=10, top=0.4)
    s.box("Coals", (0.44, 0.06, 0.44), (0, 0.82, 0), "rust")
    s.flame("Flame", (0, 1.15, 0), (0.48, 0.72), seed=3.1)
    s.embers("Embers", (0, 1.1, 0), 16)
    s.light("Light", (0, 1.3, 0), (1.0, 0.58, 0.26), 2.6, 6.0, 0.25, shadows=True)
    s.write()

    s = Scene("Lamp", "Factory lamp post with a sodium light that sometimes fails.")
    s.box("Foot", (0.34, 0.12, 0.34), (0, 0.06, 0), "metal")
    s.cylinder("Pole", 0.06, 2.4, (0, 1.2, 0), "metal", segments=6)
    s.box("Arm", (0.6, 0.07, 0.07), (0.27, 2.36, 0), "metal")
    s.box("Head", (0.26, 0.12, 0.2), (0.52, 2.3, 0), "metal")
    s.flame("Bulb", (0.52, 2.22, 0), (0.12, 0.08), seed=0.4)
    s.light("Light", (0.52, 2.1, 0), (1.0, 0.66, 0.32), 2.4, 6.5, 0.05, stutter=True)
    s.write()

    s = Scene("Pipes", "Rusty pipes running over a machine.")
    s.cylinder("PipeA", 0.11, 1.0, (0, 0.14, -0.2), "rust", segments=8, axis="x")
    s.cylinder("PipeB", 0.08, 1.0, (0, 0.1, 0.18), "metal", segments=8, axis="x")
    s.box("Valve", (0.12, 0.28, 0.12), (0.18, 0.28, -0.2), "metal")
    s.cylinder("Wheel", 0.13, 0.04, (0.18, 0.44, -0.2), "rust", segments=8)
    s.write()

    s = Scene("Throne", "Stone throne with a red cushion on the boss dais.")
    s.box("Seat", (0.7, 0.4, 0.6), (0, 0.2, 0), "castle")
    s.box("Back", (0.7, 1.3, 0.16), (0, 0.85, -0.24), "castle")
    s.box("Crest", (0.36, 0.3, 0.14), (0, 1.62, -0.24), "castle")
    s.box("Cushion", (0.56, 0.08, 0.46), (0, 0.44, 0.04), "carpet")
    s.box("ArmL", (0.12, 0.3, 0.5), (-0.33, 0.55, 0.02), "castle")
    s.box("ArmR", (0.12, 0.3, 0.5), (0.33, 0.55, 0.02), "castle")
    s.write()

    s = Scene("Rubble", "Fallen stones (decoration, walkable).")
    s.box("A", (0.22, 0.14, 0.18), (0.1, 0.07, 0.05), "brick_moss", rot_y=0.5)
    s.box("B", (0.14, 0.1, 0.12), (-0.18, 0.05, -0.12), "brick_moss", rot_y=1.3)
    s.box("C", (0.1, 0.08, 0.1), (-0.05, 0.04, 0.22), "rock", rot_y=2.0)
    s.write()

    s = Scene("Machine", "Rusty machinery block top: gears and a smoking vent.")
    s.cylinder("Gear", 0.3, 0.08, (-0.15, 0.04, 0.1), "rust", segments=8)
    s.box("Vent", (0.22, 0.4, 0.22), (0.22, 0.2, -0.15), "metal")
    s.write()

    # Billboards are stretched 1/cos(camera pitch) like the units, so pixels stay square.
    for name, texture, height in (("TreeOak", "tree_oak", 62), ("TreeOakSmall", "tree_oak_small", 56),
                                  ("TreeAutumn", "tree_autumn", 62), ("TreePine", "tree_pine", 70)):
        s = Scene(name, "Pixel-art tree billboard (HD-2D foliage).")
        s.sprite("Sprite", f"res://assets/sprites/scenery/{texture}.png", (0, height * 0.018 * 1.35, 0))
        s.nodes[-1] = s.nodes[-1].replace("Transform3D(1, 0, 0, 0, 1, 0", "Transform3D(1, 0, 0, 0, 1.35, 0")
        s.write()

    for name, texture in (("BannerRed", "banner_red"), ("BannerBlue", "banner_blue")):
        s = Scene(name, "Banner hanging on a wall face.")
        tex = s.res("Texture2D", f"res://assets/sprites/scenery/{texture}.png")
        s.nodes.append(f'[node name="Cloth" type="Sprite3D" parent="."]\n'
                       f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.55, 0.02)\n'
                       f'pixel_size = 0.036\nalpha_cut = 1\ntexture_filter = 0\ntexture = ExtResource("{tex}")')
        s.write()


if __name__ == "__main__":
    build()
    print("ok", sorted(p.name for p in OUT.glob("*.tscn")))
