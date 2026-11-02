class_name MapGenerator
extends RefCounted
## Procedural battle maps per theme (GDD §9). Deterministic for a given seed.
##
## Pipeline:
##   1. Pick a size within the zone range (always wider than tall).
##   2. Shape the terrain with the zone layout (forest / desert / cave).
##   3. Place spawns: players on the west band, enemies on the east band.
##   4. Guarantee that every spawn can walk to every other one with the real
##      movement rules (carving paths and ramps if needed).
##   5. Randomly mirror the map so players do not always start on the left.
##
## Usage: MapGenerator.generate(zone, rules, seed, 4, 5) -> MapData

const MIN_OPEN_RATIO := 0.45
const UNREACHABLE_PENALTY := 12

var _zone: ZoneData
var _rules: RulesConfig
var _rng := RandomNumberGenerator.new()
var _size: Vector2i
var _heights: PackedInt32Array = []
var _terrain: Array[TerrainData] = []


static func generate(zone: ZoneData, rules: RulesConfig, rng_seed: int,
		player_count: int, enemy_count: int) -> MapData:
	var generator := MapGenerator.new()
	return generator._build(zone, rules, rng_seed, player_count, enemy_count)


func _build(zone: ZoneData, rules: RulesConfig, rng_seed: int, player_count: int, enemy_count: int) -> MapData:
	_zone = zone
	_rules = rules
	_rng.seed = rng_seed
	var w := _rng.randi_range(zone.min_size.x, zone.max_size.x)
	var h := _rng.randi_range(zone.min_size.y, mini(zone.max_size.y, w))
	_size = Vector2i(w, h)
	_heights.resize(w * h)
	_heights.fill(0)
	_terrain.resize(w * h)
	_terrain.fill(zone.floor_terrain)

	match zone.layout:
		ZoneData.Layout.FOREST:
			_shape_forest()
		ZoneData.Layout.DESERT:
			_shape_desert()
		ZoneData.Layout.CAVE:
			_shape_cave()

	var players := _place_spawns(player_count, true)
	var enemies := _place_spawns(enemy_count, false)
	_ensure_connectivity(players + enemies)
	if _rng.randf() < 0.5:
		_mirror_x(players, enemies)
	return _to_map_data(players, enemies)


#region Layouts

func _shape_forest() -> void:
	_fill_heights_from_noise(_zone.height_frequency, _zone.max_height, 0.0)
	# A river crossing the short axis splits both camps: crossing it is a decision.
	var river: Array[Vector2i] = []
	if _rng.randf() < 0.35 + _zone.liquid_amount * 5.0:
		river = _carve_river()
	# Peaks become rocky outcrops.
	for cell in _cells():
		if _height(cell) >= _zone.max_height and _rng.randf() < 0.75:
			_set_terrain(cell, _zone.high_terrain)
	_scatter_obstacles(_noise(0.18, _rng.randi()), 0.25, func(c: Vector2i) -> bool:
		return not _is_liquid(c) and not _near_liquid(c, 1))
	# A dirt trail from west to east, crossing the river through a ford.
	var from := Vector2i(0, _rng.randi_range(2, _size.y - 3))
	var to := Vector2i(_size.x - 1, _rng.randi_range(2, _size.y - 3))
	for cell in _cheapest_path(from, to, false):
		if _terrain_at(cell) == _zone.high_terrain:
			continue
		_set_terrain(cell, _zone.alt_floor_terrain)


func _shape_desert() -> void:
	# Soft dunes.
	_fill_heights_from_noise(_zone.height_frequency, mini(_zone.max_height, 2), 0.0)
	# Mesas: tall flat sandstone plateaus, each with a ramp.
	var mesa_count := _rng.randi_range(2, 4)
	for i in mesa_count:
		_build_mesa()
	# Oasis in a low spot.
	if _rng.randf() < 0.3 + _zone.liquid_amount * 4.0:
		_build_oasis()
	_scatter_obstacles(_noise(0.3, _rng.randi()), 0.15, func(c: Vector2i) -> bool:
		return _terrain_at(c) == _zone.floor_terrain)


