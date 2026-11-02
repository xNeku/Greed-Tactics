class_name ResolutionPipeline
extends RefCounted
## Applies modifiers to a skill in the FIXED order of GDD §5:
##   1. Shape and trajectory (range, area, bounce).
##   2. Numeric (damage, cost, crit, rage).
##   3. On impact (explode, knockback, lifesteal).
##   4. Chains (bounce hops), always capped by the modifier limit.
## Rules:
##   - Numeric modifiers stack without limit.
##   - Behaviour modifiers are taken once: the one with the highest value/limit wins.
##   - Incompatible modifiers (ModifierData.incompatible_with) never coexist:
##     the one acquired first is kept.
## Conditional triggers (back attack, crit, kill) are stored and evaluated per hit
## by CombatState with [method apply_hit_modifiers] / [method get_kill_effects].

const STAGE_SHAPE: Array[ModifierData.Effect] = [
	ModifierData.Effect.RANGE, ModifierData.Effect.AREA_SIZE, ModifierData.Effect.BOUNCE,
]
const STAGE_NUMERIC: Array[ModifierData.Effect] = [
	ModifierData.Effect.DAMAGE_FLAT, ModifierData.Effect.DAMAGE_PERCENT,
	ModifierData.Effect.COST_REDUCTION, ModifierData.Effect.CRIT_CHANCE, ModifierData.Effect.RAGE_ON_HIT,
]
const STAGE_IMPACT: Array[ModifierData.Effect] = [
	ModifierData.Effect.EXPLODE, ModifierData.Effect.KNOCKBACK, ModifierData.Effect.LIFESTEAL,
]


## Builds the effective version of [param base_skill] for a unit with
## [param rage] rage and the given [param modifiers].
static func build(base_skill: SkillData, rage: int, modifiers: Array[ModifierData]) -> EffectiveSkill:
	var used := base_skill
	var variant := base_skill.empowered_variant
	if variant != null and rage >= base_skill.empowered_rage_threshold:
		used = variant
	var skill := EffectiveSkill.from_skill(base_skill, used)

	var active := filter_compatible(modifiers).filter(
		func(m: ModifierData) -> bool: return m.applies_to(used))
	for stage in [STAGE_SHAPE, STAGE_NUMERIC, STAGE_IMPACT]:
		for modifier: ModifierData in active:
			if not stage.has(modifier.effect):
				continue
			if modifier.trigger != ModifierData.Trigger.ALWAYS:
				continue
			_apply(skill, modifier)
			skill.applied.append(modifier)
	for modifier: ModifierData in active:
		if modifier.trigger != ModifierData.Trigger.ALWAYS or modifier.effect == ModifierData.Effect.REFUND_AP:
			skill.conditional.append(modifier)
			if not skill.applied.has(modifier):
				skill.applied.append(modifier)
	return skill


## Drops modifiers incompatible with an earlier one in the list.
static func filter_compatible(modifiers: Array[ModifierData]) -> Array[ModifierData]:
	var kept: Array[ModifierData] = []
	for modifier in modifiers:
		if kept.all(func(k: ModifierData) -> bool: return k.is_compatible_with(modifier)):
			kept.append(modifier)
	return kept


## Per-hit numeric bonuses from conditional modifiers. Returns
## {"damage_flat": int, "damage_percent": int, "crit": int}.
static func get_hit_bonuses(skill: EffectiveSkill, side: GridRules.AttackSide) -> Dictionary:
	var bonus := {"damage_flat": 0, "damage_percent": 0, "crit": 0}
	for modifier in skill.conditional:
		if modifier.trigger != ModifierData.Trigger.ON_BACK_ATTACK or side != GridRules.AttackSide.BACK:
			continue
		match modifier.effect:
			ModifierData.Effect.DAMAGE_FLAT:
				bonus.damage_flat += modifier.value
			ModifierData.Effect.DAMAGE_PERCENT:
				bonus.damage_percent += modifier.value
			ModifierData.Effect.CRIT_CHANCE:
				bonus.crit += modifier.value
	return bonus


## Behaviours that trigger on a landed hit ([param critical] / [param side]).
## Returns {"explode_percent", "explode_radius", "knockback", "lifesteal"}
## merged with the skill's unconditional behaviours (highest wins).
static func get_impact_effects(skill: EffectiveSkill, side: GridRules.AttackSide, critical: bool) -> Dictionary:
	var fx := {
		"explode_percent": skill.explode_percent,
		"explode_radius": skill.explode_radius,
		"knockback": skill.knockback,
		"lifesteal": skill.lifesteal_percent,
	}
	for modifier in skill.conditional:
		var fires := (modifier.trigger == ModifierData.Trigger.ON_CRIT and critical) \
			or (modifier.trigger == ModifierData.Trigger.ON_BACK_ATTACK and side == GridRules.AttackSide.BACK)
		if not fires:
			continue
		match modifier.effect:
			ModifierData.Effect.EXPLODE:
				fx.explode_percent = maxi(fx.explode_percent, modifier.value)
				fx.explode_radius = maxi(fx.explode_radius, modifier.limit)
			ModifierData.Effect.KNOCKBACK:
				fx.knockback = maxi(fx.knockback, modifier.value)
			ModifierData.Effect.LIFESTEAL:
				fx.lifesteal = maxi(fx.lifesteal, modifier.value)
	return fx


## PA refunded when the skill defeats a target, and how many times per turn.
static func get_kill_refund(skill: EffectiveSkill) -> Vector2i:
	var best := Vector2i.ZERO
	for modifier in skill.conditional:
		if modifier.effect == ModifierData.Effect.REFUND_AP and modifier.trigger == ModifierData.Trigger.ON_KILL:
			best = Vector2i(maxi(best.x, modifier.value), maxi(best.y, modifier.limit))
	return best


static func _apply(skill: EffectiveSkill, modifier: ModifierData) -> void:
	var v := modifier.value
	match modifier.effect:
		ModifierData.Effect.RANGE:
			if skill.target_rule != SkillData.TargetRule.SELF:
				skill.range_max += v
		ModifierData.Effect.AREA_SIZE:
			if skill.area_shape == AreaShape.Shape.SINGLE:
				skill.area_shape = AreaShape.Shape.DIAMOND
			skill.area_size += v
		ModifierData.Effect.BOUNCE:
			skill.bounce_hops = maxi(skill.bounce_hops, modifier.limit)
		ModifierData.Effect.DAMAGE_FLAT:
			skill.damage_flat += v
		ModifierData.Effect.DAMAGE_PERCENT:
			skill.damage_percent += v
		ModifierData.Effect.COST_REDUCTION:
			skill.mp_cost = maxi(skill.mp_cost - v, 0)
			skill.rage_cost = maxi(skill.rage_cost - v, 0)
			skill.cooldown = maxi(skill.cooldown - floori(v / 10.0), 0)
		ModifierData.Effect.CRIT_CHANCE:
			skill.crit_bonus += v
		ModifierData.Effect.RAGE_ON_HIT:
			skill.rage_on_hit += v
		ModifierData.Effect.EXPLODE:
			if v > skill.explode_percent:
				skill.explode_percent = v
			skill.explode_radius = maxi(skill.explode_radius, modifier.limit)
		ModifierData.Effect.KNOCKBACK:
			skill.knockback = maxi(skill.knockback, v)
		ModifierData.Effect.LIFESTEAL:
			skill.lifesteal_percent = maxi(skill.lifesteal_percent, v)
