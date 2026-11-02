extends TestCase
## Run structure: 2 stages x 4 phases, miniboss on the last phase, modifier
## rewards on even phases, gold on odd ones, XP always (prototype v0.3).

var run: RunState


func before_each() -> void:
	var config := RunConfig.new()
	config.heroes = [TestFixtures.unit_data("A"), TestFixtures.unit_data("B")]
	var zone := TestFixtures.zone(ZoneData.Layout.FOREST)
	var grunt := TestFixtures.unit_data("Grunt")
	grunt.xp_reward = 5
	grunt.gold_reward = 2
	var boss := TestFixtures.unit_data("Boss")
	zone.enemy_pool = [grunt]
	zone.miniboss_pool = [boss]
	config.zones = [zone]
	for i in 6:
		var m := TestFixtures.modifier(ModifierData.Effect.DAMAGE_FLAT, i + 1, &"", 1, ModifierData.Trigger.ALWAYS, StringName("m%d" % i))
		config.modifier_pool.append(m)
	run = RunState.new(config, TestFixtures.rules(), 77)


func _win(setup: BattleSetup) -> RunState.Reward:
	var hp: Array[int] = []
	hp.assign(setup.player_hp)
	return run.complete_battle(true, hp, setup.enemy_units)


func test_structure_two_stages_four_phases() -> void:
	var battles := 0
	while run.status != RunState.Status.WON:
		var setup := run.start_battle()
		battles += 1
		var reward := _win(setup)
		if reward.offers_modifier:
			run.choose_modifier(run.offer[0])
		run.advance()
		assert_true(battles <= 8, "no more than 8 battles")
	assert_eq(battles, 8)


func test_last_phase_has_a_miniboss() -> void:
	for i in 3:
		_win(run.start_battle())
		if not run.offer.is_empty():
			run.choose_modifier(run.offer[0])
		run.advance()
	assert_true(run.is_miniboss_phase())
	var setup := run.start_battle()
	assert_eq(setup.enemy_units[0].display_name, "Boss")


func test_even_phases_offer_modifiers_odd_phases_give_gold() -> void:
	var first := _win(run.start_battle())
	assert_false(first.offers_modifier)
	assert_true(first.gold > 0)
	assert_true(first.xp > 0)
	run.advance()
	var gold_before := run.gold
	var second := _win(run.start_battle())
	assert_true(second.offers_modifier)
	assert_eq(second.gold, 0)
	assert_eq(run.gold, gold_before)
	assert_eq(run.offer.size(), 3)
	assert_true(second.xp > 0)


func test_reroll_costs_gold_and_is_limited() -> void:
	_win(run.start_battle())
	run.advance()
	_win(run.start_battle())
	run.gold = 100
	assert_true(run.reroll())
	assert_eq(run.gold, 100 - run.config.reroll_cost)
	assert_false(run.reroll(), "only one reroll per checkpoint")


func test_choosing_a_modifier_adds_it_to_next_battles() -> void:
	_win(run.start_battle())
	run.advance()
	_win(run.start_battle())
	var picked := run.offer[1]
	assert_true(run.choose_modifier(picked))
	run.advance()
	var setup := run.start_battle()
	assert_has(setup.player_modifiers, picked)


func test_xp_levels_up_the_party() -> void:
	var gained := run.add_xp(run.get_xp_to_next_level())
	assert_eq(gained, 1)
	assert_eq(run.level, 2)


func test_hp_persists_and_fallen_heroes_revive() -> void:
	var setup := run.start_battle()
	run.complete_battle(true, [0, 7] as Array[int], setup.enemy_units)
	assert_true(run.heroes[0].hp > 0, "revived")
	assert_eq(run.heroes[1].hp, 7)


func test_defeat_ends_the_run() -> void:
	run.start_battle()
	run.complete_battle(false, [0, 0] as Array[int])
	assert_eq(run.status, RunState.Status.LOST)


func test_enemies_scale_with_progress() -> void:
	var first_level := run.get_enemy_level()
	_win(run.start_battle())
	run.advance()
	assert_true(run.get_enemy_level() > first_level)