func _shape_cave() -> void:
	var walls := _cave_automata()
	_fill_heights_from_noise(_zone.height_frequency, mini(_zone.max_height, 3), 0.0)
	# Walls only a bit above the highest floor, so they frame without hiding.
	var wall_height := mini(_zone.max_height, 3) + 2
	for cell in _cells():
		if walls[_index(cell)]:
			_set_terrain(cell, _zone.wall_terrain)
			_set_height(cell, wall_height + _rng.randi_range(0, 1))
	# Darker patches of floor.
	var patches := _noise(0.15, _rng.randi())
	for cell in _cells():
		if not walls[_index(cell)] and patches.get_noise_2d(cell.x, cell.y) > 0.35:
			_set_terrain(cell, _zone.alt_floor_terrain)
	# Underground pools in the lowest open spots next to walls.
	var pools := 0
	var wanted_pools := roundi(_zone.liquid_amount * 30.0)
	for cell in _shuffled(_cells()):
		if pools >= wanted_pools:
			break
		if walls[_index(cell)] or _height(cell) > 0 or not _near_terrain(cell, _zone.wall_terrain, 1):
			continue
		for pool_cell in AreaShape.get_cells(AreaShape.Shape.DIAMOND, cell, _rng.randi_range(0, 1)):
			if _inside(pool_cell) and not walls[_index(pool_cell)]:
				_set_terrain(pool_cell, _zone.liquid_terrain)
				_set_height(pool_cell, 0)
		pools += 1
	_scatter_obstacles(_noise(0.25, _rng.randi()), 0.2, func(c: Vector2i) -> bool:
		return _is_open_floor(c) and not _near_liquid(c, 0))


## Cellular automata cave: true = wall. Borders are always rock.
func _cave_automata() -> Array[bool]:
	var walls: Array[bool] = []
	for attempt in 6:
		walls = []
		walls.resize(_size.x * _size.y)
		var fill := 0.42 - attempt * 0.03
		for cell in _cells():
			walls[_index(cell)] = _is_border(cell, 1) or _rng.randf() < fill
		for step in 4:
			var next := walls.duplicate()
			for cell in _cells():
				if _is_border(cell, 1):
					continue
				var count := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var n := cell + Vector2i(dx, dy)
						if not _inside(n) or walls[_index(n)]:
							count += 1
				next[_index(cell)] = count >= 5
			walls = next
		# Keep only the biggest open region.
		var region := _largest_region(walls)
		for cell in _cells():
			walls[_index(cell)] = not region.has(cell)
		if region.size() >= _size.x * _size.y * MIN_OPEN_RATIO:
			break
	return walls


func _carve_river() -> Array[Vector2i]:
	var river: Array[Vector2i] = []
	var x := _rng.randi_range(int(_size.x * 0.4), int(_size.x * 0.6))
	for y in _size.y:
		x = clampi(x + _rng.randi_range(-1, 1), 3, _size.x - 4)
		var width := 2 if _rng.randf() < 0.35 else 1
		for dx in width:
			river.append(Vector2i(x + dx, y))
	for cell in river:
		_set_terrain(cell, _zone.liquid_terrain)
		_set_height(cell, 0)
	# Banks slope down towards the water: a valley, not a canyon.
	for distance in range(1, 4):
		for cell in _cells():
			if _is_liquid(cell):
				continue
			if _near_liquid(cell, distance):
				_set_height(cell, mini(_height(cell), distance - 1))
	for cell in _cells():
		if not _is_liquid(cell) and _near_liquid(cell, 1) and _zone.shore_terrain != null:
			_set_terrain(cell, _zone.shore_terrain)
	return river


func _build_mesa() -> void:
	var radius := _rng.randi_range(2, 3)
	var center := Vector2i(
		_rng.randi_range(radius + 3, _size.x - radius - 4),
		_rng.randi_range(radius + 1, _size.y - radius - 2))
	var top := _rng.randi_range(3, _zone.max_height)
	var shape := _noise(0.4, _rng.randi())
	var cells: Array[Vector2i] = []
	for cell in AreaShape.get_cells(AreaShape.Shape.SQUARE, center, radius + 1):
		if not _inside(cell):
			continue
		var d := Vector2(cell - center).length() + shape.get_noise_2d(cell.x, cell.y) * 1.2
		if d <= radius + 0.3:
			cells.append(cell)
	for cell in cells:
		_set_terrain(cell, _zone.high_terrain)
		_set_height(cell, top)
	# Ramp: a 1-wide staircase going down from one edge.
	var dir := GridDir.ALL[_rng.randi_range(0, 3)]
	var step := GridDir.to_vector(dir)
	var cell := center
	while cells.has(cell + step):
		cell += step
	var level := top
	while level > 0:
		cell += step
		if not _inside(cell):
			break
		level -= 1
		if _height(cell) >= level:
			break
		_set_height(cell, level)
		_set_terrain(cell, _zone.high_terrain if level > 1 else _zone.alt_floor_terrain)


func _build_oasis() -> void:
	var best := Vector2i(_size.x >> 1, _size.y >> 1)
	for i in 20:
		var cell := Vector2i(_rng.randi_range(4, _size.x - 5), _rng.randi_range(3, _size.y - 4))
		if _height(cell) < _height(best) and _terrain_at(cell) == _zone.floor_terrain:
			best = cell
	var radius := _rng.randi_range(1, 2)
	for cell in AreaShape.get_cells(AreaShape.Shape.DIAMOND, best, radius + 2):
		if not _inside(cell):
			continue
		var d := BattleGrid.manhattan(cell, best)
		if d <= radius:
			_set_terrain(cell, _zone.liquid_terrain)
			_set_height(cell, 0)
		elif _zone.shore_terrain != null:
			_set_terrain(cell, _zone.shore_terrain)
			_set_height(cell, mini(_height(cell), d - radius))

