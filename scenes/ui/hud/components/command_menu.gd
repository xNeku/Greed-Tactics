class_name CommandMenu
extends PanelContainer
## Commands of the active player unit (GDD §11): Move, one button per
## equipped skill, Wait. Number keys 1..6 trigger them in order.

signal move_selected
signal skill_selected(skill: SkillData)
signal wait_selected

const EMPOWERED_COLOR := Color(1.0, 0.55, 0.4)

const HOTKEY_ACTIONS: Array[StringName] = [
	&"command_1", &"command_2", &"command_3", &"command_4", &"command_5", &"command_6",
]

@onready var _buttons: VBoxContainer = %Buttons

var _move_button: Button
var _wait_button: Button
var _skill_buttons: Dictionary[SkillData, Button] = {}


## [param usable_skills] maps each equipped skill to whether it can be used
## right now. Names and costs shown are the effective ones (rage mutation and
## modifiers included); mutated skills are marked with a star.
func show_for(unit: UnitState, can_move: bool, usable_skills: Dictionary[SkillData, bool]) -> void:
	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	_skill_buttons.clear()

	_move_button = _add_button("Mover", "", can_move, move_selected.emit)
	for skill in usable_skills:
		var effective := unit.get_effective(skill)
		var cost := effective.get_cost_text()
		var cooldown := unit.get_cooldown(skill)
		if cooldown > 0:
			cost = "espera %d" % cooldown
		var button := _add_button(effective.display_name, cost, usable_skills[skill], skill_selected.emit.bind(skill))
		button.tooltip_text = _build_tooltip(effective, skill)
		if effective.empowered:
			button.add_theme_color_override(&"font_color", EMPOWERED_COLOR)
		_skill_buttons[skill] = button
	_wait_button = _add_button("Esperar", "", true, wait_selected.emit)
	visible = true


#region Highlight of the current mode

func highlight_move() -> void:
	_highlight(_move_button)


func highlight_skill(skill: SkillData) -> void:
	_highlight(_skill_buttons.get(skill))


func highlight_wait() -> void:
	_highlight(_wait_button)


func clear_highlight() -> void:
	_highlight(null)


func _highlight(target: Button) -> void:
	for button: Button in _buttons.get_children():
		button.set_pressed_no_signal(button == target)

#endregion


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var buttons := _buttons.get_children()
	for i in mini(HOTKEY_ACTIONS.size(), buttons.size()):
		if event.is_action_pressed(HOTKEY_ACTIONS[i]):
			var button: Button = buttons[i]
			if not button.disabled:
				button.pressed.emit()
				get_viewport().set_input_as_handled()
			return


func _add_button(label: String, cost: String, enabled: bool, on_pressed: Callable) -> Button:
	var index := _buttons.get_child_count() + 1
	var button := Button.new()
	button.text = "%d  %s" % [index, label] + ("   (%s)" % cost if not cost.is_empty() else "")
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.toggle_mode = true
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed)
	_buttons.add_child(button)
	return button


func _build_tooltip(effective: EffectiveSkill, base: SkillData) -> String:
	var lines := PackedStringArray([effective.source.description])
	if base.empowered_variant != null and not effective.empowered:
		lines.append("Con %d+ de ira muta en: %s" % [base.empowered_rage_threshold, base.empowered_variant.display_name])
	for modifier in effective.applied:
		lines.append("◆ %s: %s" % [modifier.display_name, modifier.description])
	return "\n".join(lines)
