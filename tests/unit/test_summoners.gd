extends TestCase
## Fighting summons (sand elementals): summon limit, summoner death, momentum,
## shared focus, hiding among allies and burrowing away.

var combat: CombatState
var troll: UnitState
var hero: UnitState
var elemental_data: UnitData
var summon: SkillData


func before_each() -> void:
	combat = CombatState.new(TestFixtures.flat_grid(12, 12), TestFixtures.rules(), 6)
	elemental_data = TestFixtures.unit_data("Elemental", 5)
	elemental_data.hp_per_cell_moved = 3
	elemental_data.attack_per_cell_moved = 1
	summon = TestFixtures.summon_skill(elemental_data)
	summon.summon_limit = 2
	summon.cooldown = 0
	summon.range_max = 3
	var data := TestFixtures.unit_data("Troll", 30)
	data.action_points = 6
	data.skills.append(summon)
	troll = combat.add_unit(data, UnitState.Team.ENEMY, Vector2i(5, 5))
	hero = combat.add_unit(TestFixtures.unit_data("Hero", 1), UnitState.Team.PLAYER, Vector2i(10, 10))


func _turn_of(unit: UnitState) -> void:
	for i in 60:
		var current := combat.start_next_turn()
		if current == unit:
			return
		combat.end_turn(current.facing)


func test_fighting_summons_are_not_structures_and_play_for_the_summoner_team() -> void:
	_turn_of(troll)
	var elemental := combat.use_skill(summon, Vector2i(5, 6)).summoned
	assert_false(elemental.is_structure())
	assert_eq(elemental.team, troll.team)
	assert_eq(elemental.summoner, troll)


func test_summon_limit_replaces_the_oldest() -> void:
	_turn_of(troll)
	var first := combat.use_skill(summon, Vector2i(5, 6)).summoned
	troll.cooldowns.clear()
	var second := combat.use_skill(summon, Vector2i(5, 4)).summoned
	troll.cooldowns.clear()
	var third := combat.use_skill(summon, Vector2i(4, 5))
	assert_true(second.is_alive())
	assert_false(first.is_alive(), "the oldest goes")
	assert_eq(third.replaced, first)


func test_summoner_death_kills_its_summons_and_can_end_the_combat() -> void:
	_turn_of(troll)
	var elemental := combat.use_skill(summon, Vector2i(5, 6)).summoned
	combat.end_turn(troll.facing)
	troll.hp = 1
	hero.cell = Vector2i(5, 4)
	_turn_of(hero)
	var result := combat.use_skill(hero.data.skills[0], troll.cell)
	assert_false(troll.is_alive())
	assert_false(elemental.is_alive(), "its summon dies with it")
	assert_has(result.orphaned, elemental)
	assert_true(combat.is_finished())
	assert_eq(combat.winner, UnitState.Team.PLAYER)


func test_walking_grows_momentum_units() -> void:
	_turn_of(troll)
	var elemental := combat.use_skill(summon, Vector2i(5, 6)).summoned
	combat.end_turn(troll.facing)
	_turn_of(elemental)
	var hp := elemental.max_hp
	var attack := elemental.attack
	combat.move_active_unit(Vector2i(5, 9))
	assert_eq(elemental.max_hp, hp + 9, "3 cells x 3 HP")
	assert_eq(elemental.hp, hp + 9)
	assert_eq(elemental.attack, attack + 3)


func test_hits_mark_the_team_focus_and_swarms_prefer_it() -> void:
	var other := combat.add_unit(TestFixtures.unit_data("Other", 1), UnitState.Team.PLAYER, Vector2i(4, 4))
	hero.cell = Vector2i(6, 6)
	_turn_of(troll)
	combat.focus_target[troll.team] = hero
	var profile := AiProfile.new()
	profile.shared_focus_weight = 200.0
	troll.data.ai_profile = profile
	var ai := BasicAI.new()
	var best := ai.best_attack_from(combat, troll, Vector2i(5, 5))
	assert_true(best.is_empty() or best.cell != other.cell, "never prefers the other one")
	troll.cell = Vector2i(6, 5)
	best = ai.best_attack_from(combat, troll, troll.cell)
	assert_eq(best.cell, hero.cell, "goes for the focus target")


func test_cover_makes_cells_next_to_allies_better() -> void:
	var guard := combat.add_unit(TestFixtures.unit_data("Guard", 1), UnitState.Team.ENEMY, Vector2i(2, 2))
	var profile := AiProfile.new()
	profile.ally_cover_weight = 5.0
	var ai := BasicAI.new()
	var near := ai.position_value(combat, troll, guard.cell + Vector2i(1, 0), {}, profile)
	var far := ai.position_value(combat, troll, Vector2i(9, 2), {}, profile)
	assert_true(near > far)


func test_threatened_summoner_burrows_away() -> void:
	var burrow := TestFixtures.skill(0, 3, 6)
	burrow.motion = SkillData.Motion.TELEPORT
	burrow.target_rule = SkillData.TargetRule.EMPTY_CELL
	burrow.skill_type = SkillData.SkillType.MOVEMENT
	burrow.vertical_reach = 9
	troll.data.skills = [burrow]
	troll.data.move_points = 0
	var profile := AiProfile.new()
	profile.threat_weight = 2.0
	profile.preferred_distance = 4
	troll.data.ai_profile = profile
	var brute := TestFixtures.unit_data("Brute", 1)
	brute.attack = 40
	combat.add_unit(brute, UnitState.Team.PLAYER, Vector2i(5, 6))
	_turn_of(troll)
	var action := BasicAI.new().decide(combat, troll)
	assert_eq(action.kind, AiAction.Kind.SKILL, "uses the burrow to escape")
	assert_eq(action.skill, burrow)
