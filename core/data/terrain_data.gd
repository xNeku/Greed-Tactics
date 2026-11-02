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

@export_group("Visual")
@export var top_color: Color = Color(0.37, 0.8, 0.56)
@export var side_color: Color = Color(0.22, 0.55, 0.38)
