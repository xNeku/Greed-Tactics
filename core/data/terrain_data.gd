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
## Liquids are rendered with the water material and sit slightly lower.
@export var is_liquid: bool = false

## Procedural look of the top/sides in the terrain shader.
enum Surface { PLAIN, GRASS, ROCK, SAND, DIRT, CAVE }

@export_group("Visual")
@export var surface: Surface = Surface.PLAIN
@export var top_color: Color = Color(0.37, 0.8, 0.56)
@export var side_color: Color = Color(0.22, 0.55, 0.38)
## Optional decoration placed on top of the cell (tree, cactus, stalagmite...).
@export var prop_scene: PackedScene
@export_range(0.3, 3.0) var prop_min_scale: float = 0.85
@export_range(0.3, 3.0) var prop_max_scale: float = 1.15
## Small walk-through decorations (grass tufts, pebbles, mushrooms...).
@export var decor_scenes: Array[PackedScene] = []
## Chance (0-1) that a cell of this terrain gets one decoration.
@export_range(0.0, 1.0) var decor_density: float = 0.0
