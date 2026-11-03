class_name SkillInfoPanel
extends PanelContainer
## Card describing the selected skill (as it will really be used: rage
## mutation and modifiers included), so every rule is readable on screen.

const TYPE_NAMES := ["Básica", "Lanzamiento", "Área", "Movimiento"]
const SHAPE_NAMES := ["Casilla", "Rombo", "Cuadrado", "Cruz", "Línea"]
const MOTION_TEXT := ["", "Teletransporte a la casilla", "Carga en línea recta", "Aparece a la espalda del objetivo"]
const EMPOWERED_COLOR := Color(1.0, 0.55, 0.4)

@onready var _name_label: Label = %NameLabel
@onready var _type_label: Label = %TypeLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _effects_label: Label = %EffectsLabel
@onready var _modifiers_label: Label = %ModifiersLabel


func show_skill(skill: EffectiveSkill) -> void:
	visible = true
	_name_label.text = skill.display_name
	_name_label.modulate = EMPOWERED_COLOR if skill.empowered else Color.WHITE
	_type_label.text = "%s · %s · %s" % [TYPE_NAMES[skill.skill_type], skill.get_cost_text(),
		", ".join(skill.tags.map(func(t: StringName) -> String: return String(t)))]
	_description_label.text = skill.source.description

	var stats := PackedStringArray()
	if skill.target_rule == SkillData.TargetRule.SELF:
		stats.append("Sobre sí mismo")
	else:
		stats.append("Alcance %d-%d" % [skill.range_min, skill.range_max])
		stats.append("Altura ±%d" % skill.vertical_reach)
	if skill.area_size > 0:
		stats.append("%s %d" % [SHAPE_NAMES[skill.area_shape], skill.area_size])
	if skill.deals_damage():
		stats.append("Poder %d" % skill.power)
	_stats_label.text = " · ".join(stats)

	var effects := PackedStringArray()
	if skill.summon != null:
		effects.append("Invoca: %s" % skill.summon.display_name)
		if skill.summon.aura != null:
			effects.append("Aura radio %d" % skill.summon.aura.radius)
	if skill.motion != SkillData.Motion.NONE:
		effects.append(MOTION_TEXT[skill.motion])
	for app in skill.statuses:
		effects.append("%s %d%% (%d t)" % [app.status.display_name, app.chance, app.duration])
	if skill.strikes > 1:
		effects.append("%d golpes" % skill.strikes)
	if skill.self_status != null:
		effects.append("Se aplica %s" % skill.self_status.display_name)
	if skill.knockback > 0:
		effects.append("Empuja %d" % skill.knockback)
	if skill.bounce_hops > 0:
		effects.append("Rebota ×%d" % skill.bounce_hops)
	if skill.explode_percent > 0:
		effects.append("Explota %d%%" % skill.explode_percent)
	if skill.lifesteal_percent > 0:
		effects.append("Roba vida %d%%" % skill.lifesteal_percent)
	_effects_label.visible = not effects.is_empty()
	_effects_label.text = " · ".join(effects)

	var mods := skill.applied.map(func(m: ModifierData) -> String: return "◆ " + m.display_name)
	_modifiers_label.visible = not mods.is_empty()
	_modifiers_label.text = "  ".join(mods)


func hide_skill() -> void:
	visible = false
