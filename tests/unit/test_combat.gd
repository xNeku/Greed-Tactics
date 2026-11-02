extends TestCase
## Skill use, PA/MP costs, targeting and victory.

var combat: CombatState
var hero: UnitState
var foe: UnitState


func before_each() -> void:
	combat = CombatState.new(TestFixtures.flat_grid(6, 6), TestFixtures.rules(), 42)
	hero = combat.add_unit(TestFixtures.unit_data("Hero", 20), UnitState.Team.PLAYER, Vector2i(2, 2))
	foe = combat.add_unit(TestFixtures.unit_data("Foe", 5), UnitState.Team.ENEMY, Vector2i(2, 3), GridDir.Dir.NORTH)
	combat.start_next_turn()


func test_hero_acts_first() -> void:
	assert_eq(combat.active_unit, hero)


func test_skill_spends_pa_and_damages() -> void:
	var skill := hero.get_basic_skill()
	var result := combat.use_skill(skill, foe.cell)
	assert_not_null(result)
	assert_eq(hero.pa, hero.data.action_points - skill.ap_cost)
	assert_eq(result.hits.size(), 1)
	var hit := result.hits[0]
	assert_true(hit.landed, "0 evasion always hits")
	assert_eq(foe.hp, foe.data.max_hp - hit.damage)
	assert_eq(hero.facing, GridDir.Dir.SOUTH, "turns towards the target")


func test_cannot_use_skill_out_of_range_or_without_pa() -> void:
	var skill := hero.get_basic_skill()
	assert_null(combat.use_skill(skill, Vector2i(5, 5)), "out of range")
	hero.pa = 0
	assert_null(combat.use_skill(skill, foe.cell), "no PA")
	assert_eq(foe.hp, foe.data.max_hp)


func test_vertical_reach_limits_targets() -> void:
	var grid := TestFixtures.grid(["ggg"], ["030"])
	var c := CombatState.new(grid, TestFixtures.rules(), 1)
	var unit := c.add_unit(TestFixtures.unit_data(), UnitState.Team.PLAYER, Vector2i(0, 0))
	var cells := c.get_targetable_cells(unit, unit.get_basic_skill(), unit.cell)
	assert_not_has(cells, Vector2i(1, 0), "3 levels above a melee skill")


func test_defeating_last_enemy_finishes_combat() -> void:
	foe.hp = 1
	var winners: Array[int] = []
	combat.combat_finished.connect(func(team: UnitState.Team) -> void: winners.append(team))
	combat.use_skill(hero.get_basic_skill(), foe.cell)
	assert_false(foe.is_alive())
	assert_true(combat.is_finished())
	assert_eq(winners, [UnitState.Team.PLAYER] as Array[int])


func test_ai_attacks_adjacent_opponent() -> void:
	while combat.active_unit != foe:
		combat.end_turn(combat.active_unit.facing)
		combat.start_next_turn()
	var action := BasicAI.new().decide(combat, foe)
	assert_eq(action.kind, AiAction.Kind.SKILL)
	assert_eq(action.cell, hero.cell)


func test_ai_approaches_when_out_of_range() -> void:
	var c := CombatState.new(TestFixtures.flat_grid(12, 1), TestFixtures.rules(), 1)
	c.add_unit(TestFixtures.unit_data("Hero", 1), UnitState.Team.PLAYER, Vector2i(0, 0))
	var enemy := c.add_unit(TestFixtures.unit_data("Foe", 20), UnitState.Team.ENEMY, Vector2i(11, 0))
	c.start_next_turn()
	var action := BasicAI.new().decide(c, enemy)
	assert_eq(action.kind, AiAction.Kind.MOVE)
	assert_eq(action.cell, Vector2i(11 - enemy.data.move_points, 0))


func test_duplicate_enemy_names_get_suffixes() -> void:
	var setup := BattleSetup.new()
	setup.map = MapData.create([TestFixtures.grass()] as Array[TerrainData], ["gggg"], ["0000"])
	setup.map.player_spawns = [Vector2i(0, 0)]
	setup.map.enemy_spawns = [Vector2i(2, 0), Vector2i(3, 0)]
	var goblin := TestFixtures.unit_data("Goblin")
	setup.player_units = [TestFixtures.unit_data("Hero")]
	setup.enemy_units = [goblin, goblin]
	var c := CombatState.from_setup(setup, TestFixtures.rules())
	assert_eq(c.units[1].display_name, "Goblin A")
	assert_eq(c.units[2].display_name, "Goblin B")