#endregion


#region Shared helpers

func _fill_heights_from_noise(frequency: float, max_level: int, bias: float) -> void:
	var noise := _noise(frequency, _rng.randi())
	noise.fractal_octaves = 3
	for cell in _cells():
		var n := clampf((noise.get_noise_2d(cell.x, cell.y) + 1.0) * 0.5 + bias, 0.0, 1.0)
		# Ease so most of the map is low and walkable, with some hills.
		_set_height(cell, clampi(floori(pow(n, 1.6) * (max_level + 1)), 0, max_level))


func _scatter_obstacles(noise: FastNoiseLite, cluster_threshold: float, allowed: Callable) -> void:
	if _zone.obstacle_terrains.is_empty():
		return
	for cell in _cells():
		if not allowed.call(cell):
			continue
		var clustered := noise.get_noise_2d(cell.x, cell.y) > cluster_threshold
		var chance := _zone.obstacle_density * (2.2 if clustered else 0.35)
		if _rng.randf() < chance:
			var index := _rng.randi_range(0, _zone.obstacle_terrains.size() - 1)
			_set_terrain(cell, _zone.obstacle_terrains[index])


func _place_spawns(count: int, west: bool) -> Array[Vector2i]:
	var band := maxi(3, int(_size.x * 0.22))
	var x_from := 1 if west else _size.x - 1 - band
	var x_to := band if west else _size.x - 2
	var anchor := Vector2i(floori((x_from + x_to) / 2.0), _rng.randi_range(floori(_size.y / 3.0), floori(_size.y * 2 / 3.0)))
	var candidates: Array[Vector2i] = []
	for y in range(1, _size.y - 1):
		for x in range(x_from, x_to + 1):
			var cell := Vector2i(x, y)
			if _is_open_floor(cell):
				candidates.append(cell)
	if candidates.size() < count:
		# Not enough room: clear the band around the anchor.
		for cell in AreaShape.get_cells(AreaShape.Shape.SQUARE, anchor, 2):
			if _inside(cell) and not _is_border(cell, 1):
				_set_terrain(cell, _zone.floor_terrain)
				candidates.append(cell)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return BattleGrid.manhattan(a, anchor) < BattleGrid.manhattan(b, anchor))
	var spawns: Array[Vector2i] = []
	for cell in candidates:
		if spawns.size() >= count:
			break
		if not spawns.has(cell):
			spawns.append(cell)
	return spawns


## Makes sure every spawn can reach the first one with the real movement
## rules. Carves the cheapest path and smooths its heights when they cannot.
func _ensure_connectivity(spawns: Array[Vector2i]) -> void:
	if spawns.is_empty():
		return
	for attempt in 4:
		var reach := _walk_costs(spawns[0])
		var missing := spawns.filter(func(c: Vector2i) -> bool: return not reach.has(c))
		if missing.is_empty():
			return
		for cell: Vector2i in missing:
			var path := _cheapest_path(spawns[0], cell, true)
			var previous := spawns[0]
			for step in path:
				if not _terrain_at(step).walkable:
					_set_terrain(step, _zone.alt_floor_terrain)
				var h := clampi(_height(step), _height(previous) - _rules.max_climb, _height(previous) + _rules.max_climb)
				_set_height(step, h)
				previous = step


func _walk_costs(start: Vector2i) -> Dictionary[Vector2i, int]:
	var grid := BattleGrid.new(_snapshot())
	return Pathfinder.distance_field(grid, _rules, start)


## Dijkstra where illegal steps are allowed but expensive, so the result is a
## path that needs as little carving as possible. [param through_anything]
## also lets it cross walls.
func _cheapest_path(from: Vector2i, to: Vector2i, through_anything: bool) -> Array[Vector2i]:
	var costs: Dictionary[Vector2i, int] = {from: 0}
	var came: Dictionary[Vector2i, Vector2i] = {}
	var frontier: Array[Vector2i] = [from]
	while not frontier.is_empty():
		var best_i := 0
		for i in frontier.size():
			if costs[frontier[i]] < costs[frontier[best_i]]:
				best_i = i
		var current := frontier[best_i]
		frontier.remove_at(best_i)
		if current == to:
			break
		for dir in GridDir.ALL:
			var next := current + GridDir.to_vector(dir)
			if not _inside(next):
				continue
			var terrain := _terrain_at(next)
			var step := 1 + absi(_height(next) - _height(current))
			if not terrain.walkable:
				if not through_anything and terrain == _zone.wall_terrain:
					continue
				step += UNREACHABLE_PENALTY
			elif absi(_height(next) - _height(current)) > _rules.max_climb:
				step += UNREACHABLE_PENALTY >> 1
			if terrain.is_liquid:
				step += 3
			var cost := costs[current] + step
			if not costs.has(next) or cost < costs[next]:
				costs[next] = cost
				came[next] = current
				if not frontier.has(next):
					frontier.append(next)
	var path: Array[Vector2i] = []
	if not costs.has(to):
		return path
	var cell := to
	while cell != from:
		path.push_front(cell)
		cell = came[cell]
	return path


