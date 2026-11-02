class_name BattleGrid
extends RefCounted
## Read-only runtime view of a MapData: bounds, heights and terrain per cell.
## Units are NOT stored here; occupancy belongs to CombatState.

var size: Vector2i:
	get:
		return _size

var _size: Vector2i
var _heights: PackedInt32Array = []
var _terrains: Array[TerrainData] = []


func _init(map: MapData) -> void:
	_size = map.get_size()
	for y in _size.y:
		for x in _size.x:
			var cell := Vector2i(x, y)
			_heights.append(map.get_height_at(cell))
			_terrains.append(map.get_terrain_at(cell))


static func manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _size.x and cell.y < _size.y


func get_height(cell: Vector2i) -> int:
	return _heights[_index(cell)] if is_inside(cell) else 0


func get_terrain(cell: Vector2i) -> TerrainData:
	return _terrains[_index(cell)] if is_inside(cell) else null


func is_walkable(cell: Vector2i) -> bool:
	if not is_inside(cell):
		return false
	var terrain := get_terrain(cell)
	return terrain != null and terrain.walkable


func get_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in _size.y:
		for x in _size.x:
			cells.append(Vector2i(x, y))
	return cells


func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in GridDir.ALL:
		var next := cell + GridDir.to_vector(dir)
		if is_inside(next):
			result.append(next)
	return result


func _index(cell: Vector2i) -> int:
	return cell.y * _size.x + cell.x
