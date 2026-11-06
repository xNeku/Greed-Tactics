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
## Pixels per side of every terrain texture layer (32 px per world unit).
const LAYER_SIZE := 32
## Walls (TerrainData.cutaway) dissolve above this height when they hide floor.
const CUT_HEIGHT := 0.75

@onready var _solid: MultiMeshInstance3D = $SolidTerrain
@onready var _liquid: MultiMeshInstance3D = $LiquidTerrain
@onready var _props: Node3D = $Props

var _grid: BattleGrid
## Wall decorations (torches, banners) and their cell top: hidden with the
## wall when the cutaway removes it.
var _wall_decor: Array[Node3D] = []


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
	_fill_solid(solid_cells)
	_fill(_liquid.multimesh, liquid_cells)
	_place_props()


## Wall decorations follow the wall cutaway of the terrain shader: hidden
## when their wall stands in front of floor of the map.
func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or _grid == null or _wall_decor.is_empty():
		return
	for decor in _wall_decor:
		decor.visible = not _hides_floor(camera.global_position, decor.global_position)


func _hides_floor(eye: Vector3, point: Vector3) -> bool:
	var view := (point - eye).normalized()
	if point.y <= CUT_HEIGHT:
		return false
	var t := (0.0 - point.y) / minf(view.y, -0.01)
	var ground := to_local(point + view * t)
	var inner := Rect2(Vector2(0.5, 0.5), Vector2(_grid.size) - Vector2(2.0, 2.0))
	return inner.has_point(Vector2(ground.x, ground.z))


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
			var top := terrain.top_color.srgb_to_linear()
			top.a = terrain.surface / 10.0
			multimesh.set_instance_custom_data(i, top)


## Solid columns with their pixel textures. Stair cells become two half-cell
## steps rising towards their highest neighbour, so a line of stair cells
## (one level apart) reads as one continuous staircase.
func _fill_solid(cells: Array[Vector2i]) -> void:
	var layers := _build_texture_layers(cells)
	var material := (_solid.multimesh.mesh as BoxMesh).material as ShaderMaterial
	material.set_shader_parameter(&"layers", layers.array)
	# Cutaway: the inner map rect (border walls excluded) in world space.
	var inner_min := to_global(Vector3(0.5, 0.0, 0.5))
	var inner_max := to_global(Vector3(_grid.size.x - 1.5, 0.0, _grid.size.y - 1.5))
	material.set_shader_parameter(&"map_min", Vector2(inner_min.x, inner_min.z))
	material.set_shader_parameter(&"map_max", Vector2(inner_max.x, inner_max.z))
	material.set_shader_parameter(&"floor_y", global_position.y)
	material.set_shader_parameter(&"cut_height", CUT_HEIGHT)
	var boxes: Array[AABB] = []
	var owners: Array[TerrainData] = []
	for cell in cells:
		var terrain := _grid.get_terrain(cell)
		for box in _column_boxes(cell, terrain):
			boxes.append(box)
			owners.append(terrain)
	var multimesh := _solid.multimesh
	multimesh.instance_count = boxes.size()
	for i in boxes.size():
		var box := boxes[i]
		var terrain := owners[i]
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(box.size), box.get_center()))
		multimesh.set_instance_color(i, terrain.texture_tint.srgb_to_linear() if terrain.top_texture != null else Color.WHITE)
		var index: Vector2i = layers.index[terrain]
		multimesh.set_instance_custom_data(i, Color(index.x / 255.0, index.y / 255.0, terrain.side_lip / 32.0,
			1.0 if terrain.cutaway else 0.0))


## Boxes that draw [param cell]: its column, or two steps for stairs.
func _column_boxes(cell: Vector2i, terrain: TerrainData) -> Array[AABB]:
	var column := _get_column_aabb(cell)
	if terrain == null or not terrain.stairs:
		return [column]
	var high_dir := Vector2i.ZERO
	var best := _grid.get_height(cell)
	for dir in GridDir.ALL:
		var next := cell + GridDir.to_vector(dir)
		if _grid.is_walkable(next) and _grid.get_height(next) > best:
			best = _grid.get_height(next)
			high_dir = GridDir.to_vector(dir)
	if high_dir == Vector2i.ZERO:
		return [column]
	# Low half (away from the climb) one half-level lower, high half at the top.
	var half := TILE_SIZE * 0.5
	var step := LEVEL_HEIGHT * 0.5
	var low := column
	var high := column
	if high_dir.x != 0:
		low.size.x = half
		high.size.x = half
		if high_dir.x > 0:
			high.position.x += half
		else:
			low.position.x += half
	else:
		low.size.z = half
		high.size.z = half
		if high_dir.y > 0:
			high.position.z += half
		else:
			low.position.z += half
	low.size.y -= step
	return [low, high]