func _largest_region(walls: Array[bool]) -> Dictionary[Vector2i, bool]:
	var seen: Dictionary[Vector2i, bool] = {}
	var best: Dictionary[Vector2i, bool] = {}
	for cell in _cells():
		if walls[_index(cell)] or seen.has(cell):
			continue
		var region: Dictionary[Vector2i, bool] = {}
		var stack: Array[Vector2i] = [cell]
		seen[cell] = true
		while not stack.is_empty():
			var current: Vector2i = stack.pop_back()
			region[current] = true
			for dir in GridDir.ALL:
				var next := current + GridDir.to_vector(dir)
				if _inside(next) and not walls[_index(next)] and not seen.has(next):
					seen[next] = true
					stack.append(next)
		if region.size() > best.size():
			best = region
	return best


func _mirror_x(players: Array[Vector2i], enemies: Array[Vector2i]) -> void:
	var heights := _heights.duplicate()
	var terrain := _terrain.duplicate()
	for cell in _cells():
		var mirrored := Vector2i(_size.x - 1 - cell.x, cell.y)
		_heights[_index(mirrored)] = heights[_index(cell)]
		_terrain[_index(mirrored)] = terrain[_index(cell)]
	for spawns in [players, enemies]:
		for i in spawns.size():
			spawns[i] = Vector2i(_size.x - 1 - spawns[i].x, spawns[i].y)


func _snapshot() -> MapData:
	var map := MapData.new()
	map.terrains = _zone.get_all_terrains()
	var terrain_rows := PackedStringArray()
	var height_rows := PackedStringArray()
	for y in _size.y:
		var t_row := ""
		var h_row := ""
		for x in _size.x:
			var i := _index(Vector2i(x, y))
			t_row += _terrain[i].symbol
			h_row += MapData.HEIGHT_DIGITS[clampi(_heights[i], 0, MapData.HEIGHT_DIGITS.length() - 1)]
		terrain_rows.append(t_row)
		height_rows.append(h_row)
	map.terrain_rows = terrain_rows
	map.height_rows = height_rows
	return map


func _to_map_data(players: Array[Vector2i], enemies: Array[Vector2i]) -> MapData:
	var map := _snapshot()
	map.display_name = _zone.display_name
	map.player_spawns = players
	map.enemy_spawns = enemies
	return map


func _noise(frequency: float, noise_seed: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	return noise


func _cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in _size.y:
		for x in _size.x:
			cells.append(Vector2i(x, y))
	return cells


func _shuffled(cells: Array[Vector2i]) -> Array[Vector2i]:
	for i in range(cells.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := cells[i]
		cells[i] = cells[j]
		cells[j] = tmp
	return cells


func _index(cell: Vector2i) -> int:
	return cell.y * _size.x + cell.x


func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _size.x and cell.y < _size.y


func _is_border(cell: Vector2i, thickness: int) -> bool:
	return cell.x < thickness or cell.y < thickness \
		or cell.x >= _size.x - thickness or cell.y >= _size.y - thickness


func _height(cell: Vector2i) -> int:
	return _heights[_index(cell)]


func _set_height(cell: Vector2i, value: int) -> void:
	_heights[_index(cell)] = maxi(value, 0)


func _terrain_at(cell: Vector2i) -> TerrainData:
	return _terrain[_index(cell)]


func _set_terrain(cell: Vector2i, terrain: TerrainData) -> void:
	if terrain != null:
		_terrain[_index(cell)] = terrain


func _is_liquid(cell: Vector2i) -> bool:
	return _terrain_at(cell).is_liquid


func _is_open_floor(cell: Vector2i) -> bool:
	var terrain := _terrain_at(cell)
	return terrain.walkable and not terrain.is_liquid


func _near_liquid(cell: Vector2i, distance: int) -> bool:
	for other in AreaShape.get_cells(AreaShape.Shape.DIAMOND, cell, distance):
		if _inside(other) and _is_liquid(other):
			return true
	return false


func _near_terrain(cell: Vector2i, terrain: TerrainData, distance: int) -> bool:
	for other in AreaShape.get_cells(AreaShape.Shape.DIAMOND, cell, distance):
		if other != cell and _inside(other) and _terrain_at(other) == terrain:
			return true
	return false

#endregion
