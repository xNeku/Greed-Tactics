extends TestCase
## Tactical AI (BasicAI + AiProfile): threat map, backstabs, focus fire,
## ranged units keeping distance.

var combat: CombatState


func before_each() -> void:
	combat = CombatState.new(TestFixtures.flat_grid(10, 10), TestFixtures.rules(), 9)


func _play_turn(unit: UnitState) -> void:
	var ai := BasicAI.new()
	for step in 10:
		var action := ai.decide(combat, unit)
		match action.kind:
			AiAction.Kind.MOVE:
				combat.move_active_unit(action.cell)
			AiAction.Kind.SKILL:
				combat.use_skill(action.skill, action.cell)
			_:
				return


func _turn_of(unit: UnitState) -> void:
	for i in 50:
		var current := combat.start_next_turn()
		if current == unit:
			return
		combat.end_turn(current.facing)


func test_threat_map_covers_opponent_reach() -> void:
	var me := combat.add_unit(TestFixtures.unit_data("Me", 1), UnitState.Team.ENEMY, Vector2i(9, 9))
	combat.add_unit(TestFixtures.unit_data("Hero", 20), UnitState.Team.PLAYER, Vector2i(2, 2))
	var threat := BasicAI.new().build_threat_map(combat, me)
	assert_true(threat.get(Vector2i(3, 2), 0.0) > 0.0, "next to the hero is dangerous")
	assert_eq(threat.get(Vector2i(9, 9), 0.0), 0.0, "far away is safe")


func test_ai_prefers_the_back() -> void:
	var hero := combat.add_unit(TestFixtures.unit_data("Hero", 1), UnitState.Team.PLAYER, Vector2i(5, 5), GridDir.Dir.NORTH)
	# Back (5,6) and flank (6,5) both cost 3 PM from here: it must pick the back.
	var foe := combat.add_unit(TestFixtures.unit_data("Foe", 20), UnitState.Team.ENEMY, Vector2i(8, 6))
	_turn_of(foe)
	var action := BasicAI.new().decide(combat, foe)
	assert_eq(action.kind, AiAction.Kind.MOVE)
	assert_eq(action.cell, hero.cell + Vector2i(0, 1), "goes around to stab the back")


func test_ai_finishes_the_wounded_one() -> void:
	var healthy := combat.add_unit(TestFixtures.unit_data("Healthy", 1), UnitState.Team.PLAYER, Vector2i(4, 5))
	var wounded := combat.add_unit(TestFixtures.unit_data("Wounded", 1), UnitState.Team.PLAYER, Vector2i(6, 5))
	wounded.hp = 15
	var foe_data := TestFixtures.unit_data("Foe", 20)
	foe_data.action_points = 1
	var foe := combat.add_unit(foe_data, UnitState.Team.ENEMY, Vector2i(5, 5))
	_turn_of(foe)
	_play_turn(foe)
	assert_false(wounded.is_alive(), "its only attack kills the wounded target")
	assert_eq(healthy.hp, healthy.max_hp)


func test_ranged_profile_keeps_distance() -> void:
	var archer_data := TestFixtures.unit_data("Archer", 20)
	archer_data.skills[0].range_min = 2
	archer_data.skills[0].range_max = 5
	archer_data.skills[0].vertical_reach = 5
	var profile := AiProfile.new()
	profile.preferred_distance = 4
	profile.threat_weight = 1.0
	archer_data.ai_profile = profile
	var hero := combat.add_unit(TestFixtures.unit_data("Hero", 1), UnitState.Team.PLAYER, Vector2i(5, 5))
	var archer := combat.add_unit(archer_data, UnitState.Team.ENEMY, Vector2i(5, 7))
	_turn_of(archer)
	_play_turn(archer)
	assert_true(hero.hp < hero.max_hp, "shoots")
	assert_true(BattleGrid.manhattan(archer.cell, hero.cell) >= 3, "and does not stay in melee range")


