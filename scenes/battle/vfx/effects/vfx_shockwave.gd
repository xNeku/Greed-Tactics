class_name VfxShockwave
extends Node3D
## A ground ring that expands and fades. Frees itself.

@onready var _ring: GeometryInstance3D = $Ring


func play(color: Color, radius: float, duration: float) -> void:
	scale = Vector3(radius, 1.0, radius)
	_ring.set_instance_shader_parameter(&"tint", color)
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: _ring.set_instance_shader_parameter(&"progress", v), 0.05, 1.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)
	await tween.finished
