extends TestCase
## Status effects: burn/poison damage over time, slow, stun, silence, and how
## skills and modifiers apply them.

var combat: CombatState
var hero: UnitState
var foe: UnitState


func before_each() -> void:
	combat = CombatState.new(TestFixtures.flat_grid(8, 8), TestFixtures.rules(), 5)
	hero = combat.add_unit(TestFixtures.unit_data("Hero", 20), UnitState.Team.PLAYER, Vector2i(2, 2))
	foe = combat.add_unit(TestFixtures.unit_data("Foe", 10), UnitState.Team.ENEMY, Vector2i(2, 3))


func _turn_of(unit: UnitState) -> UnitState:
	for i in 50:
		var current := combat.start_next_turn()
		if current == unit:
			return current
		combat.end_turn(current.facing)
	return null


func test_burn_deals_damage_at_turn_start_and_expires() -> void:
	foe.add_status(TestFixtures.status(StatusData.Kind.BURN, 2), 2)
	_turn_of(foe)
	assert_eq(foe.hp, foe.max_hp - 10)
	assert_eq(combat.last_status_events.size(), 1)
	assert_eq(combat.last_status_events[0].damage, 10)
	combat.end_turn(foe.facing)
	_turn_of(foe)
	assert_eq(foe.hp, foe.max_hp - 20)
	assert_true(combat.last_status_events[0].expired)
	assert_true(foe.statuses.is_empty())


func test_poison_can_kill_and_ends_the_combat() -> void:
	foe.hp = 3
	foe.add_status(TestFixtures.status(StatusData.Kind.POISON), 2)
	_turn_of(foe)
	assert_false(foe.is_alive())
	assert_true(foe.skip_turn)
	assert_true(combat.is_finished())


func test_slow_reduces_pm_and_speed() -> void:
	var slow := TestFixtures.status(StatusData.Kind.SLOW)
	foe.add_status(slow, 2)
	assert_eq(foe.get_current_speed(), 5)
	_turn_of(foe)
	assert_eq(foe.pm, foe.move_points - 2)


func test_stun_skips_the_turn() -> void:
	foe.add_status(TestFixtures.status(StatusData.Kind.STUN, 1), 1)
	_turn_of(foe)
	assert_true(foe.skip_turn)
	assert_eq(foe.pa, 0)
	assert_eq(foe.pm, 0)
	combat.end_turn(foe.facing)
	_turn_of(foe)
	assert_false(foe.skip_turn, "only one turn lost")


func test_silence_only_allows_basic_skills() -> void:
	var special := TestFixtures.skill(20)
	special.skill_type = SkillData.SkillType.AREA
	hero.data.skills.append(special)
	hero.add_status(TestFixtures.status(StatusData.Kind.SILENCE), 2)
	_turn_of(hero)
	assert_true(combat.can_use_skill(hero, hero.data.skills[0]), "basic still works")
	assert_false(combat.can_use_skill(hero, special))


func test_skill_applies_its_status_on_hit() -> void:
	var burn := TestFixtures.status(StatusData.Kind.BURN)
	var skill := hero.data.skills[0]
	skill.status = burn
	skill.status_chance = 100
	_turn_of(hero)
	var preview := combat.preview_skill(hero, skill, hero.cell, foe.cell)[0]
	assert_eq(preview.statuses.size(), 1, "the forecast shows the status")
	var result := combat.use_skill(skill, foe.cell)
	assert_has(result.hits[0].applied_statuses, burn)
	assert_true(foe.has_status(burn))


func test_modifier_applies_status_on_crit_only() -> void:
	var stun := TestFixtures.status(StatusData.Kind.STUN, 1)
	var mod := TestFixtures.modifier(ModifierData.Effect.APPLY_STATUS, 100, &"", 1, ModifierData.Trigger.ON_CRIT)
	mod.status = stun
	var effective := ResolutionPipeline.build(hero.data.skills[0], 0, [mod])
	assert_eq(ResolutionPipeline.get_impact_effects(effective, GridRules.AttackSide.FRONT, false).statuses.size(), 0)
	assert_eq(ResolutionPipeline.get_impact_effects(effective, GridRules.AttackSide.FRONT, true).statuses.size(), 1)


func test_reapplying_refreshes_instead_of_stacking() -> void:
	var burn := TestFixtures.status(StatusData.Kind.BURN)
	foe.add_status(burn, 1)
	foe.add_status(burn, 3)
	foe.add_status(burn, 2)
	assert_eq(foe.statuses[burn], 3)
	assert_eq(foe.statuses.size(), 1)


func test_stacking_status_adds_charges_up_to_the_cap() -> void:
	var toxin := TestFixtures.status(StatusData.Kind.POISON, 3)
	toxin.max_stacks = 3
	for i in 5:
		foe.add_status(toxin, 3)
	assert_eq(foe.get_stacks(toxin), 3, "capped at max_stacks")
	assert_eq(foe.statuses.size(), 1)


func test_charges_multiply_damage_over_time() -> void:
	var toxin := TestFixtures.status(StatusData.Kind.POISON, 3)  # 5 flat per charge
	toxin.max_stacks = 6
	foe.add_status(toxin, 3)
	foe.add_status(toxin, 3)
	foe.add_status(toxin, 3)
	_turn_of(foe)
	assert_eq(combat.last_status_events[0].stacks, 3)
	assert_eq(foe.hp, foe.max_hp - 15)


func test_each_strike_adds_a_charge_and_forecast_shows_it() -> void:
	var toxin := TestFixtures.status(StatusData.Kind.POISON, 3)
	toxin.max_stacks = 6
	var skill := hero.data.skills[0]
	skill.status = toxin
	skill.strikes = 2
	_turn_of(hero)
	combat.use_skill(skill, foe.cell)
	assert_eq(foe.get_stacks(toxin), 2)


func test_charges_vanish_when_the_status_expires() -> void:
	var toxin := TestFixtures.status(StatusData.Kind.POISON, 1)
	toxin.max_stacks = 6
	foe.add_status(toxin, 1)
	foe.add_status(toxin, 1)
	_turn_of(foe)
	assert_eq(foe.get_stacks(toxin), 0)
	assert_true(foe.status_stacks.is_empty())


func test_extra_statuses_are_applied_with_the_main_one() -> void:
	var toxin := TestFixtures.status(StatusData.Kind.POISON)
	var taunt := TestFixtures.status(StatusData.Kind.OTHER)
	taunt.taunts = true
	var skill := hero.data.skills[0]
	skill.status = toxin
	skill.extra_statuses = [taunt]
	_turn_of(hero)
	combat.use_skill(skill, foe.cell)
	assert_true(foe.has_status(toxin))
	assert_true(foe.has_status(taunt))
	assert_eq(foe.get_taunter(), hero, "the taunt remembers who applied it")


func test_taunt_is_forgotten_when_it_expires_or_the_taunter_dies() -> void:
	var taunt := TestFixtures.status(StatusData.Kind.OTHER, 1)
	taunt.taunts = true
	foe.add_status(taunt, 1, hero)
	assert_eq(foe.get_taunter(), hero)
	hero.hp = 0
	assert_null(foe.get_taunter(), "dead taunters do not count")
	hero.hp = 10
	_turn_of(foe)
	assert_null(foe.get_taunter())