func test_taunted_unit_goes_for_the_taunter() -> void:
	var near := combat.add_unit(TestFixtures.unit_data("Near", 1), UnitState.Team.PLAYER, Vector2i(5, 4))
	near.hp = 10  # Wounded and adjacent: normally the obvious target.
	var taunter := combat.add_unit(TestFixtures.unit_data("Taunter", 1), UnitState.Team.PLAYER, Vector2i(5, 8))
	var foe := combat.add_unit(TestFixtures.unit_data("Foe", 20), UnitState.Team.ENEMY, Vector2i(5, 5))
	var taunt := TestFixtures.status(StatusData.Kind.OTHER, 2)
	taunt.taunts = true
	foe.add_status(taunt, 2, taunter)
	_turn_of(foe)
	_play_turn(foe)
	assert_eq(near.hp, 10, "ignores the wounded unit next to it")
	assert_true(taunter.hp < taunter.max_hp, "walks to the taunter and hits it")


func test_ai_values_healing_wounded_allies() -> void:
	var foe_data := TestFixtures.unit_data("Healer", 20)
	var nova := TestFixtures.skill(5)
	nova.target_rule = SkillData.TargetRule.SELF
	nova.area_shape = AreaShape.Shape.DIAMOND
	nova.area_size = 2
	nova.heal_percent = 50
	foe_data.skills = [nova]
	var healer := combat.add_unit(foe_data, UnitState.Team.ENEMY, Vector2i(5, 5))
	var ally := combat.add_unit(TestFixtures.unit_data("Ally", 1), UnitState.Team.ENEMY, Vector2i(5, 6))
	ally.hp = 20
	combat.add_unit(TestFixtures.unit_data("Hero", 1), UnitState.Team.PLAYER, Vector2i(6, 5))
	_turn_of(healer)
	var action := BasicAI.new().decide(combat, healer)
	assert_eq(action.kind, AiAction.Kind.SKILL)
	combat.use_skill(action.skill, action.cell)
	assert_eq(ally.hp, 70, "healed 50% of max HP")


func _height_grid(heights: PackedStringArray) -> BattleGrid:
	var rows := PackedStringArray()
	for row in heights:
		rows.append("g".repeat(row.length()))
	return TestFixtures.grid(rows, heights)


func test_melee_takes_the_ramp_to_reach_a_unit_on_high_ground() -> void:
	combat = CombatState.new(_height_grid([
		"0000000333",
		"0000000333",
		"0000000333",
		"0000000002",
		"0000000001",
		"0000000000",
	]), TestFixtures.rules(), 9)
	var hero := combat.add_unit(TestFixtures.unit_data("Hero", 1), UnitState.Team.PLAYER, Vector2i(7, 1))
	var foe_data := TestFixtures.unit_data("Foe", 20)
	foe_data.move_points = 6
	var foe := combat.add_unit(foe_data, UnitState.Team.ENEMY, Vector2i(4, 4))
	_turn_of(foe)
	_play_turn(foe)
	assert_true(foe.cell.x >= 8, "heads for the ramp instead of waiting under the cliff: %s" % foe.cell)
	assert_eq(hero.hp, hero.max_hp)


func test_unreachable_target_still_gets_approached() -> void:
	combat = CombatState.new(_height_grid([
		"00000",
		"00300",
		"00000",
		"00000",
		"00000",
		"00000",
		"00000",
	]), TestFixtures.rules(), 9)
	var hero := combat.add_unit(TestFixtures.unit_data("Hero", 1), UnitState.Team.PLAYER, Vector2i(2, 1))
	var foe := combat.add_unit(TestFixtures.unit_data("Foe", 20), UnitState.Team.ENEMY, Vector2i(2, 6))
	_turn_of(foe)
	var before := BattleGrid.manhattan(foe.cell, hero.cell)
	_play_turn(foe)
	assert_true(BattleGrid.manhattan(foe.cell, hero.cell) < before, "does not wander off")


func test_cautious_unit_engages_after_a_long_stalemate() -> void:
	var hero_data := TestFixtures.unit_data("Hero", 1)
	hero_data.attack = 60  # Any cell near the hero is very dangerous.
	var hero := combat.add_unit(hero_data, UnitState.Team.PLAYER, Vector2i(1, 1))
	var foe_data := TestFixtures.unit_data("Coward", 20)
	foe_data.skills[0].range_max = 1
	var profile := AiProfile.new()
	profile.threat_weight = 50.0
	profile.patience_turns = 6
	foe_data.ai_profile = profile
	var foe := combat.add_unit(foe_data, UnitState.Team.ENEMY, Vector2i(8, 8))
	_turn_of(foe)
	var ai := BasicAI.new()
	combat.turns_without_damage = 0
	assert_eq(ai.get_caution(combat, profile), 1.0)
	combat.turns_without_damage = 6
	assert_eq(ai.get_caution(combat, profile), 0.0, "no fear left")
	var before := BattleGrid.manhattan(foe.cell, hero.cell)
	_play_turn(foe)
	assert_true(BattleGrid.manhattan(foe.cell, hero.cell) < before, "goes in after the stalemate")


