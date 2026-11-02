class_name UnitInfoPanel
extends PanelContainer
## Character sheet of the active or hovered unit (GDD §11).

## Rage bar scale (RulesConfig.rage_max default).
const RAGE_MAX_DISPLAY := 100

@onready var _name_label: Label = %NameLabel
@onready var _hp_label: Label = %HpLabel
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _mp_label: Label = %MpLabel
@onready var _mp_bar: ProgressBar = %MpBar
@onready var _stats_label: Label = %StatsLabel


## [param is_active] shows the PM/PA left this turn instead of the unit's maximums.
func show_unit(unit: UnitState, is_active: bool) -> void:
	if unit == null:
		visible = false
		return
	visible = true
	var data := unit.data
	_name_label.text = "%s (Nv. %d %s • %s)" % [unit.display_name, unit.level, data.race, data.unit_class]
	_hp_label.text = "HP: %d / %d" % [unit.hp, unit.max_hp]
	_hp_bar.max_value = unit.max_hp
	_hp_bar.value = unit.hp
	_mp_label.visible = data.resource_kind != UnitData.ResourceKind.NONE
	_mp_bar.visible = _mp_label.visible
	if unit.uses_mana():
		_mp_label.text = "MP: %d / %d" % [unit.mp, unit.max_mp]
		_mp_bar.theme_type_variation = &"MpBar"
		_mp_bar.max_value = maxi(unit.max_mp, 1)
		_mp_bar.value = unit.mp
	elif unit.uses_rage():
		_mp_label.text = "Ira: %d / %d" % [unit.rage, RAGE_MAX_DISPLAY]
		_mp_bar.theme_type_variation = &"RageBar"
		_mp_bar.max_value = RAGE_MAX_DISPLAY
		_mp_bar.value = unit.rage
	var pm := unit.pm if is_active else unit.move_points
	var pa := unit.pa if is_active else unit.action_points
	_stats_label.text = "PM: %d/%d   PA: %d/%d   ATQ: %d   DEF: %d   EVA: %d%%   VEL: %d" % [
		pm, unit.move_points, pa, unit.action_points, unit.attack, unit.defense, unit.evasion, unit.speed]