## Every top/side texture used by [param cells] in one Texture2DArray.
## Terrains without textures get flat swatches of their colours.
func _build_texture_layers(cells: Array[Vector2i]) -> Dictionary:
	var images: Array[Image] = []
	var by_texture: Dictionary = {}
	var index: Dictionary = {}
	for cell in cells:
		var terrain := _grid.get_terrain(cell)
		if index.has(terrain):
			continue
		var top := _layer_of(terrain.top_texture, terrain.top_color, images, by_texture)
		var side := _layer_of(terrain.side_texture if terrain.side_texture != null else terrain.top_texture,
			terrain.side_color, images, by_texture)
		index[terrain] = Vector2i(top, side)
	if images.is_empty():
		images.append(_swatch(Color.MAGENTA))
	var array := Texture2DArray.new()
	array.create_from_images(images)
	return {"array": array, "index": index}


func _layer_of(texture: Texture2D, fallback: Color, images: Array[Image], by_texture: Dictionary) -> int:
	var key: Variant = texture if texture != null else fallback
	if by_texture.has(key):
		return by_texture[key]
	var image := _swatch(fallback) if texture == null else texture.get_image().duplicate()
	if image.is_compressed():
		image.decompress()
	image.clear_mipmaps()
	image.convert(Image.FORMAT_RGBA8)
	if image.get_size() != Vector2i(LAYER_SIZE, LAYER_SIZE):
		image.resize(LAYER_SIZE, LAYER_SIZE, Image.INTERPOLATE_NEAREST)
	by_texture[key] = images.size()
	images.append(image)
	return images.size() - 1


func _swatch(color: Color) -> Image:
	var image := Image.create_empty(LAYER_SIZE, LAYER_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image


## Instances TerrainData.prop_scene on every cell that has one, with a
## rotation and scale derived from the cell so the result is stable.
func _place_props() -> void:
	for child in _props.get_children():
		child.queue_free()
	for cell in _grid.get_cells():
		var terrain := _grid.get_terrain(cell)
		if terrain == null or (terrain.prop_scene == null and terrain.prop_variants.is_empty()):
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(cell)
		var scene := terrain.prop_scene
		if not terrain.prop_variants.is_empty():
			scene = terrain.prop_variants[rng.randi_range(0, terrain.prop_variants.size() - 1)]
		var prop: Node3D = scene.instantiate()
		_props.add_child(prop)
		prop.position = Vector3(cell.x * TILE_SIZE, get_surface_height(cell), cell.y * TILE_SIZE)
		prop.rotation.y = rng.randf() * TAU if terrain.prop_free_rotation else rng.randi_range(0, 3) * PI * 0.5
		prop.scale = Vector3.ONE * rng.randf_range(terrain.prop_min_scale, terrain.prop_max_scale)
	_place_decor()
	_place_wall_decor()


## Torches, banners and pipes on the faces of tall columns that overlook
## lower walkable ground, facing out and a little below the top.
func _place_wall_decor() -> void:
	for cell in _grid.get_cells():
		var terrain := _grid.get_terrain(cell)
		if terrain == null or terrain.wall_decor_scenes.is_empty():
			continue
		for dir in GridDir.ALL:
			var offset := GridDir.to_vector(dir)
			var next := cell + offset
			if not _grid.is_walkable(next):
				continue
			var drop := _grid.get_height(cell) - _grid.get_height(next)
			if drop < terrain.wall_decor_min_drop:
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(cell) ^ (dir * 7919 + 13)
			if rng.randf() >= terrain.wall_decor_density:
				continue
			var decor: Node3D = terrain.wall_decor_scenes[rng.randi_range(0, terrain.wall_decor_scenes.size() - 1)].instantiate()
			_props.add_child(decor)
			var face := Vector3(offset.x, 0.0, offset.y) * TILE_SIZE * 0.5
			decor.position = Vector3(cell.x * TILE_SIZE, get_surface_height(cell) - 0.55, cell.y * TILE_SIZE) + face
			# The decoration's +Z looks out of the wall.
			decor.rotation.y = atan2(offset.x, offset.y)
			_wall_decor.append(decor)


## Small decorations on walkable cells (they never block anything).
func _place_decor() -> void:
	for cell in _grid.get_cells():
		var terrain := _grid.get_terrain(cell)
		if terrain == null or terrain.decor_scenes.is_empty() or terrain.prop_scene != null:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(cell) ^ 0x5bd1e995
		if rng.randf() >= terrain.decor_density:
			continue
		var decor: Node3D = terrain.decor_scenes[rng.randi_range(0, terrain.decor_scenes.size() - 1)].instantiate()
		_props.add_child(decor)
		var jitter := Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3)) * TILE_SIZE
		decor.position = Vector3(cell.x * TILE_SIZE + jitter.x, get_surface_height(cell), cell.y * TILE_SIZE + jitter.y)
		decor.rotation.y = rng.randf() * TAU
		decor.scale = Vector3.ONE * rng.randf_range(0.8, 1.2)
