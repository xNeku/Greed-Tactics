extends TestCase
## What the arrows show before confirming: partial moves, cut pushes, bounces.

var combat: CombatState
var hero: UnitState


func before_each() -> void:
	combat = CombatState.new(TestFixtures.flat_grid(12, 3), TestFixtures.rules(), 2)
	hero = combat.add_unit(TestFixtures.unit_data("Hero", 20), UnitState.Team.PLAYER, Vector2i(0, 1))
	combat.start_next_turn()


func test_move_preview_inside_range_is_complete() -> void:
	var preview := combat.get_move_preview(hero, Vector2i(3, 1))
	assert_eq(preview.destination, Vector2i(3, 1))
	assert_false(preview.partial)


func test_move_preview_out_of_range_stops_halfway() -> void:
	var preview := combat.get_move_preview(hero, Vector2i(10, 1))
	assert_true(preview.partial)
	assert_eq(preview.destination, Vector2i(hero.pm, 1), "as far as the PM allow, on the way")
	assert_eq(preview.path.size(), hero.pm)


func test_move_preview_unreachable_is_empty() -> void:
	var grid := TestFixtures.grid(["gg#g"])
	var c := CombatState.new(grid, TestFixtures.rules(), 1)
	var u := c.add_unit(TestFixtures.unit_data(), UnitState.Team.PLAYER, Vector2i(0, 0))
	c.start_next_turn()
	assert_eq(c.get_move_preview(u, Vector2i(3, 0)), {})


func test_push_is_cut_by_an_obstacle() -> void:
	var foe := combat.add_unit(TestFixtures.unit_data("Foe", 1), UnitState.Team.ENEMY, Vector2i(1, 1))
	combat.add_unit(TestFixtures.unit_data("Wall", 1), UnitState.Team.ENEMY, Vector2i(3, 1))
	var push := combat.predict_push(foe, GridDir.Dir.EAST, 3)
	assert_eq(push.to, Vector2i(2, 1))
	assert_eq(push.blocked_at, Vector2i(3, 1))
	var free := combat.predict_push(foe, GridDir.Dir.NORTH, 1)
	assert_eq(free.to, Vector2i(1, 0))
	assert_eq(free.blocked_at, CombatState.NO_CELL)


func test_preview_reports_the_cut_push() -> void:
	var skill := hero.data.skills[0]
	skill.knockback = 3
	var foe := combat.add_unit(TestFixtures.unit_data("Foe", 1), UnitState.Team.ENEMY, Vector2i(1, 1))
	combat.add_unit(TestFixtures.unit_data("Wall", 1), UnitState.Team.ENEMY, Vector2i(3, 1))
	var preview := combat.preview_skill(hero, skill, hero.cell, foe.cell)[0]
	assert_eq(preview.push_to, Vector2i(2, 1))
	assert_eq(preview.push_blocked_at, Vector2i(3, 1))


func test_bounce_prediction_follows_nearest_enemies() -> void:
	var a := combat.add_unit(TestFixtures.unit_data("A", 1), UnitState.Team.ENEMY, Vector2i(2, 1))
	var b := combat.add_unit(TestFixtures.unit_data("B", 1), UnitState.Team.ENEMY, Vector2i(4, 1))
	var c := combat.add_unit(TestFixtures.unit_data("C", 1), UnitState.Team.ENEMY, Vector2i(6, 1))
	hero.modifiers = [TestFixtures.modifier(ModifierData.Effect.BOUNCE, 1, &"", 2)]
	var effective := hero.get_effective(hero.data.skills[0])
	assert_eq(combat.predict_bounces(hero, effective, a), [b, c] as Array[UnitState])
