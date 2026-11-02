class_name UnitInfoPanel
extends PanelContainer
## Character sheet of the active or hovered unit (GDD §11).

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
	_name_label.text = "%s (Nv. %d %s • %s)" % [unit.display_name, data.level, data.race, data.unit_class]
	_hp_label.text = "HP: %d / %d" % [unit.hp, data.max_hp]
	_hp_bar.max_value = data.max_hp
	_hp_bar.value = unit.hp
	_mp_label.text = "MP: %d / %d" % [unit.mp, data.max_mp]
	_mp_bar.max_value = maxi(data.max_mp, 1)
	_mp_bar.value = unit.mp
	var pm := unit.pm if is_active else data.move_points
	var pa := unit.pa if is_active else data.action_points
	_stats_label.text = "PM: %d/%d   PA: %d/%d   EVA: %d%%   VEL: %d" % [
		pm, data.move_points, pa, data.action_points, data.evasion, data.speed]
