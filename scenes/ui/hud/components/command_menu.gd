class_name CommandMenu
extends PanelContainer
## Commands of the active player unit (GDD §11), in two pages:
##   ROOT    1 Mover · 2 Atacar · 3 Esperar
##   SKILLS  1..6 one button per equipped skill · Esc Volver
## Number keys trigger the buttons of the page that is showing. Hovering a
## skill shows its card (SkillInfoPanel) through [signal skill_hovered]; there
## are no tooltips, the card is the only description.

signal move_selected
signal skill_selected(skill: SkillData)
signal wait_selected
## Mouse over a skill button (its effective version), or null when it leaves.
signal skill_hovered(skill: EffectiveSkill)

enum Page { ROOT, SKILLS }

const EMPOWERED_COLOR := Color(1.0, 0.55, 0.4)

const HOTKEY_ACTIONS: Array[StringName] = [
	&"command_1", &"command_2", &"command_3", &"command_4", &"command_5", &"command_6",
]

@onready var _caption: Label = %Caption
@onready var _buttons: VBoxContainer = %Buttons

var _page := Page.ROOT
var _unit: UnitState
var _can_move := false
var _usable: Dictionary[SkillData, bool] = {}
var _move_button: Button
var _attack_button: Button
var _wait_button: Button
var _skill_buttons: Dictionary[SkillData, Button] = {}
## Hotkey order of the current page (Volver is not numbered).
var _numbered: Array[Button] = []
var _highlighted: Button


## [param usable_skills] maps each equipped skill to whether it can be used
## right now. Names and costs shown are the effective ones (rage mutation and
## modifiers included); mutated skills are marked with their own colour.
func show_for(unit: UnitState, can_move: bool, usable_skills: Dictionary[SkillData, bool], page: Page = Page.ROOT) -> void:
	_unit = unit
	_can_move = can_move
	_usable = usable_skills
	_page = page
	_rebuild()
	visible = true


func open_skills() -> void:
	if _page != Page.SKILLS:
		_page = Page.SKILLS
		_rebuild()


func open_root() -> void:
	if _page != Page.ROOT:
		_page = Page.ROOT
		_rebuild()


func get_page() -> Page:
	return _page


func has_usable_skill() -> bool:
	return _usable.values().has(true)


#region Highlight of the current mode

func highlight_move() -> void:
	_highlight(_move_button if _page == Page.ROOT else null)


func highlight_skill(skill: SkillData) -> void:
	if _page != Page.SKILLS:
		open_skills()
	_highlight(_skill_buttons.get(skill))


func highlight_wait() -> void:
	if _page != Page.ROOT:
		open_root()
	_highlight(_wait_button)


func clear_highlight() -> void:
	_highlight(null)


func _highlight(target: Button) -> void:
	_highlighted = target
	for button: Button in _buttons.get_children():
		button.set_pressed_no_signal(button == target)

#endregion


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	for i in mini(HOTKEY_ACTIONS.size(), _numbered.size()):
		if event.is_action_pressed(HOTKEY_ACTIONS[i]):
			var button := _numbered[i]
			if not button.disabled:
				button.pressed.emit()
				get_viewport().set_input_as_handled()
			return


func _rebuild() -> void:
	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	_skill_buttons.clear()
	_numbered.clear()
	_move_button = null
	_attack_button = null
	_wait_button = null
	if _page == Page.ROOT:
		_caption.text = "Acciones"
		_move_button = _add_button("Mover", "", _can_move, move_selected.emit)
		# Deferred: the page is rebuilt, and the pressed button with it.
		_attack_button = _add_button("Atacar", "", has_usable_skill(), func() -> void: open_skills.call_deferred())
		_wait_button = _add_button("Esperar", "", true, wait_selected.emit)
	else:
		_caption.text = "Habilidades"
		for skill in _usable:
			var effective := _unit.get_effective(skill)
			var cost := effective.get_cost_text()
			var cooldown := _unit.get_cooldown(skill)
			if cooldown > 0:
				cost = "espera %d" % cooldown
			var button := _add_button(effective.display_name, cost, _usable[skill], skill_selected.emit.bind(skill))
			button.mouse_entered.connect(skill_hovered.emit.bind(effective))
			button.mouse_exited.connect(skill_hovered.emit.bind(null))
			if effective.empowered:
				button.add_theme_color_override(&"font_color", EMPOWERED_COLOR)
			_skill_buttons[skill] = button
		_add_button("Volver", "", true, func() -> void: open_root.call_deferred(), "Esc")
	if _highlighted != null and not is_instance_valid(_highlighted):
		_highlighted = null


func _add_button(label: String, cost: String, enabled: bool, on_pressed: Callable, key := "") -> Button:
	var button := Button.new()
	if key.is_empty():
		_numbered.append(button)
		key = str(_numbered.size())
	button.text = "%s  %s" % [key, label] + ("   (%s)" % cost if not cost.is_empty() else "")
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.toggle_mode = true
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed)
	_buttons.add_child(button)
	return button
