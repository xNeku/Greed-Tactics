extends TestCase
## Run structure (v0.7): one protagonist + recruited companions, branching
## stage maps ending in a miniboss, rewards per node kind, optional battle
## objectives, enemies and map size scaled by party size.

var run: RunState
var config: RunConfig


func before_each() -> void:
	config = RunConfig.new()
	var a := TestFixtures.unit_data("A")
	a.skills[0].tags = [&"basico", &"melee", &"solo_a"]
	config.heroes = [a, TestFixtures.unit_data("B")]
	config.roster = [a, TestFixtures.unit_data("C"), TestFixtures.unit_data("D"), TestFixtures.unit_data("E")]
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


func _win(setup: BattleSetup, objective_met := false) -> RunState.Reward:
	var hp: Array[int] = []
	hp.assign(setup.player_hp)
	return run.complete_battle(true, hp, setup.enemy_units, 0, objective_met)


func _pick(kind: RunMap.Kind) -> RunMap.MapNode:
	for node in run.get_choices():
		if node.kind == kind:
			return node
	return null


## Plays a node of any kind, taking the first choice of everything.
func _play(node: RunMap.MapNode) -> void:
	run.choose_node(node)
	if node.is_battle():
		_win(run.start_battle())
		if not run.offer.is_empty():
			run.choose_modifier(run.offer[0])
		run.advance()
	if run.status == RunState.Status.RECRUIT:
		run.choose_recruit(run.recruit_offer[0])


func test_starts_with_the_protagonist_alone() -> void:
	assert_eq(run.heroes.size(), 1)
	assert_eq(run.get_protagonist().data, config.heroes[0])


func test_each_stage_map_ends_in_a_single_miniboss() -> void:
	for map in run.maps:
		var last: Array = map.get_layer(map.get_layer_count() - 1)
		assert_eq(last.size(), 1)
		assert_eq(last[0].kind, RunMap.Kind.MINIBOSS)
		assert_eq(map.get_layer_count(), config.phases_per_stage)


func test_every_node_is_reachable_and_leads_on() -> void:
	for map in run.maps:
		for layer in map.get_layer_count() - 1:
			var reached := {}
			for node: RunMap.MapNode in map.get_layer(layer):
				assert_false(node.links.is_empty(), "every node leads somewhere")
				for index in node.links:
					reached[index] = true
			assert_eq(reached.size(), map.get_layer(layer + 1).size(), "every next node is reachable")


func test_a_full_run_walks_both_stages_and_wins() -> void:
	var steps := 0
	while run.status != RunState.Status.WON and steps < 20:
		_play(run.get_choices()[0])
		steps += 1
	assert_eq(run.status, RunState.Status.WON)
	assert_eq(steps, config.stage_count * config.phases_per_stage)


func test_recruiting_adds_a_companion_not_in_the_party() -> void:
	_play(run.get_choices()[0])
	var recruit := _pick(RunMap.Kind.RECRUIT)
	if recruit == null:
		return  # This seed has no recruit on layer 1; covered by the next test.
	run.choose_node(recruit)
	assert_eq(run.status, RunState.Status.RECRUIT)
	assert_eq(run.recruit_offer.size(), config.recruit_offer_size)
	assert_not_has(run.recruit_offer, config.heroes[0])
	run.choose_recruit(run.recruit_offer[1])
	assert_eq(run.heroes.size(), 2)
	assert_eq(run.status, RunState.Status.MAP)


func test_each_stage_offers_recruit_nodes() -> void:
	for map in run.maps:
		var recruits := 0
		for layer in map.get_layer_count():
			for node: RunMap.MapNode in map.get_layer(layer):
				if node.kind == RunMap.Kind.RECRUIT:
					recruits += 1
		assert_true(recruits >= mini(config.recruits_per_stage, config.phases_per_stage - 2))


func test_a_full_party_gets_gold_instead() -> void:
	for i in 3:
		run.heroes.append(HeroState.new(config.roster[i + 1], 1))
	run.status = RunState.Status.RECRUIT
	run.status = RunState.Status.MAP
	run.current_node = null
	var node := RunMap.MapNode.new()
	node.kind = RunMap.Kind.RECRUIT
	run.maps[0].layers[0][0] = node
	var gold := run.gold
	run.choose_node(node)
	assert_eq(run.heroes.size(), 4)
	assert_eq(run.gold, gold + config.recruit_gold_when_full)
	assert_eq(run.status, RunState.Status.MAP)


func test_combat_gives_gold_elite_and_objectives_give_a_modifier() -> void:
	var first := run.get_choices()[0]
	first.objective = RunMap.Objective.NONE
	run.choose_node(first)
	var reward := _win(run.start_battle())
	assert_false(reward.offers_modifier)
	assert_true(reward.gold > 0)
	run.advance()
	var next: RunMap.MapNode = run.get_choices()[0]
	next.kind = RunMap.Kind.COMBAT
	next.objective = RunMap.Objective.PROTECT
	run.choose_node(next)
	var setup := run.start_battle()
	assert_eq(setup.objective, RunMap.Objective.PROTECT)
	var bonus := _win(setup, true)
	assert_true(bonus.objective_met)
	assert_true(bonus.offers_modifier, "meeting the objective gives the bonus")
	assert_eq(run.offer.size(), 3)


