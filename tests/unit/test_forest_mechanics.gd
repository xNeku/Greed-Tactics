extends TestCase
## Mechanics added for the forest enemies: guaranteed crits on poisoned
## targets, haste, vulnerability, uses per turn, charges spent by skills,
## single-target healing at any range, support AI and the Ent's roll.

var combat: CombatState
var hero: UnitState
var foe: UnitState


func before_each() -> void:
	combat = CombatState.new(TestFixtures.flat_grid(12, 12), TestFixtures.rules(), 8)
	hero = combat.add_unit(TestFixtures.unit_data("Hero", 20), UnitState.Team.PLAYER, Vector2i(5, 5))
	foe = combat.add_unit(TestFixtures.unit_data("Foe", 1), UnitState.Team.ENEMY, Vector2i(5, 6))


func _turn_of(unit: UnitState) -> void:
	for i in 60:
		var current := combat.start_next_turn()
		if current == unit:
			return
		combat.end_turn(current.facing)


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


func test_always_crits_a_poisoned_target() -> void:
	var stab := hero.data.skills[0]
	stab.crit_vs_status_kind = StatusData.Kind.POISON
	_turn_of(hero)
	assert_true(combat.preview_skill(hero, stab, hero.cell, foe.cell)[0].crit_chance < 100)
	foe.add_status(TestFixtures.status(StatusData.Kind.POISON), 2)
	assert_eq(combat.preview_skill(hero, stab, hero.cell, foe.cell)[0].crit_chance, 100)


func test_haste_adds_move_points() -> void:
	var haste := TestFixtures.status(StatusData.Kind.OTHER, 2)
	haste.move_bonus = 2
	foe.add_status(haste, 2)
	_turn_of(foe)
	assert_eq(foe.pm, foe.move_points + 2)


func test_vulnerable_targets_take_more_damage() -> void:
	_turn_of(hero)
	var normal := combat.preview_skill(hero, hero.data.skills[0], hero.cell, foe.cell)[0].damage
	var weak := TestFixtures.status(StatusData.Kind.OTHER, 2)
	weak.damage_taken_percent_bonus = 100
	foe.add_status(weak, 2)
	assert_eq(combat.preview_skill(hero, hero.data.skills[0], hero.cell, foe.cell)[0].damage, normal * 2)


func test_max_uses_per_turn() -> void:
	var jab := hero.data.skills[0]
	jab.max_uses_per_turn = 1
	hero.data.action_points = 3
	_turn_of(hero)
	combat.use_skill(jab, foe.cell)
	assert_false(combat.can_use_skill(hero, jab), "only once this turn")
	combat.end_turn(hero.facing)
	_turn_of(hero)
	assert_true(combat.can_use_skill(hero, jab), "again next turn")


func test_skill_needs_and_spends_charges() -> void:
	var rolling := TestFixtures.status(StatusData.Kind.OTHER, 2)
	rolling.max_stacks = 3
	var bomb := TestFixtures.skill(10, 1, 9)
	bomb.requires_status = rolling
	bomb.requires_stacks = 2
	hero.data.skills.append(bomb)
	_turn_of(hero)
	assert_false(combat.can_use_skill(hero, bomb))
	hero.add_status(rolling, 2)
	hero.add_status(rolling, 2)
	assert_true(combat.can_use_skill(hero, bomb))
	combat.use_skill(bomb, foe.cell)
	assert_false(hero.has_status(rolling), "both charges spent")


func test_single_target_heal_reaches_across_the_map() -> void:
	var far := combat.add_unit(TestFixtures.unit_data("Far", 1), UnitState.Team.PLAYER, Vector2i(11, 0))
	far.hp = 20
	var mend := TestFixtures.skill(0, 1, 30)
	mend.target_rule = SkillData.TargetRule.ALLY_UNIT
	mend.heal_percent = 30
	mend.vertical_reach = 30
	hero.data.skills.append(mend)
	_turn_of(hero)
	var cells := combat.get_targetable_cells(hero, mend, hero.cell)
	assert_has(cells, far.cell)
	assert_not_has(cells, foe.cell, "never on enemies")
	combat.use_skill(mend, far.cell)
	assert_eq(far.hp, 50)


func test_healer_ai_heals_the_wounded_and_hastes_otherwise() -> void:
	var data := TestFixtures.unit_data("Healer", 30)
	var mend := TestFixtures.skill(0, 1, 30)
	mend.target_rule = SkillData.TargetRule.ALLY_UNIT
	mend.heal_percent = 30
	mend.vertical_reach = 30
	var haste := TestFixtures.status(StatusData.Kind.OTHER, 2)
	haste.move_bonus = 2
	var breeze := TestFixtures.skill(0, 1, 30)
	breeze.target_rule = SkillData.TargetRule.ALLY_UNIT
	breeze.ally_status = haste
	breeze.vertical_reach = 30
	data.skills = [mend, breeze]
	data.action_points = 1
	var healer := combat.add_unit(data, UnitState.Team.ENEMY, Vector2i(0, 11))
	foe.hp = 30
	_turn_of(healer)
	_play_turn(healer)
	assert_eq(foe.hp, 60, "heals the wounded ally first")
	combat.end_turn(healer.facing)
	foe.hp = foe.max_hp
	_turn_of(healer)
	_play_turn(healer)
	assert_true(foe.has_status(haste), "nobody to heal: hastes")


func test_roll_crosses_the_map_over_walls_and_hits_a_wide_band() -> void:
	var rows := PackedStringArray()
	var heights := PackedStringArray()
	for y in 9:
		rows.append("ggggggggg")
		heights.append("000090000" if y == 4 else "000000000")
	combat = CombatState.new(TestFixtures.grid(rows, heights), TestFixtures.rules(), 8)
	var data := TestFixtures.unit_data("Ent", 20)
	var roll := TestFixtures.skill(6, 1, 1)
	roll.motion = SkillData.Motion.ROLL
	roll.area_size = 2
	roll.vertical_reach = 99
	data.skills = [roll]
	var ent := combat.add_unit(data, UnitState.Team.ENEMY, Vector2i(0, 4))
	var in_band := combat.add_unit(TestFixtures.unit_data("A", 1), UnitState.Team.PLAYER, Vector2i(6, 2))
	var outside := combat.add_unit(TestFixtures.unit_data("B", 1), UnitState.Team.PLAYER, Vector2i(6, 7))
	_turn_of(ent)
	var effective := combat.get_effective(ent, roll)
	assert_eq(combat.get_landing_cell(ent, effective, ent.cell, Vector2i(1, 4)), Vector2i(8, 4), "over the pillar to the edge")
	var targets := combat.get_skill_targets(ent, effective, ent.cell, Vector2i(1, 4))
	assert_has(targets, in_band)
	assert_not_has(targets, outside)
	combat.use_skill(roll, Vector2i(1, 4))
	assert_eq(ent.cell, Vector2i(8, 4))
