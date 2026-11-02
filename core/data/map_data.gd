class_name MapData
extends Resource
## Authorable battle map.
##
## Each entry of [member terrain_rows] and [member height_rows] is one row of the
## grid (y axis), with one character per cell (x axis). This keeps maps readable
## and diff-friendly in the .tres file, and procedural generators can build one
## with [method create].

const HEIGHT_DIGITS := "0123456789abcdefghijklmnopqrstuvwxyz"

@export var display_name: String = ""
## Legend: every symbol used in [member terrain_rows] must match one terrain.
@export var terrains: Array[TerrainData] = []
## One string per row. Each character is a [member TerrainData.symbol].
@export var terrain_rows: PackedStringArray = []
## One string per row. Each character is a height level: 0-9, then a-z (10-35).
@export var height_rows: PackedStringArray = []

@export_group("Spawns")
@export var player_spawns: Array[Vector2i] = []
@export var enemy_spawns: Array[Vector2i] = []

var _legend: Dictionary[String, TerrainData] = {}


static func create(
		p_terrains: Array[TerrainData],
		p_terrain_rows: PackedStringArray,
		p_height_rows: PackedStringArray) -> MapData:
	var map := MapData.new()
	map.terrains = p_terrains
	map.terrain_rows = p_terrain_rows
	map.height_rows = p_height_rows
	return map


func get_size() -> Vector2i:
	if terrain_rows.is_empty():
		return Vector2i.ZERO
	return Vector2i(terrain_rows[0].length(), terrain_rows.size())


func get_terrain_at(cell: Vector2i) -> TerrainData:
	var symbol := terrain_rows[cell.y][cell.x]
	return _get_legend().get(symbol, null)


func get_height_at(cell: Vector2i) -> int:
	if cell.y >= height_rows.size() or cell.x >= height_rows[cell.y].length():
		return 0
	return maxi(HEIGHT_DIGITS.find(height_rows[cell.y][cell.x]), 0)


## Returns a list of human readable problems. Empty means the map is valid.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var size := get_size()
	if size == Vector2i.ZERO:
		errors.append("Map has no rows.")
		return errors
	if height_rows.size() != size.y:
		errors.append("height_rows has %d rows, expected %d." % [height_rows.size(), size.y])
	for y in size.y:
		if terrain_rows[y].length() != size.x:
			errors.append("terrain_rows[%d] has length %d, expected %d." % [y, terrain_rows[y].length(), size.x])
		if y < height_rows.size() and height_rows[y].length() != size.x:
			errors.append("height_rows[%d] has length %d, expected %d." % [y, height_rows[y].length(), size.x])
		for x in terrain_rows[y].length():
			if not _get_legend().has(terrain_rows[y][x]):
				errors.append("Unknown terrain symbol '%s' at (%d, %d)." % [terrain_rows[y][x], x, y])
	for spawn in player_spawns + enemy_spawns:
		if spawn.x < 0 or spawn.y < 0 or spawn.x >= size.x or spawn.y >= size.y:
			errors.append("Spawn %s is outside the map." % spawn)
	return errors


func _get_legend() -> Dictionary[String, TerrainData]:
	if _legend.size() != terrains.size():
		_legend.clear()
		for terrain in terrains:
			if terrain != null:
				_legend[terrain.symbol] = terrain
	return _legend
