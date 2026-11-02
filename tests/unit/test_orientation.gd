extends TestCase
## Orientation rules (GDD §5): the back is the cell opposite to where the
## target faces; if that cell is occupied or blocked it does not count as back.

const TARGET := Vector2i(2, 2)

var rules: RulesConfig
var grid: BattleGrid
var no_units: Dictionary[Vector2i, bool] = {}


func before_each() -> void:
	rules = TestFixtures.rules()
	grid = TestFixtures.flat_grid(5, 5)


func _side(attacker: Vector2i, facing: GridDir.Dir, occupied := no_units) -> GridRules.AttackSide:
	return GridRules.get_attack_side(grid, rules, attacker, TARGET, facing, occupied)


func test_attack_from_front() -> void:
	assert_eq(_side(Vector2i(2, 1), GridDir.Dir.NORTH), GridRules.AttackSide.FRONT)


func test_attack_from_behind() -> void:
	assert_eq(_side(Vector2i(2, 3), GridDir.Dir.NORTH), GridRules.AttackSide.BACK)
	assert_eq(_side(Vector2i(1, 2), GridDir.Dir.EAST), GridRules.AttackSide.BACK)


func test_attack_from_sides() -> void:
	assert_eq(_side(Vector2i(1, 2), GridDir.Dir.NORTH), GridRules.AttackSide.SIDE)
	assert_eq(_side(Vector2i(3, 2), GridDir.Dir.NORTH), GridRules.AttackSide.SIDE)


func test_ranged_uses_dominant_axis_and_ties_are_side() -> void:
	assert_eq(_side(Vector2i(3, 4), GridDir.Dir.NORTH), GridRules.AttackSide.BACK, "mostly behind")
	assert_eq(_side(Vector2i(4, 4), GridDir.Dir.NORTH), GridRules.AttackSide.SIDE, "perfect diagonal")
	assert_eq(_side(Vector2i(2, 0), GridDir.Dir.NORTH), GridRules.AttackSide.FRONT)


func test_back_covered_by_unit_is_not_back() -> void:
	var occupied: Dictionary[Vector2i, bool] = {Vector2i(2, 3): true}
	assert_eq(_side(Vector2i(2, 4), GridDir.Dir.NORTH, occupied), GridRules.AttackSide.SIDE)


func test_attacker_standing_behind_is_back() -> void:
	var occupied: Dictionary[Vector2i, bool] = {Vector2i(2, 3): true}
	assert_eq(_side(Vector2i(2, 3), GridDir.Dir.NORTH, occupied), GridRules.AttackSide.BACK)


func test_back_covered_by_wall_is_not_back() -> void:
	grid = TestFixtures.grid(["ggggg", "ggggg", "ggggg", "gg#gg", "ggggg"])
	assert_eq(_side(Vector2i(2, 4), GridDir.Dir.NORTH), GridRules.AttackSide.SIDE)


func test_back_covered_by_height_is_not_back() -> void:
	grid = TestFixtures.grid(
		["ggggg", "ggggg", "ggggg", "ggggg", "ggggg"],
		["00000", "00000", "00000", "00300", "00000"])
	assert_eq(_side(Vector2i(2, 4), GridDir.Dir.NORTH), GridRules.AttackSide.SIDE)


func test_back_covered_by_ally_of_attacker_is_not_back() -> void:
	# A ranged attacker behind the target, with a unit (any team) on the back cell.
	var occupied: Dictionary[Vector2i, bool] = {Vector2i(2, 3): true}
	assert_eq(_side(Vector2i(2, 4), GridDir.Dir.NORTH, occupied), GridRules.AttackSide.SIDE)
	assert_eq(_side(Vector2i(2, 4), GridDir.Dir.NORTH), GridRules.AttackSide.BACK, "same shot, back free")


func test_back_attack_boosts_damage_and_crit() -> void:
	var combat := CombatState.new(grid, rules, 1)
	var attacker := combat.add_unit(TestFixtures.unit_data("A"), UnitState.Team.PLAYER, Vector2i(2, 3))
	combat.add_unit(TestFixtures.unit_data("B"), UnitState.Team.ENEMY, TARGET, GridDir.Dir.NORTH)
	var skill := attacker.data.skills[0]
	var back := combat.preview_skill(attacker, skill, Vector2i(2, 3), TARGET)[0]
	var front := combat.preview_skill(attacker, skill, Vector2i(2, 1), TARGET)[0]
	assert_eq(back.side, GridRules.AttackSide.BACK)
	assert_eq(front.side, GridRules.AttackSide.FRONT)
	assert_true(back.damage > front.damage)
	assert_eq(back.crit_chance - front.crit_chance, rules.back_crit_bonus)
