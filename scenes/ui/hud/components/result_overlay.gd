class_name ResultOverlay
extends Control
## End of combat screen: victory or defeat, with a retry button.

signal restart_requested

@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	visible = false
	_restart_button.pressed.connect(restart_requested.emit)


func show_result(victory: bool) -> void:
	_title_label.text = "¡Victoria!" if victory else "Derrota"
	_subtitle_label.text = "Todos los enemigos han caído." if victory else "Tu grupo ha caído."
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)