func test_failed_objective_gives_no_bonus() -> void:
	var first: RunMap.MapNode = run.get_choices()[0]
	first.objective = RunMap.Objective.ESCAPE
	run.choose_node(first)
	var reward := _win(run.start_battle(), false)
	assert_false(reward.objective_met)
	assert_false(reward.offers_modifier)


func test_modifiers_are_offered_for_the_protagonist_only() -> void:
	var own := TestFixtures.modifier(ModifierData.Effect.DAMAGE_FLAT, 1, &"solo_a", 1, ModifierData.Trigger.ALWAYS, &"own")
	var other := TestFixtures.modifier(ModifierData.Effect.DAMAGE_FLAT, 1, &"nobody", 1, ModifierData.Trigger.ALWAYS, &"other")
	config.modifier_pool = [own, other]
	run.roll_offer()
	assert_has(run.offer, own)
	assert_not_has(run.offer, other)


func test_protagonist_falling_loses_the_run() -> void:
	run.heroes.append(HeroState.new(config.roster[1], 1))
	run.choose_node(run.get_choices()[0])
	var setup := run.start_battle()
	var hp: Array[int] = [0, 30]
	run.complete_battle(true, hp, setup.enemy_units)
	assert_eq(run.status, RunState.Status.LOST)


func test_enemies_and_map_grow_with_the_party() -> void:
	run.choose_node(run.get_choices()[0])
	var solo := run.start_battle()
	run.status = RunState.Status.MAP
	run.current_node = null
	for i in 3:
		run.heroes.append(HeroState.new(config.roster[i + 1], 1))
	run.choose_node(run.get_choices()[0])
	var full := run.start_battle()
	assert_eq(solo.enemy_units.size(), config.enemies_by_party[0])
	assert_eq(full.enemy_units.size(), config.enemies_by_party[3])
	assert_true(solo.map.get_size().x * solo.map.get_size().y < full.map.get_size().x * full.map.get_size().y, "smaller map alone")


func test_rest_heals_the_party() -> void:
	run.get_protagonist().hp = 1
	var node := RunMap.MapNode.new()
	node.kind = RunMap.Kind.REST
	run.maps[0].layers[0][0] = node
	run.choose_node(node)
	assert_true(run.get_protagonist().hp > 1)
	assert_eq(run.status, RunState.Status.MAP)


func test_miniboss_victory_offers_a_recruit_before_the_next_stage() -> void:
	config.stage_count = 2
	config.zones.append(config.zones[0])
	run = RunState.new(config, TestFixtures.rules(), 5)
	while not (run.get_choices().size() == 1 and run.get_choices()[0].kind == RunMap.Kind.MINIBOSS):
		var node := run.get_choices()[0]
		if node.kind == RunMap.Kind.RECRUIT:
			run.choose_node(node)
			run.skip_recruit()
		else:
			_play(node)
	run.choose_node(run.get_choices()[0])
	_win(run.start_battle())
	run.choose_modifier(run.offer[0])
	run.advance()
	assert_eq(run.status, RunState.Status.RECRUIT)
	run.choose_recruit(run.recruit_offer[0])
	assert_eq(run.stage, 1, "on to the next stage")


func test_protagonist_bonus_goes_into_every_battle() -> void:
	run.choose_node(run.get_choices()[0])
	var setup := run.start_battle()
	assert_eq(setup.protagonist_move_bonus, config.protagonist_move_bonus)
	assert_eq(setup.protagonist_action_bonus, config.protagonist_action_bonus)


func test_same_seed_same_maps() -> void:
	var other := RunState.new(config, TestFixtures.rules(), 77)
	for stage in run.maps.size():
		for layer in run.maps[stage].get_layer_count():
			var a: Array = run.maps[stage].get_layer(layer)
			var b: Array = other.maps[stage].get_layer(layer)
			assert_eq(a.size(), b.size())
			for i in a.size():
				assert_eq(a[i].kind, b[i].kind)
				assert_eq(a[i].links, b[i].links)


func test_battle_only_hp_bonus_does_not_carry_over() -> void:
	run.choose_node(run.get_choices()[0])
	var setup := run.start_battle()
	var max_hp := run.get_protagonist().get_max_hp(run.level)
	var hp: Array[int] = [max_hp + 50]
	run.complete_battle(true, hp, setup.enemy_units)
	assert_true(run.get_protagonist().hp <= run.get_protagonist().get_max_hp(run.level))


func test_late_zones_never_open_the_run() -> void:
	var late := TestFixtures.zone(ZoneData.Layout.CASTLE)
	late.min_stage = 1
	late.enemy_pool = config.zones[0].enemy_pool
	late.miniboss_pool = config.zones[0].miniboss_pool
	config.zones = [late, config.zones[0]]
	config.stage_count = 2
	for s in 12:
		var other := RunState.new(config, TestFixtures.rules(), s + 1)
		assert_ne(other.zones[0], late, "seed %d" % (s + 1))
		assert_eq(other.zones[1], late)
