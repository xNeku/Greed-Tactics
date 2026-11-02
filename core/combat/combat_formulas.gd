class_name CombatFormulas
extends RefCounted
## Damage, hit and crit formulas. Pure functions: easy to test and to balance.
## The modifier pipeline (GDD §5, M1) will hook in between these steps.


static func build_preview(
		rules: RulesConfig,
		user: UnitState,
		skill: SkillData,
		target: UnitState,
		side: GridRules.AttackSide) -> AttackPreview:
	var preview := AttackPreview.new()
	preview.target = target
	preview.side = side
	preview.damage = compute_damage(rules, user, skill, target, side)
	preview.crit_damage = maxi(roundi(preview.damage * rules.crit_multiplier), rules.min_damage)
	preview.hit_chance = compute_hit_chance(rules, target, side)
	preview.crit_chance = compute_crit_chance(rules, user, side)
	return preview


static func compute_damage(
		rules: RulesConfig,
		user: UnitState,
		skill: SkillData,
		target: UnitState,
		side: GridRules.AttackSide) -> int:
	var base := skill.power + user.data.attack - target.data.defense
	var multiplier := 1.0
	match side:
		GridRules.AttackSide.SIDE:
			multiplier = rules.side_damage_multiplier
		GridRules.AttackSide.BACK:
			multiplier = rules.back_damage_multiplier
	return maxi(roundi(base * multiplier), rules.min_damage)


static func compute_hit_chance(rules: RulesConfig, target: UnitState, side: GridRules.AttackSide) -> int:
	var evasion_factor := 1.0
	match side:
		GridRules.AttackSide.SIDE:
			evasion_factor = rules.side_evasion_factor
		GridRules.AttackSide.BACK:
			evasion_factor = rules.back_evasion_factor
	var chance := 100 - roundi(target.data.evasion * evasion_factor)
	return clampi(chance, rules.min_hit_chance, rules.max_hit_chance)


static func compute_crit_chance(rules: RulesConfig, user: UnitState, side: GridRules.AttackSide) -> int:
	var chance := user.data.crit_chance
	if side == GridRules.AttackSide.BACK:
		chance += rules.back_crit_bonus
	return clampi(chance, 0, 100)
