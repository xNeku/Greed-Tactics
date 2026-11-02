class_name DamagePopup
extends Label3D
## Floating number/text that rises and fades, then frees itself.

@export var rise := 0.7
@export var duration := 0.9


func show_text(value: String, color: Color) -> void:
	text = value
	modulate = color
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y + rise, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	tween.chain().tween_callback(queue_free)
