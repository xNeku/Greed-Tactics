class_name ModifierCard
extends PanelContainer
## One modifier offered at a checkpoint (GDD §5), with its grammar spelled out.

signal chosen(modifier: ModifierData)

const TRIGGER_TEXT := {
	ModifierData.Trigger.ALWAYS: "Siempre",
	ModifierData.Trigger.ON_BACK_ATTACK: "Al atacar por la espalda",
	ModifierData.Trigger.ON_CRIT: "Al hacer crítico",
	ModifierData.Trigger.ON_KILL: "Al matar",
}

@onready var _name_label: Label = %NameLabel
@onready var _kind_label: Label = %KindLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _target_label: Label = %TargetLabel
@onready var _choose_button: Button = %ChooseButton

var _modifier: ModifierData


func _ready() -> void:
	_choose_button.pressed.connect(func() -> void: chosen.emit(_modifier))


func show_modifier(modifier: ModifierData) -> void:
	_modifier = modifier
	_name_label.text = modifier.display_name
	_kind_label.text = "Comportamiento" if modifier.is_behavior() else "Numérico"
	_description_label.text = modifier.description
	var tag := "todas las habilidades" if modifier.target_tag == &"" else "etiqueta «%s»" % modifier.target_tag
	_target_label.text = "Afecta a: %s\nDisparador: %s" % [tag, TRIGGER_TEXT[modifier.trigger]]


func set_choosable(value: bool) -> void:
	_choose_button.disabled = not value
