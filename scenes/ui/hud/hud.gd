class_name BattleHud
extends CanvasLayer
## Facade over the combat HUD widgets (GDD §11). Gameplay code talks to this
## node only; each widget is its own scene and can be restyled independently.

signal move_selected
signal skill_selected(skill: SkillData)
signal wait_selected
signal restart_requested

const MESSAGE_PLAYER_COLOR := Color(0.92, 0.94, 1.0)
const MESSAGE_ENEMY_COLOR := Color(1.0, 0.62, 0.62)

@onready var _title_label: Label = %TitleLabel
@onready var _turn_queue: TurnQueueBar = %TurnQueueBar
@onready var _message_label: Label = %MessageLabel
@onready var _tile_info: PanelContainer = %TileInfo
@onready var _tile_info_label: Label = %TileInfoLabel
@onready var _unit_info: UnitInfoPanel = %UnitInfoPanel
@onready var _command_menu: CommandMenu = %CommandMenu
@onready var _previews: ActionPreviewLayer = %ActionPreviewLayer
@onready var _result: ResultOverlay = %ResultOverlay
@onready var _skill_info: SkillInfoPanel = %SkillInfoPanel

## Card of the skill being aimed (shown again when the mouse leaves a button).
var _selected_skill: EffectiveSkill


func _ready() -> void:
	_command_menu.move_selected.connect(move_selected.emit)
	_command_menu.skill_selected.connect(skill_selected.emit)
	_command_menu.wait_selected.connect(wait_selected.emit)
	_command_menu.skill_hovered.connect(_on_skill_hovered)
	_result.restart_requested.connect(restart_requested.emit)
	_command_menu.visible = false
	_tile_info.visible = false


func set_camera(camera: Camera3D) -> void:
	_previews.set_camera(camera)


func set_title(text: String) -> void:
	_title_label.text = text


func set_message(text: String, from_enemy := false) -> void:
	_message_label.text = text
	_message_label.modulate = MESSAGE_ENEMY_COLOR if from_enemy else MESSAGE_PLAYER_COLOR


func show_turn_queue(units: Array[UnitState]) -> void:
	_turn_queue.show_queue(units)


func show_unit(unit: UnitState, is_active := true) -> void:
	_unit_info.show_unit(unit, is_active)


func show_tile(terrain: TerrainData, height: int) -> void:
	_tile_info.visible = terrain != null
	if terrain != null:
		_tile_info_label.text = "%s · Elev. %d" % [terrain.display_name, height]


func show_commands(unit: UnitState, can_move: bool, usable_skills: Dictionary[SkillData, bool],
		page: CommandMenu.Page = CommandMenu.Page.ROOT) -> void:
	_command_menu.show_for(unit, can_move, usable_skills, page)


func hide_commands() -> void:
	_command_menu.visible = false
	hide_skill_info()


func show_skill_info(skill: EffectiveSkill) -> void:
	_selected_skill = skill
	_skill_info.show_skill(skill)


func hide_skill_info() -> void:
	_selected_skill = null
	_skill_info.hide_skill()


func _on_skill_hovered(skill: EffectiveSkill) -> void:
	if skill != null:
		_skill_info.show_skill(skill)
	elif _selected_skill != null:
		_skill_info.show_skill(_selected_skill)
	else:
		_skill_info.hide_skill()


func get_command_menu() -> CommandMenu:
	return _command_menu


func show_previews(previews: Array[AttackPreview], anchors: Array[Vector3]) -> void:
	_previews.show_previews(previews, anchors)


func clear_previews() -> void:
	_previews.clear()


func set_result_button_text(text: String) -> void:
	_result.set_button_text(text)


func show_result(victory: bool) -> void:
	hide_commands()
	clear_previews()
	_result.show_result(victory)
