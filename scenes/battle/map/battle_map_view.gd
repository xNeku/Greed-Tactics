class_name BattleMapView
extends Node3D
## Renders a BattleGrid as 3D columns (one MultiMesh instance per cell) and
## converts between grid cells and world space. Picking is analytic (ray vs.
## column AABB), so no physics bodies are needed.

const INVALID_CELL := Vector2i(-1, -1)
const TILE_SIZE := 1.0
## World height of one level of elevation.
const LEVEL_HEIGHT := 0.5
## Thickness of the ground slab below level 0.
const BASE_DEPTH := 0.6
## Liquids sit this much lower than solid ground of the same level.
const LIQUID_DROP := 0.15

@onready var _solid: MultiMeshInstance3D = $SolidTerrain
@onready var _liquid: MultiMeshInstance3D = $LiquidTerrain

var _grid: BattleGrid


func build(grid: BattleGrid) -> void:
	_grid = grid
	var solid_cells: Array[Vector2i] = []
	var liquid_cells: Array[Vector2i] = []
	for cell in grid.get_cells():
		var terrain := grid.get_terrain(cell)
		if terrain != null and terrain.is_liquid:
			liquid_cells.append(cell)
		else:
			solid_cells.append(cell)
	_fill(_solid.multimesh, solid_cells)
	_fill(_liquid.multimesh, liquid_cells)


func get_grid() -> BattleGrid:
	return _grid


## World position of the walkable surface at the center of [param cell].
func cell_to_world(cell: Vector2i) -> Vector3:
	return to_global(Vector3(cell.x * TILE_SIZE, get_surface_height(cell), cell.y * TILE_SIZE))


func get_surface_height(cell: Vector2i) -> float:
	var height := _grid.get_height(cell) * LEVEL_HEIGHT
	var terrain := _grid.get_terrain(cell)
	if terrain != null and terrain.is_liquid:
		height -= LIQUID_DROP
	return height


func get_center() -> Vector3:
	var size := Vector2(_grid.size - Vector2i.ONE) * TILE_SIZE
	return to_global(Vector3(size.x * 0.5, 0.0, size.y * 0.5))


func get_bounds() -> AABB:
	var size := Vector3(_grid.size.x, 0.0, _grid.size.y) * TILE_SIZE
	return AABB(to_global(Vector3(-0.5, 0.0, -0.5) * TILE_SIZE), size)


## Closest cell hit by a world-space ray, or INVALID_CELL.
func pick_cell(ray_origin: Vector3, ray_direction: Vector3) -> Vector2i:
	if _grid == null:
		return INVALID_CELL
	var local_origin := to_local(ray_origin)
	var local_direction := global_basis.inverse() * ray_direction
	var best_cell := INVALID_CELL
	var best_distance := INF
	for cell in _grid.get_cells():
		var hit: Variant = _get_column_aabb(cell).intersects_ray(local_origin, local_direction)
		if hit == null:
			continue
		var distance := local_origin.distance_squared_to(hit)
		if distance < best_distance:
			best_distance = distance
			best_cell = cell
	return best_cell


func _get_column_aabb(cell: Vector2i) -> AABB:
	var top := get_surface_height(cell)
	var half := TILE_SIZE * 0.5
	return AABB(
		Vector3(cell.x * TILE_SIZE - half, -BASE_DEPTH, cell.y * TILE_SIZE - half),
		Vector3(TILE_SIZE, top + BASE_DEPTH, TILE_SIZE))


func _fill(multimesh: MultiMesh, cells: Array[Vector2i]) -> void:
	multimesh.instance_count = cells.size()
	for i in cells.size():
		var cell := cells[i]
		var aabb := _get_column_aabb(cell)
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(aabb.size), aabb.get_center()))
		# Per-instance data reaches the shader raw, so convert sRGB colours here.
		var terrain := _grid.get_terrain(cell)
		if multimesh.use_colors:
			multimesh.set_instance_color(i, terrain.side_color.srgb_to_linear())
		if multimesh.use_custom_data:
			multimesh.set_instance_custom_data(i, terrain.top_color.srgb_to_linear())
