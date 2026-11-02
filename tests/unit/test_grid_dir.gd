extends TestCase


func test_opposite_directions() -> void:
	assert_eq(GridDir.opposite(GridDir.Dir.NORTH), GridDir.Dir.SOUTH)
	assert_eq(GridDir.opposite(GridDir.Dir.EAST), GridDir.Dir.WEST)
	assert_eq(GridDir.opposite(GridDir.Dir.SOUTH), GridDir.Dir.NORTH)
	assert_eq(GridDir.opposite(GridDir.Dir.WEST), GridDir.Dir.EAST)


func test_vectors_are_orthogonal_unit_steps() -> void:
	for dir in GridDir.ALL:
		var v := GridDir.to_vector(dir)
		assert_eq(absi(v.x) + absi(v.y), 1, GridDir.dir_name(dir))


func test_from_delta_uses_dominant_axis() -> void:
	assert_eq(GridDir.from_delta(Vector2i(3, 1)), GridDir.Dir.EAST)
	assert_eq(GridDir.from_delta(Vector2i(-1, 4)), GridDir.Dir.SOUTH)
	assert_eq(GridDir.from_delta(Vector2i(0, -2)), GridDir.Dir.NORTH)
	assert_eq(GridDir.from_delta(Vector2i(-2, 2)), GridDir.Dir.WEST, "ties favour x")
	assert_eq(GridDir.from_delta(Vector2i.ZERO, GridDir.Dir.EAST), GridDir.Dir.EAST, "zero uses fallback")


func test_yaw_points_node_forward_to_direction() -> void:
	for dir in GridDir.ALL:
		var forward := Basis(Vector3.UP, GridDir.to_yaw(dir)) * Vector3.FORWARD
		assert_true(forward.is_equal_approx(GridDir.to_world(dir)), GridDir.dir_name(dir))
