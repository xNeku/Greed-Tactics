class_name AreaShape
extends RefCounted
## Cell patterns used by skill ranges and areas of effect (GDD §3).
## Results are NOT clipped to the map; callers filter with BattleGrid.is_inside.

enum Shape {
	SINGLE,   ## Only the origin cell.
	DIAMOND,  ## Manhattan distance <= size.
	SQUARE,   ## Chebyshev distance <= size (size 1 = 3x3).
	CROSS,    ## Same row or column, up to size cells away.
	LINE,     ## size cells starting at the origin, going in a direction.
}


static func get_cells(
		shape: Shape,
		origin: Vector2i,
		size: int,
		direction: GridDir.Dir = GridDir.Dir.NORTH) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	match shape:
		Shape.SINGLE:
			cells.append(origin)
		Shape.DIAMOND:
			for dy in range(-size, size + 1):
				var span := size - absi(dy)
				for dx in range(-span, span + 1):
					cells.append(origin + Vector2i(dx, dy))
		Shape.SQUARE:
			for dy in range(-size, size + 1):
				for dx in range(-size, size + 1):
					cells.append(origin + Vector2i(dx, dy))
		Shape.CROSS:
			cells.append(origin)
			for dir in GridDir.ALL:
				for i in range(1, size + 1):
					cells.append(origin + GridDir.to_vector(dir) * i)
		Shape.LINE:
			var step := GridDir.to_vector(direction)
			for i in range(0, maxi(size, 1)):
				cells.append(origin + step * i)
	return cells


## Cells whose manhattan distance to [param origin] is within [min_range, max_range].
static func get_ring(origin: Vector2i, min_range: int, max_range: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in get_cells(Shape.DIAMOND, origin, max_range):
		if BattleGrid.manhattan(origin, cell) >= min_range:
			cells.append(cell)
	return cells
