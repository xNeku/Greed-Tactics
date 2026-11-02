extends TestCase
## ResolutionPipeline (GDD §5): fixed order, numeric stacking, behaviours
## taken once, incompatibilities, tag targeting and conditional triggers.

const E := ModifierData.Effect

var skill: SkillData


func before_each() -> void:
	skill = TestFixtures.skill(10, 2, 4)
	skill.tags = [&"lanzamiento", &"proyectil"]


func _build(mods: Array[ModifierData], rage: int = 0) -> EffectiveSkill:
	return ResolutionPipeline.build(skill, rage, mods)


func test_without_modifiers_mirrors_the_skill() -> void:
	var e := _build([])
	assert_eq(e.power, 10)
	assert_eq(e.range_max, 4)
	assert_false(e.empowered)


func test_numeric_modifiers_stack() -> void:
	var e := _build([TestFixtures.modifier(E.RANGE, 1), TestFixtures.modifier(E.RANGE, 1, &"", 1, ModifierData.Trigger.ALWAYS, &"other")])
	assert_eq(e.range_max, 6, "two +1 range add up")
	e = _build([TestFixtures.modifier(E.DAMAGE_FLAT, 3), TestFixtures.modifier(E.DAMAGE_FLAT, 4, &"", 1, ModifierData.Trigger.ALWAYS, &"b")])
	assert_eq(e.damage_flat, 7)


func test_behaviours_do_not_stack_highest_limit_wins() -> void:
	var small := TestFixtures.modifier(E.BOUNCE, 1, &"", 2, ModifierData.Trigger.ALWAYS, &"bounce_small")
	var big := TestFixtures.modifier(E.BOUNCE, 1, &"", 3, ModifierData.Trigger.ALWAYS, &"bounce_big")
	assert_eq(_build([small, big]).bounce_hops, 3)
	assert_eq(_build([big, small]).bounce_hops, 3)


func test_modifiers_only_apply_to_their_tag() -> void:
	var e := _build([TestFixtures.modifier(E.DAMAGE_FLAT, 5, &"melee")])
	assert_eq(e.damage_flat, 0)
	e = _build([TestFixtures.modifier(E.DAMAGE_FLAT, 5, &"proyectil")])
	assert_eq(e.damage_flat, 5)


func test_incompatible_modifiers_keep_the_first() -> void:
	var a := TestFixtures.modifier(E.BOUNCE, 1, &"", 2, ModifierData.Trigger.ALWAYS, &"bounce")
	var b := TestFixtures.modifier(E.EXPLODE, 50, &"", 1, ModifierData.Trigger.ALWAYS, &"explode")
	b.incompatible_with = [&"bounce"]
	var e := _build([a, b])
	assert_eq(e.bounce_hops, 2)
	assert_eq(e.explode_percent, 0, "explode is incompatible with bounce")
	assert_eq(ResolutionPipeline.filter_compatible([b, a] as Array[ModifierData]), [b] as Array[ModifierData])


func test_area_modifier_turns_single_into_diamond() -> void:
	var e := _build([TestFixtures.modifier(E.AREA_SIZE, 1)])
	assert_eq(e.area_shape, AreaShape.Shape.DIAMOND)
	assert_eq(e.area_size, 1)


func test_cost_reduction_never_goes_negative() -> void:
	skill.mp_cost = 4
	skill.cooldown = 2
	var e := _build([TestFixtures.modifier(E.COST_REDUCTION, 10)])
	assert_eq(e.mp_cost, 0)
	assert_eq(e.cooldown, 1)


func test_conditional_triggers_are_deferred() -> void:
	var back_crit := TestFixtures.modifier(E.CRIT_CHANCE, 25, &"", 1, ModifierData.Trigger.ON_BACK_ATTACK)
	var e := _build([back_crit])
	assert_eq(e.crit_bonus, 0, "not applied statically")
	assert_eq(ResolutionPipeline.get_hit_bonuses(e, GridRules.AttackSide.BACK).crit, 25)
	assert_eq(ResolutionPipeline.get_hit_bonuses(e, GridRules.AttackSide.FRONT).crit, 0)


func test_explode_on_crit_only_fires_on_crit() -> void:
	var m := TestFixtures.modifier(E.EXPLODE, 40, &"", 1, ModifierData.Trigger.ON_CRIT)
	var e := _build([m])
	assert_eq(ResolutionPipeline.get_impact_effects(e, GridRules.AttackSide.FRONT, false).explode_percent, 0)
	assert_eq(ResolutionPipeline.get_impact_effects(e, GridRules.AttackSide.FRONT, true).explode_percent, 40)


func test_rage_threshold_swaps_to_empowered_variant() -> void:
	var data := TestFixtures.rage_unit_data()
	var strike := data.skills[0]
	assert_false(ResolutionPipeline.build(strike, 49, []).empowered)
	var e := ResolutionPipeline.build(strike, 50, [])
	assert_true(e.empowered)
	assert_eq(e.power, 30)
	assert_eq(e.base, strike, "cooldowns and UI keep using the equipped skill")


func test_modifiers_apply_to_the_empowered_variant() -> void:
	var data := TestFixtures.rage_unit_data()
	var e := ResolutionPipeline.build(data.skills[0], 80, [TestFixtures.modifier(E.DAMAGE_FLAT, 5, &"melee")])
	assert_eq(e.damage_flat, 5)
