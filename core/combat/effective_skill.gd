class_name EffectiveSkill
extends RefCounted
## A skill after rage mutation and modifiers have been applied by
## ResolutionPipeline. Everything the combat needs (targeting, costs, preview,
## resolution) reads from here, never from the raw SkillData.

## The equipped skill (key for cooldowns and UI).
var base: SkillData
## The skill actually used (base or its empowered variant).
var source: SkillData
var empowered: bool = false

var display_name: String
var tags: Array[StringName] = []
var skill_type: SkillData.SkillType

var ap_cost: int
var mp_cost: int
var rage_cost: int
var cooldown: int

var target_rule: SkillData.TargetRule
var range_min: int
var range_max: int
var vertical_reach: int
var requires_straight_line: bool
var area_shape: AreaShape.Shape
var area_size: int

var power: int
var affects_allies: bool
var motion: SkillData.Motion
var knockback: int
var crit_bonus: int
var strikes: int = 1
var self_status: StatusData

# Numeric modifiers (stage 2)
var damage_flat: int = 0
var damage_percent: int = 0
var rage_on_hit: int = 0

# Behaviours (stages 1, 3 and 4). 0 = not present.
var bounce_hops: int = 0
var explode_percent: int = 0
var explode_radius: int = 0
var lifesteal_percent: int = 0
var refund_ap: int = 0
## Statuses applied on every landed hit (skill + ALWAYS modifiers).
var statuses: Array[StatusApplication] = []
var summon: UnitData
var vfx_style: SkillData.VfxStyle = SkillData.VfxStyle.AUTO
var vfx_color: Color = Color.WHITE

## Modifiers whose trigger is evaluated per hit (ON_BACK_ATTACK, ON_CRIT, ON_KILL).
var conditional: Array[ModifierData] = []
## Every modifier that touched this skill (for tooltips).
var applied: Array[ModifierData] = []


static func from_skill(base_skill: SkillData, used: SkillData) -> EffectiveSkill:
	var e := EffectiveSkill.new()
	e.base = base_skill
	e.source = used
	e.empowered = used != base_skill
	e.display_name = used.display_name
	e.tags = used.tags.duplicate()
	e.skill_type = used.skill_type
	e.ap_cost = used.ap_cost
	e.mp_cost = used.mp_cost
	e.rage_cost = used.rage_cost
	e.cooldown = used.cooldown
	e.target_rule = used.target_rule
	e.range_min = used.range_min
	e.range_max = used.range_max
	e.vertical_reach = used.vertical_reach
	e.requires_straight_line = used.requires_straight_line
	e.area_shape = used.area_shape
	e.area_size = used.area_size
	e.power = used.power
	e.affects_allies = used.affects_allies
	e.motion = used.motion
	e.knockback = used.knockback
	e.crit_bonus = used.crit_bonus
	e.strikes = used.strikes
	e.lifesteal_percent = used.lifesteal_percent
	e.self_status = used.self_status
	if used.status != null:
		e.statuses.append(StatusApplication.create(used.status, used.status_chance, used.status_duration))
	e.summon = used.summon as UnitData
	e.vfx_style = used.vfx_style
	e.vfx_color = used.vfx_color
	return e


## Resolves AUTO into a concrete style.
func get_vfx_style() -> SkillData.VfxStyle:
	if vfx_style != SkillData.VfxStyle.AUTO:
		return vfx_style
	if target_rule == SkillData.TargetRule.SELF:
		return SkillData.VfxStyle.NOVA
	if not deals_damage():
		return SkillData.VfxStyle.NONE
	if area_size > 0 and range_max >= 2:
		return SkillData.VfxStyle.LOB
	if has_tag(&"proyectil"):
		return SkillData.VfxStyle.PROJECTILE
	return SkillData.VfxStyle.SLASH


func deals_damage() -> bool:
	return power > 0


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


## Short cost text for buttons: "1 PA · 20 Ira".
func get_cost_text() -> String:
	var parts := PackedStringArray(["%d PA" % ap_cost])
	if mp_cost > 0:
		parts.append("%d MP" % mp_cost)
	if rage_cost > 0:
		parts.append("%d Ira" % rage_cost)
	if cooldown > 0:
		parts.append("CD %d" % cooldown)
	return " · ".join(parts)
