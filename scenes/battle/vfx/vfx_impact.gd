class_name VfxImpact
extends Node3D
## Placeholder hit/explosion: sparks, an expanding ring on the floor, a flash
## and a light pulse. Frees itself when done.

@onready var _flash: GeometryInstance3D = $Flash
@onready var _ring: GeometryInstance3D = $Ring
@onready var _sparks: CPUParticles3D = $Sparks
@onready var _light: OmniLight3D = $Light


func play(color: Color, size: float = 1.0) -> void:
	_sparks.color = color
	_sparks.amount = maxi(8, roundi(28 * size))
	_sparks.restart()
	_light.light_color = color
	_ring.set_instance_shader_parameter(&"disc_color", color)
	_ring.scale = Vector3.ONE * 0.2
	_flash.scale = Vector3.ONE * 0.3 * size
	var tween := create_tween().set_parallel()
	tween.tween_property(_ring, "scale", Vector3.ONE * 1.6 * size, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(_set_ring_alpha.bind(color), 1.0, 0.0, 0.45)
	tween.tween_property(_flash, "scale", Vector3.ONE * 1.1 * size, 0.18).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_flash_alpha.bind(color), 1.0, 0.0, 0.25)
	tween.tween_property(_light, "light_energy", 0.0, 0.35)
	get_tree().create_timer(maxf(_sparks.lifetime, 0.5) + 0.2).timeout.connect(queue_free)


func _set_ring_alpha(alpha: float, color: Color) -> void:
	_ring.set_instance_shader_parameter(&"disc_color", Color(color, alpha))


func _set_flash_alpha(alpha: float, color: Color) -> void:
	_flash.set_instance_shader_parameter(&"tint", Color(color, alpha))
