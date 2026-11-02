extends TestCase
## Movement rules (GDD §3): orthogonal only, 1 PM per cell, +1 PM per level
## climbed, no steps higher than max_climb, enemies block, allies can be crossed.

var rules: RulesConfig


func before_each() -> void:
	rules = TestFixtures.rules()


func test_open_field_reach_is_a_diamond() -> void:
	var grid := TestFixtures.flat_grid(9, 9)
	var reach := Pathfinder.find_reachable(grid, rules, Vector2i(4, 4), 2)
	# Diamond of radius 2 = 13 cells, minus the origin.
	assert_eq(reach.get_destinations().size(), 12)
	assert_true(reach.can_stop_at(Vector2i(6, 4)))
	assert_true(reach.can_stop_at(Vector2i(5, 5)))
	assert_false(reach.can_stop_at(Vector2i(6, 5)), "3 steps away")
	assert_false(reach.can_stop_at(Vector2i(4, 4)), "origin is not a destination")


func test_paths_are_orthogonal() -> void:
	var grid := TestFixtures.flat_grid(6, 6)
	var reach := Pathfinder.find_reachable(grid, rules, Vector2i(0, 0), 6)
	var path := reach.get_path_to(Vector2i(3, 3))
	assert_eq(path.size(), 6)
	var previous := Vector2i(0, 0)
	for cell in path:
		assert_eq(BattleGrid.manhattan(previous, cell), 1, "step %s -> %s" % [previous, cell])
		previous = cell
	assert_eq(path[-1], Vector2i(3, 3))


func test_climbing_costs_extra_pm() -> void:
	var grid := TestFixtures.grid(["ggg"], ["011"])
	var reach := Pathfinder.find_reachable(grid, rules, Vector2i(0, 0), 3)
	assert_eq(reach.get_cost(Vector2i(1, 0)), 2, "1 base + 1 climb")
	assert_eq(reach.get_cost(Vector2i(2, 0)), 3)


func test_dropping_is_free_by_default() -> void:
	var grid := TestFixtures.grid(["gg"], ["10"])
	var reach := Pathfinder.find_reachable(grid, rules, Vector2i(0, 0), 1)
	assert_eq(reach.get_cost(Vector2i(1, 0)), 1)


func test_cannot_step_more_than_max_climb() -> void:
	var grid := TestFixtures.grid(["gg", "gg"], ["02", "00"])
	var reach := Pathfinder.find_reachable(grid, rules, Vector2i(0, 0), 10)
	assert_false(reach.can_stop_at(Vector2i(1, 0)), "height 2 wall from 0")
	# Also unreachable going around, every neighbour is at height 0.
	assert_eq(GridRules.get_step_cost(grid, rules, Vector2i(1, 1), Vector2i(1, 0)), -1)
	assert_eq(GridRules.get_step_cost(grid, rules, Vector2i(1, 0), Vector2i(1, 1)), -1, "dropping 2 is also too much")


func test_unwalkable_terrain_blocks() -> void:
	var grid := TestFixtures.grid(["g#g"])
	var reach := Pathfinder.find_reachable(grid, rules, Vector2i(0, 0), 10)
	assert_false(reach.can_stop_at(Vector2i(1, 0)))
	assert_false(reach.can_stop_at(Vector2i(2, 0)))


func test_terrain_move_cost_applies() -> void:
	var grid := TestFixtures.grid(["gwg"])
	var reach := Pathfinder.find_reachable(grid, rules, Vector2i(0, 0), 3)
	assert_eq(reach.get_cost(Vector2i(1, 0)), 2, "water costs 2")
	assert_eq(reach.get_cost(Vector2i(2, 0)), 3)


func test_enemies_block_and_allies_are_crossable() -> void:
	var grid := TestFixtures.grid(["ggg"])
	var blocked: Dictionary[Vector2i, bool] = {Vector2i(1, 0): true}
	var reach := Pathfinder.find_reachable(grid, rules, Vector2i(0, 0), 5, blocked, blocked)
	assert_false(reach.can_stop_at(Vector2i(2, 0)), "enemy in the corridor")

	var occupied: Dictionary[Vector2i, bool] = {Vector2i(1, 0): true}
	reach = Pathfinder.find_reachable(grid, rules, Vector2i(0, 0), 5, {}, occupied)
	assert_false(reach.can_stop_at(Vector2i(1, 0)), "cannot stop on an ally")
	assert_true(reach.can_stop_at(Vector2i(2, 0)), "can walk through an ally")


func test_combat_move_spends_pm_and_faces_last_step() -> void:
	var combat := CombatState.new(TestFixtures.flat_grid(5, 5), rules, 1)
	var unit := combat.add_unit(TestFixtures.unit_data(), UnitState.Team.PLAYER, Vector2i(0, 0))
	combat.start_next_turn()
	var path := combat.move_active_unit(Vector2i(2, 1))
	assert_eq(path.size(), 3)
	assert_eq(unit.cell, Vector2i(2, 1))
	assert_eq(unit.pm, unit.data.move_points - 3)
	assert_eq(unit.facing, GridDir.from_delta(path[-1] - path[-2]))


func test_combat_rejects_moves_beyond_pm() -> void:
	var combat := CombatState.new(TestFixtures.flat_grid(9, 1), rules, 1)
	var unit := combat.add_unit(TestFixtures.unit_data(), UnitState.Team.PLAYER, Vector2i(0, 0))
	combat.start_next_turn()
	var path := combat.move_active_unit(Vector2i(unit.data.move_points + 1, 0))
	assert_true(path.is_empty())
	assert_eq(unit.cell, Vector2i(0, 0))
	assert_eq(unit.pm, unit.data.move_points)
