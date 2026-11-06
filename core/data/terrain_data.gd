class_name TerrainData
extends Resource
## Definition of a terrain type (grass, stone, water...).
## Referenced by MapData through its single-character [member symbol].

@export var id: StringName = &""
@export var display_name: String = ""
## Single character used in MapData.terrain_rows to place this terrain.
@export var symbol: String = "g"

@export_group("Rules")
@export var walkable: bool = true
## Base PM cost to enter a cell of this terrain (before height costs).
@export_range(1, 9) var move_cost: int = 1
## Levels above the cell top that block line of sight (trees, pillars...).
## Walls block with their own height already.
@export_range(0, 12) var sight_block: int = 0
## Liquids are rendered with the water material and sit slightly lower.
@export var is_liquid: bool = false

## Procedural look of the top/sides in the terrain shader.
enum Surface { PLAIN, GRASS, ROCK, SAND, DIRT, CAVE }

@export_group("Visual")
@export var surface: Surface = Surface.PLAIN
## Pixel-art textures (32 px per cell, tileable). Without them the cell is
## drawn in flat top_color / side_color.
@export var top_texture: Texture2D
@export var side_texture: Texture2D
## Pixels of the top texture hanging over the sides (grass over dirt).
@export_range(0, 16) var side_lip: int = 0
## Multiplies both textures (recolour a material per zone).
@export var texture_tint: Color = Color.WHITE
## Walls: dissolve above a low rim when they hide floor from the camera.
@export var cutaway: bool = false
## Drawn as two steps rising towards its highest neighbour (stairs, ramps).
@export var stairs: bool = false
@export var top_color: Color = Color(0.37, 0.8, 0.56)
@export var side_color: Color = Color(0.22, 0.55, 0.38)
## Optional decoration placed on top of the cell (tree, cactus, stalagmite...).
@export var prop_scene: PackedScene
## Alternatives to [member prop_scene], picked per cell (stable).
@export var prop_variants: Array[PackedScene] = []
## Props turn freely (trees, rocks); off = only quarter turns (pillars, crates).
@export var prop_free_rotation: bool = true
@export_range(0.3, 3.0) var prop_min_scale: float = 0.85
@export_range(0.3, 3.0) var prop_max_scale: float = 1.15
## Small walk-through decorations (grass tufts, pebbles, mushrooms...).
@export var decor_scenes: Array[PackedScene] = []
## Chance (0-1) that a cell of this terrain gets one decoration.
@export_range(0.0, 1.0) var decor_density: float = 0.0
## Hung on the faces of this terrain's columns that overlook lower walkable
## ground (torches, banners, pipes), facing out.
@export var wall_decor_scenes: Array[PackedScene] = []
## Chance (0-1) per exposed face.
@export_range(0.0, 1.0) var wall_decor_density: float = 0.0
## A face needs at least this drop (levels) to get a wall decoration.
@export_range(1, 10) var wall_decor_min_drop: int = 3
