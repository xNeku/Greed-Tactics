extends TestCase
## Speed-based turn order (GDD §3).

var combat: CombatState


func before_each() -> void:
	combat = CombatState.new(TestFixtures.flat_grid(5, 5), TestFixtures.rules(), 1)


func test_fastest_unit_acts_first() -> void:
	combat.add_unit(TestFixtures.unit_data("Slow", 5), UnitState.Team.PLAYER, Vector2i(0, 0))
	var fast := combat.add_unit(TestFixtures.unit_data("Fast", 20), UnitState.Team.ENEMY, Vector2i(4, 4))
	assert_eq(combat.start_next_turn(), fast)


func test_faster_units_act_more_often() -> void:
	var slow := combat.add_unit(TestFixtures.unit_data("Slow", 5), UnitState.Team.PLAYER, Vector2i(0, 0))
	var fast := combat.add_unit(TestFixtures.unit_data("Fast", 10), UnitState.Team.ENEMY, Vector2i(4, 4))
	var counts := {slow: 0, fast: 0}
	for i in 12:
		var unit := combat.start_next_turn()
		counts[unit] += 1
		combat.end_turn(unit.facing)
	assert_eq(counts[fast], 8)
	assert_eq(counts[slow], 4)


func test_preview_matches_real_order_and_does_not_mutate() -> void:
	combat.add_unit(TestFixtures.unit_data("A", 7), UnitState.Team.PLAYER, Vector2i(0, 0))
	combat.add_unit(TestFixtures.unit_data("B", 11), UnitState.Team.PLAYER, Vector2i(1, 0))
	combat.add_unit(TestFixtures.unit_data("C", 9), UnitState.Team.ENEMY, Vector2i(4, 4))
	var first := combat.start_next_turn()
	var preview := combat.get_turn_preview(6)
	var ct_before := combat.units.map(func(u: UnitState) -> int: return u.ct)
	preview = combat.get_turn_preview(6)
	assert_eq(combat.units.map(func(u: UnitState) -> int: return u.ct), ct_before, "preview must not change CT")
	assert_eq(preview[0], first, "active unit is listed first")

	var real: Array[UnitState] = [first]
	combat.end_turn(first.facing)
	for i in 5:
		var unit := combat.start_next_turn()
		real.append(unit)
		combat.end_turn(unit.facing)
	assert_eq(preview, real)


func test_dead_units_do_not_get_turns() -> void:
	var dead := combat.add_unit(TestFixtures.unit_data("Dead", 30), UnitState.Team.PLAYER, Vector2i(0, 0))
	var alive := combat.add_unit(TestFixtures.unit_data("Alive", 5), UnitState.Team.ENEMY, Vector2i(4, 4))
	dead.hp = 0
	assert_eq(combat.start_next_turn(), alive)
	assert_not_has(combat.get_turn_preview(4), dead)
