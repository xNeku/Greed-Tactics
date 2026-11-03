class_name VfxSlash
extends Node3D
## Placeholder melee swing: a crescent that sweeps and fades. Frees itself.

@onready var _arc: GeometryInstance3D = $Arc


func play(color: Color, duration: float = 0.22) -> void:
	_arc.set_instance_shader_parameter(&"tint", color)
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.5, duration)
	tween.tween_method(_set_alpha.bind(color), 1.0, 0.0, 0.12)
	tween.tween_callback(queue_free)


func _set_progress(value: float) -> void:
	_arc.set_instance_shader_parameter(&"progress", value)


func _set_alpha(alpha: float, color: Color) -> void:
	_arc.set_instance_shader_parameter(&"tint", Color(color, alpha))
