extends TestCase
## Movement skills (GDD §4) and on-impact effects (GDD §5 stage 3-4).

var combat: CombatState
var user: UnitState


func before_each() -> void:
	combat = CombatState.new(TestFixtures.flat_grid(8, 8), TestFixtures.rules(), 3)
	user = combat.add_unit(TestFixtures.unit_data("User", 30), UnitState.Team.PLAYER, Vector2i(1, 4))


func _foe(cell: Vector2i, facing := GridDir.Dir.WEST) -> UnitState:
	var data := TestFixtures.unit_data("Foe", 1)
	data.max_hp = 999
	return combat.add_unit(data, UnitState.Team.ENEMY, cell, facing)


func _skill(motion: SkillData.Motion, rule: SkillData.TargetRule, range_max: int, power := 10) -> SkillData:
	var s := TestFixtures.skill(power, 1, range_max)
	s.motion = motion
	s.target_rule = rule
	s.vertical_reach = 9
	user.data.skills.append(s)
	return s


func test_teleport_moves_to_empty_cell_only() -> void:
	var foe := _foe(Vector2i(4, 4))
	var blink := _skill(SkillData.Motion.TELEPORT, SkillData.TargetRule.EMPTY_CELL, 4, 0)
	combat.start_next_turn()
	var cells := combat.get_targetable_cells(user, blink, user.cell)
	assert_not_has(cells, foe.cell)
	assert_has(cells, Vector2i(4, 3))
	var result := combat.use_skill(blink, Vector2i(4, 3))
	assert_eq(user.cell, Vector2i(4, 3))
	assert_true(result.user_moved())


func test_charge_stops_next_to_target_in_a_line() -> void:
	var foe := _foe(Vector2i(5, 4))
	var charge := _skill(SkillData.Motion.CHARGE, SkillData.TargetRule.ENEMY_UNIT, 5)
	charge.requires_straight_line = true
	combat.start_next_turn()
	assert_has(combat.get_targetable_cells(user, charge, user.cell), foe.cell)
	combat.use_skill(charge, foe.cell)
	assert_eq(user.cell, Vector2i(4, 4))
	assert_true(foe.hp < foe.max_hp)


func test_charge_is_blocked_by_units_in_the_way() -> void:
	var foe := _foe(Vector2i(5, 4))
	_foe(Vector2i(3, 4))
	var charge := _skill(SkillData.Motion.CHARGE, SkillData.TargetRule.ENEMY_UNIT, 5)
	combat.start_next_turn()
	assert_not_has(combat.get_targetable_cells(user, charge, user.cell), foe.cell)


func test_behind_target_lands_on_its_back_and_backstabs() -> void:
	var foe := _foe(Vector2i(4, 4), GridDir.Dir.NORTH)
	var shadow_step := _skill(SkillData.Motion.BEHIND_TARGET, SkillData.TargetRule.ENEMY_UNIT, 5)
	combat.start_next_turn()
	var result := combat.use_skill(shadow_step, foe.cell)
	assert_eq(user.cell, Vector2i(4, 5), "south of a unit facing north")
	assert_eq(result.hits[0].side, GridRules.AttackSide.BACK)


func test_behind_target_needs_a_free_back() -> void:
	var foe := _foe(Vector2i(4, 4), GridDir.Dir.NORTH)
	_foe(Vector2i(4, 5))
	var shadow_step := _skill(SkillData.Motion.BEHIND_TARGET, SkillData.TargetRule.ENEMY_UNIT, 5)
	combat.start_next_turn()
	assert_not_has(combat.get_targetable_cells(user, shadow_step, user.cell), foe.cell)


func test_knockback_pushes_away_and_stops_at_obstacles() -> void:
	var foe := _foe(Vector2i(2, 4))
	var shove := _skill(SkillData.Motion.NONE, SkillData.TargetRule.ANY, 1)
	shove.knockback = 2
	combat.start_next_turn()
	var result := combat.use_skill(shove, foe.cell)
	assert_eq(foe.cell, Vector2i(4, 4))
	assert_eq(result.hits[0].pushed_to, Vector2i(4, 4))


func test_bounce_hits_extra_enemies_up_to_the_limit() -> void:
	var a := _foe(Vector2i(3, 4))
	var b := _foe(Vector2i(4, 4))
	var c := _foe(Vector2i(5, 4))
	var d := _foe(Vector2i(6, 4))
	var shot := _skill(SkillData.Motion.NONE, SkillData.TargetRule.ANY, 3)
	user.modifiers = [TestFixtures.modifier(ModifierData.Effect.BOUNCE, 1, &"", 2)]
	combat.start_next_turn()
	var result := combat.use_skill(shot, a.cell)
	assert_eq(result.hits.size(), 3, "primary + 2 hops")
	for foe in [a, b, c]:
		assert_true(foe.hp < foe.max_hp)
	assert_eq(d.hp, d.max_hp, "limit respected")


func test_explosion_splashes_neighbours() -> void:
	var a := _foe(Vector2i(3, 4))
	var b := _foe(Vector2i(3, 5))
	var shot := _skill(SkillData.Motion.NONE, SkillData.TargetRule.ANY, 3)
	user.modifiers = [TestFixtures.modifier(ModifierData.Effect.EXPLODE, 50, &"", 1)]
	combat.start_next_turn()
	var result := combat.use_skill(shot, a.cell)
	assert_eq(result.hits.size(), 2)
	assert_eq(result.hits[1].source, SkillResult.HitSource.EXPLOSION)
	assert_true(b.hp < b.max_hp)


func test_lifesteal_heals_the_user() -> void:
	var foe := _foe(Vector2i(2, 4))
	var bite := _skill(SkillData.Motion.NONE, SkillData.TargetRule.ANY, 1, 30)
	user.modifiers = [TestFixtures.modifier(ModifierData.Effect.LIFESTEAL, 50)]
	user.hp = 10
	combat.start_next_turn()
	var result := combat.use_skill(bite, foe.cell)
	assert_true(result.hits[0].healed > 0)
	assert_eq(user.hp, 10 + result.hits[0].healed)


func test_kill_refunds_ap_once_per_turn() -> void:
	var a := _foe(Vector2i(2, 4))
	a.hp = 1
	var stab := _skill(SkillData.Motion.NONE, SkillData.TargetRule.ANY, 1)
	user.modifiers = [TestFixtures.modifier(ModifierData.Effect.REFUND_AP, 1, &"", 1, ModifierData.Trigger.ON_KILL)]
	_foe(Vector2i(6, 6))
	combat.start_next_turn()
	var before := user.pa
	var result := combat.use_skill(stab, a.cell)
	assert_eq(result.refunded_ap, 1)
	assert_eq(user.pa, before)
