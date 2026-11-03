class_name CombatFormulas
extends RefCounted
## Damage, hit and crit formulas. Pure functions: easy to test and to balance.
## Modifier bonuses arrive already folded into the EffectiveSkill
## (ResolutionPipeline) plus per-hit conditional bonuses.


static func build_preview(
		rules: RulesConfig,
		user: UnitState,
		skill: EffectiveSkill,
		target: UnitState,
		side: GridRules.AttackSide,
		height_diff: int) -> AttackPreview:
	var bonus := ResolutionPipeline.get_hit_bonuses(skill, side)
	var preview := AttackPreview.new()
	preview.target = target
	preview.side = side
	preview.damage = compute_damage(rules, user, skill, target, side, height_diff, bonus)
	preview.crit_damage = maxi(roundi(preview.damage * rules.crit_multiplier), rules.min_damage)
	preview.hit_chance = compute_hit_chance(rules, target, side)
	preview.crit_chance = clampi(compute_crit_chance(rules, user, skill, side) + bonus.crit, 0, 100)
	preview.bounces = skill.bounce_hops
	preview.strikes = skill.strikes
	preview.knockback = ResolutionPipeline.get_impact_effects(skill, side, false).knockback
	return preview


## [param height_diff] = user height - target height (levels).
static func compute_damage(
		rules: RulesConfig,
		user: UnitState,
		skill: EffectiveSkill,
		target: UnitState,
		side: GridRules.AttackSide,
		height_diff: int = 0,
		hit_bonus: Dictionary = {}) -> int:
	if not skill.deals_damage():
		return 0
	var base := skill.power + user.attack - target.get_defense() + skill.damage_flat + int(hit_bonus.get("damage_flat", 0))
	var multiplier := 1.0
	match side:
		GridRules.AttackSide.SIDE:
			multiplier = rules.side_damage_multiplier
		GridRules.AttackSide.BACK:
			multiplier = rules.back_damage_multiplier
	multiplier *= 1.0 + (skill.damage_percent + int(hit_bonus.get("damage_percent", 0))) / 100.0
	multiplier *= 1.0 + maxi(height_diff, 0) * rules.height_damage_bonus
	if user.uses_rage():
		multiplier *= 1.0 + user.rage * rules.rage_damage_bonus
	multiplier *= maxf(1.0 + user.get_damage_bonus_percent() / 100.0, 0.1)
	return maxi(roundi(base * multiplier), rules.min_damage)


static func compute_hit_chance(rules: RulesConfig, target: UnitState, side: GridRules.AttackSide) -> int:
	var evasion_factor := 1.0
	match side:
		GridRules.AttackSide.SIDE:
			evasion_factor = rules.side_evasion_factor
		GridRules.AttackSide.BACK:
			evasion_factor = rules.back_evasion_factor
	var chance := 100 - roundi(target.evasion * evasion_factor)
	return clampi(chance, rules.min_hit_chance, rules.max_hit_chance)


static func compute_crit_chance(rules: RulesConfig, user: UnitState, skill: EffectiveSkill, side: GridRules.AttackSide) -> int:
	var chance := user.crit_chance + skill.crit_bonus
	if side == GridRules.AttackSide.BACK:
		chance += rules.back_crit_bonus
	return clampi(chance, 0, 100)


## Rage a unit gains when it takes [param damage].
static func rage_from_damage_taken(rules: RulesConfig, unit: UnitState, damage: int) -> int:
	return rules.rage_on_hit_taken + roundi(float(damage) / unit.max_hp * rules.rage_per_max_hp_taken)
