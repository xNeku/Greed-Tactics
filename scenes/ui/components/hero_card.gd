class_name HeroCard
extends PanelContainer
## Portrait card of a hero: sprite, name, class, resource and optional HP.

const RESOURCE_TEXT := {
	UnitData.ResourceKind.NONE: "Enfriamientos",
	UnitData.ResourceKind.MANA: "Maná",
	UnitData.ResourceKind.RAGE: "Ira",
}

## Emitted on click when [member selectable].
signal pressed

@export var show_description := false
## Clickable card (party selection on the main menu).
@export var selectable := false

@onready var _portrait: TextureRect = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _class_label: Label = %ClassLabel
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _hp_label: Label = %HpLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _level_badge: Label = %LevelBadge
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _progress_label: Label = %ProgressLabel


func _gui_input(event: InputEvent) -> void:
	if selectable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


func set_selected(value: bool) -> void:
	theme_type_variation = &"SelectedCard" if value else &"Card"
	modulate = Color.WHITE if value else Color(1, 1, 1, 0.72)


## Account progression: Roman level badge, XP bar to the next level and a
## note when the hero waits at a wall (boss needed) or is a master.
func show_progress(profile: PlayerProfile, config: ProgressionConfig, hero_id: StringName) -> void:
	var level := profile.get_level(config, hero_id)
	var xp := profile.get_record(hero_id).xp
	_level_badge.visible = true
	_level_badge.text = ProgressionConfig.roman(level)
	_xp_bar.visible = true
	_progress_label.visible = true
	if level >= ProgressionConfig.MAX_LEVEL:
		_xp_bar.value = 100.0
		_progress_label.text = "Maestría ★" if profile.is_master(config, hero_id) else "Nivel máximo"
		return
	var from := config.level_xp[level - 1]
	var to := config.level_xp[level]
	_xp_bar.value = 100.0 * (xp - from) / maxf(to - from, 1)
	if profile.get_wall(config, hero_id) > 0:
		_progress_label.text = "Bloqueado: vence a un jefe"
	else:
		_progress_label.text = "%d / %d XP" % [xp - from, to - from]


## Run protagonist: star on the name and highlighted frame.
func mark_protagonist() -> void:
	_name_label.text = "★ " + _name_label.text
	theme_type_variation = &"SelectedCard"


## [param hp] < 0 hides the HP bar (class showcase).
func show_hero(data: UnitData, level: int, hp: int = -1, max_hp: int = -1) -> void:
	_portrait.texture = data.sprite
	_name_label.text = "%s · Nv. %d" % [data.display_name, level] if level > 0 else data.display_name
	_class_label.text = "%s %s · %s" % [data.unit_class, data.race, RESOURCE_TEXT[data.resource_kind]]
	var has_hp := hp >= 0
	_hp_bar.visible = has_hp
	_hp_label.visible = has_hp
	if has_hp:
		_hp_bar.max_value = max_hp
		_hp_bar.value = hp
		_hp_label.text = "HP %d / %d" % [hp, max_hp] if hp > 0 else "Caído"
		modulate = Color.WHITE if hp > 0 else Color(1, 1, 1, 0.5)
	_description_label.visible = show_description
	_description_label.text = data.description
