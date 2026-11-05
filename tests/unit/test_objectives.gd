extends TestCase
## Protagonist rules and optional battle objectives (protect / escape).

var rules: RulesConfig


func before_each() -> void:
	rules = TestFixtures.rules()


func _setup(players: int, objective: int, extra_spawns := 0) -> BattleSetup:
	var setup := BattleSetup.new()
	var rows := PackedStringArray()
	for y in 10:
		rows.append("g".repeat(12))
	setup.map = MapData.create([TestFixtures.grass(), TestFixtures.water(), TestFixtures.wall()], rows, PackedStringArray())
	for i in players + extra_spawns:
		setup.map.player_spawns.append(Vector2i(1, 4 + i))
	setup.map.enemy_spawns = [Vector2i(10, 5)]
	for i in players:
		setup.player_units.append(TestFixtures.unit_data("Hero%d" % i, 20 - i))
	setup.enemy_units = [TestFixtures.unit_data("Foe", 1)]
	setup.has_protagonist = true
	setup.objective = objective
	setup.rng_seed = 3
	setup.player_modifiers = [TestFixtures.modifier(ModifierData.Effect.DAMAGE_FLAT, 5)]
	return setup


func test_modifiers_only_on_the_protagonist() -> void:
	var combat := CombatState.from_setup(_setup(2, 0), rules)
	var heroes := combat.get_living_units(UnitState.Team.PLAYER)
	assert_true(heroes[0].is_protagonist)
	assert_eq(heroes[0].modifiers.size(), 1)
	assert_eq(heroes[1].modifiers.size(), 0)


func test_losing_the_protagonist_loses_the_battle() -> void:
	var combat := CombatState.from_setup(_setup(2, 0), rules)
	var heroes := combat.get_living_units(UnitState.Team.PLAYER)
	var foe := combat.get_living_units(UnitState.Team.ENEMY)[0]
	heroes[0].hp = 1
	foe.cell = heroes[0].cell + Vector2i(1, 0)
	for i in 50:
		if combat.start_next_turn() == foe:
			break
		combat.end_turn(combat.active_unit.facing)
	combat.use_skill(foe.data.skills[0], heroes[0].cell)
	assert_true(combat.is_finished())
	assert_eq(combat.winner, UnitState.Team.ENEMY, "the companion alive does not save the battle")


func test_protect_spawns_the_cart_and_counts_it() -> void:
	var combat := CombatState.from_setup(_setup(1, CombatState.OBJECTIVE_PROTECT, 1), rules)
	assert_not_null(combat.objective_unit)
	assert_true(combat.objective_unit.is_structure())
	assert_eq(combat.objective_unit.team, UnitState.Team.PLAYER)
	combat.get_living_units(UnitState.Team.ENEMY)[0].hp = 0
	combat.winner = UnitState.Team.PLAYER
	assert_true(combat.is_objective_met())
	combat.objective_unit.hp = 0
	assert_false(combat.is_objective_met(), "a broken cart means no bonus")


func test_escape_wins_when_the_protagonist_reaches_the_exit() -> void:
	var combat := CombatState.from_setup(_setup(1, CombatState.OBJECTIVE_ESCAPE), rules)
	assert_false(combat.exit_cells.is_empty())
	var hero := combat.get_living_units(UnitState.Team.PLAYER)[0]
	for i in 50:
		if combat.start_next_turn() == hero:
			break
		combat.end_turn(combat.active_unit.facing)
	var exit := combat.exit_cells[0]
	hero.cell = exit + Vector2i(0, 1 if exit.y == 0 else -1)
	combat.move_active_unit(exit)
	assert_true(combat.is_finished())
	assert_eq(combat.winner, UnitState.Team.PLAYER)
	assert_true(combat.is_objective_met())


func test_protagonist_moves_and_acts_more() -> void:
	var setup := _setup(2, 0)
	setup.protagonist_move_bonus = 1
	setup.protagonist_action_bonus = 1
	var combat := CombatState.from_setup(setup, rules)
	var heroes := combat.get_living_units(UnitState.Team.PLAYER)
	assert_eq(heroes[0].move_points, heroes[1].move_points + 1)
	assert_eq(heroes[0].action_points, heroes[1].action_points + 1)
	for i in 50:
		if combat.start_next_turn() == heroes[0]:
			break
		combat.end_turn(combat.active_unit.facing)
	assert_eq(heroes[0].pa, heroes[0].data.action_points + 1, "every turn")