func test_damage_resets_the_stalemate_counter() -> void:
	var hero := combat.add_unit(TestFixtures.unit_data("Hero", 20), UnitState.Team.PLAYER, Vector2i(4, 4))
	combat.add_unit(TestFixtures.unit_data("Foe", 1), UnitState.Team.ENEMY, Vector2i(4, 5))
	combat.turns_without_damage = 5
	_turn_of(hero)
	combat.use_skill(hero.data.skills[0], Vector2i(4, 5))
	assert_eq(combat.turns_without_damage, 0)


func test_ai_goes_for_the_healer_before_the_tank() -> void:
	var tank_data := TestFixtures.unit_data("Tank", 1)
	tank_data.attack = 14
	var healer_data := TestFixtures.unit_data("Healer", 1)
	var mend := TestFixtures.skill(0, 1, 5)
	mend.target_rule = SkillData.TargetRule.ALLY_UNIT
	mend.heal_percent = 30
	healer_data.skills.append(mend)
	var tank := combat.add_unit(tank_data, UnitState.Team.PLAYER, Vector2i(4, 5))
	var healer := combat.add_unit(healer_data, UnitState.Team.PLAYER, Vector2i(6, 5))
	var foe := combat.add_unit(TestFixtures.unit_data("Foe", 20), UnitState.Team.ENEMY, Vector2i(5, 5))
	_turn_of(foe)
	var best := BasicAI.new().best_attack_from(combat, foe, foe.cell)
	assert_eq(best.cell, healer.cell, "the healer, not the more dangerous tank")
	assert_eq(tank.hp, tank.max_hp)


func test_ai_exploits_crits_on_poisoned_targets() -> void:
	var a := combat.add_unit(TestFixtures.unit_data("A", 1), UnitState.Team.PLAYER, Vector2i(4, 5))
	var b := combat.add_unit(TestFixtures.unit_data("B", 1), UnitState.Team.PLAYER, Vector2i(6, 5))
	var data := TestFixtures.unit_data("Assassin", 20)
	data.skills[0].crit_vs_status_kind = StatusData.Kind.POISON
	var foe := combat.add_unit(data, UnitState.Team.ENEMY, Vector2i(5, 5))
	b.add_status(TestFixtures.status(StatusData.Kind.POISON, 3), 3)
	_turn_of(foe)
	var best := BasicAI.new().best_attack_from(combat, foe, foe.cell)
	assert_eq(best.cell, b.cell, "the poisoned one: guaranteed crit")
	assert_eq(a.hp, a.max_hp)


func test_ai_sets_up_combos_for_its_allies() -> void:
	var hero := combat.add_unit(TestFixtures.unit_data("Hero", 1), UnitState.Team.PLAYER, Vector2i(5, 4))
	var data := TestFixtures.unit_data("Poisoner", 20)
	var plain := TestFixtures.skill(25)  # 15 more damage: only the combo justifies the poison.
	var venom := TestFixtures.skill(10)
	venom.status = TestFixtures.status(StatusData.Kind.POISON, 3)
	data.skills = [plain, venom]
	data.action_points = 1
	var poisoner := combat.add_unit(data, UnitState.Team.ENEMY, Vector2i(5, 5))
	var assassin_data := TestFixtures.unit_data("Assassin", 1)
	assassin_data.skills[0].crit_vs_status_kind = StatusData.Kind.POISON
	combat.add_unit(assassin_data, UnitState.Team.ENEMY, Vector2i(9, 9))
	_turn_of(poisoner)
	var best := BasicAI.new().best_attack_from(combat, poisoner, poisoner.cell)
	assert_eq(best.skill, venom, "poisons so the assassin can crit, even if it hits a bit less")
	assert_eq(hero.hp, hero.max_hp)
