class_name HeroCard
extends PanelContainer
## Portrait card of a hero: sprite, name, class, resource and optional HP.

const RESOURCE_TEXT := {
	UnitData.ResourceKind.NONE: "Enfriamientos",
	UnitData.ResourceKind.MANA: "Maná",
	UnitData.ResourceKind.RAGE: "Ira",
}

@export var show_description := false

@onready var _portrait: TextureRect = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _class_label: Label = %ClassLabel
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _hp_label: Label = %HpLabel
@onready var _description_label: Label = %DescriptionLabel


## [param hp] < 0 hides the HP bar (class showcase).
func show_hero(data: UnitData, level: int, hp: int = -1, max_hp: int = -1) -> void:
	_portrait.texture = data.sprite
	_name_label.text = "%s · Nv. %d" % [data.display_name, level]
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
