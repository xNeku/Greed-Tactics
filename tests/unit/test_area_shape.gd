extends TestCase
## Skill shapes (GDD §3): single, line, cross, diamond, 3x3 square.

const O := Vector2i(5, 5)


func test_single() -> void:
	assert_eq(AreaShape.get_cells(AreaShape.Shape.SINGLE, O, 3), [O] as Array[Vector2i])


func test_diamond_sizes() -> void:
	assert_eq(AreaShape.get_cells(AreaShape.Shape.DIAMOND, O, 0).size(), 1)
	assert_eq(AreaShape.get_cells(AreaShape.Shape.DIAMOND, O, 1).size(), 5)
	assert_eq(AreaShape.get_cells(AreaShape.Shape.DIAMOND, O, 2).size(), 13)


func test_square_size_one_is_3x3() -> void:
	var cells := AreaShape.get_cells(AreaShape.Shape.SQUARE, O, 1)
	assert_eq(cells.size(), 9)
	assert_has(cells, O + Vector2i(1, 1))


func test_cross() -> void:
	var cells := AreaShape.get_cells(AreaShape.Shape.CROSS, O, 2)
	assert_eq(cells.size(), 9)
	assert_has(cells, O + Vector2i(0, -2))
	assert_not_has(cells, O + Vector2i(1, 1))


func test_line_follows_direction() -> void:
	var cells := AreaShape.get_cells(AreaShape.Shape.LINE, O, 3, GridDir.Dir.EAST)
	assert_eq(cells, [O, O + Vector2i(1, 0), O + Vector2i(2, 0)] as Array[Vector2i])


func test_ring_excludes_inner_cells() -> void:
	var cells := AreaShape.get_ring(O, 2, 3)
	assert_not_has(cells, O)
	assert_not_has(cells, O + Vector2i(1, 0))
	assert_has(cells, O + Vector2i(2, 0))
	assert_has(cells, O + Vector2i(2, 1))
	assert_eq(cells.size(), 25 - 5)
