class_name ModifierData
extends Resource
## A run modifier (GDD §5). Grammar: target tag + trigger + effect + limit + type.
## Applied by ResolutionPipeline in the fixed order of GDD §5.

## When the modifier acts.
enum Trigger {
	ALWAYS,          ## Every use of a matching skill.
	ON_BACK_ATTACK,  ## Per hit, only when the hit lands on the target's back.
	ON_CRIT,         ## Per hit, only on critical hits.
	ON_KILL,         ## When a matching skill defeats a target.
}

## What the modifier changes. The pipeline stage is derived from the effect.
enum Effect {
	# Stage 1 - shape and trajectory
	RANGE,           ## +value max range.
	AREA_SIZE,       ## +value area size (SINGLE becomes DIAMOND).
	BOUNCE,          ## Behaviour: after hitting, jumps to another enemy (limit = hops).
	# Stage 2 - numeric
	DAMAGE_FLAT,     ## +value damage.
	DAMAGE_PERCENT,  ## +value % damage.
	COST_REDUCTION,  ## -value mana / rage cost (and -1 cooldown per 10).
	CRIT_CHANCE,     ## +value crit chance.
	RAGE_ON_HIT,     ## +value rage per hit dealt.
	# Stage 3 - on impact
	EXPLODE,         ## Behaviour: value % of the hit damage to enemies around (limit = radius).
	KNOCKBACK,       ## Behaviour: push the target value cells.
	LIFESTEAL,       ## Behaviour: heal the user value % of the damage dealt.
	# On kill
	REFUND_AP,       ## Behaviour: get value PA back (limit = times per turn).
}

const BEHAVIOR_EFFECTS: Array[Effect] = [
	Effect.BOUNCE, Effect.EXPLODE, Effect.KNOCKBACK, Effect.LIFESTEAL, Effect.REFUND_AP,
]

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Skill tag this modifier applies to. Empty = every skill.
@export var target_tag: StringName = &""
@export var trigger: Trigger = Trigger.ALWAYS
@export var effect: Effect = Effect.DAMAGE_FLAT
@export var value: int = 1
## Cap for behaviours (hops, radius, times per turn). Ignored by numeric effects.
@export var limit: int = 1
## Ids of modifiers that cannot coexist with this one (incompatibility table).
@export var incompatible_with: Array[StringName] = []
## Relative chance to be offered.
@export_range(1, 100) var weight: int = 10


## Numeric modifiers stack; behaviour modifiers are taken once (highest wins).
func is_behavior() -> bool:
	return BEHAVIOR_EFFECTS.has(effect)


func applies_to(skill: SkillData) -> bool:
	return target_tag == &"" or skill.has_tag(target_tag)


func is_compatible_with(other: ModifierData) -> bool:
	return not incompatible_with.has(other.id) and not other.incompatible_with.has(id)
