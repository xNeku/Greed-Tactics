extends TestCase
## Elites, bosses and rage mode (v0.9.1): elites are picked per battle and
## get tougher, bosses never count as elites and carry innate modifiers,
## rage mode starts when a skill would mutate, buffs are the helpful statuses.


func _setup(enemies: Array[UnitData], elites: int) -> BattleSetup:
	var setup := BattleSetup.new()
	setup.map = MapData.create([TestFixtures.grass()] as Array[TerrainData], ["gggggg", "gggggg"], ["000000", "000000"])
	setup.map.player_spawns = [Vector2i(0, 0)]
	setup.map.enemy_spawns = [Vector2i(5, 0), Vector2i(5, 1), Vector2i(4, 1)]
	setup.player_units = [TestFixtures.unit_data("Hero")]
	setup.enemy_units = enemies
	setup.elite_count = elites
	return setup


func test_elites_are_tougher_and_counted() -> void:
	var grunt := TestFixtures.unit_data("Grunt")
	var rules := TestFixtures.rules()
	var combat := CombatState.from_setup(_setup([grunt, grunt, grunt], 2), rules)
	var foes := combat.get_living_units(UnitState.Team.ENEMY)
	var elites := foes.filter(func(u: UnitState) -> bool: return u.is_elite)
	assert_eq(elites.size(), 2)
	var normal: UnitState = foes.filter(func(u: UnitState) -> bool: return not u.is_elite)[0]
	assert_true(elites[0].max_hp > normal.max_hp)
	assert_true(elites[0].attack > normal.attack)
	assert_eq(elites[0].hp, elites[0].max_hp)


func test_bosses_are_never_elites_and_keep_their_modifiers() -> void:
	var boss := TestFixtures.unit_data("Boss")
	boss.rank = UnitData.Rank.BOSS
	var mod := TestFixtures.modifier(ModifierData.Effect.DAMAGE_FLAT, 5)
	boss.innate_modifiers = [mod]
	var combat := CombatState.from_setup(_setup([boss, TestFixtures.unit_data("Grunt")], 1), TestFixtures.rules())
	var foes := combat.get_living_units(UnitState.Team.ENEMY)
	assert_false(foes[0].is_elite, "the boss is not an elite")
	assert_true(foes[1].is_elite, "the add is")
	assert_has(foes[0].modifiers, mod)


func test_rage_mode_starts_when_a_skill_would_mutate() -> void:
	var data := TestFixtures.rage_unit_data()
	var unit := UnitState.new(1, data, UnitState.Team.PLAYER, Vector2i.ZERO, GridDir.Dir.SOUTH)
	unit.rage = 0
	assert_false(unit.is_enraged())
	var threshold := 100
	for skill in data.skills:
		if skill.empowered_variant != null:
			threshold = mini(threshold, skill.empowered_rage_threshold)
	unit.rage = threshold
	assert_true(unit.is_enraged())


func test_buffs_are_the_helpful_statuses() -> void:
	var unit := UnitState.new(1, TestFixtures.unit_data(), UnitState.Team.PLAYER, Vector2i.ZERO, GridDir.Dir.SOUTH)
	var fire := TestFixtures.status(StatusData.Kind.OTHER)
	fire.damage_percent_bonus = 20
	var poison := TestFixtures.status(StatusData.Kind.POISON)
	unit.add_status(fire, 2)
	unit.add_status(poison, 2)
	assert_eq(unit.get_buffs(), [fire] as Array[StatusData])
