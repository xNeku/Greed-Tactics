class_name LineOfSight
extends RefCounted
## Line of sight over the grid (GDD §3, v0.9). Heights are in levels. The
## line goes from the shooter's eye to the aimed point on the target; every
## cell it crosses (not the two ends) blocks it if its top, plus its
## TerrainData.sight_block (trees, pillars), rises above the line there.

## Samples per cell of distance along the line.
const SAMPLES_PER_CELL := 6


## How many levels the worst obstacle rises above the straight line between
## [param from] and [param to] (<= 0 means the line is clear).
static func get_clearance(grid: BattleGrid, from: Vector2i, to: Vector2i, eye_height: float, target_height: float) -> float:
	var start := Vector3(from.x, grid.get_height(from) + eye_height, from.y)
	var end := Vector3(to.x, grid.get_height(to) + target_height, to.y)
	var steps := maxi(2, ceili(Vector2(to - from).length() * SAMPLES_PER_CELL))
	var worst := -INF
	for i in range(1, steps):
		var point := start.lerp(end, float(i) / steps)
		var cell := Vector2i(roundi(point.x), roundi(point.z))
		if cell == from or cell == to or not grid.is_inside(cell):
			continue
		worst = maxf(worst, get_block_top(grid, cell) - point.y)
	return worst if worst > -INF else -1.0


static func is_clear(grid: BattleGrid, from: Vector2i, to: Vector2i, eye_height: float, target_height: float) -> bool:
	return get_clearance(grid, from, to, eye_height, target_height) <= 0.0


## Top of whatever stands on [param cell], in levels.
static func get_block_top(grid: BattleGrid, cell: Vector2i) -> float:
	var terrain := grid.get_terrain(cell)
	return grid.get_height(cell) + (terrain.sight_block if terrain != null else 0)
