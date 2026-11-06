class_name VfxImpact
extends Node3D
## Hit / explosion: pixel star flash, ring, square pixel sparks (with
## gravity: debris falls, embers rise), optional smoke and a light pulse that
## lights the ground around. Frees itself when done.

@onready var _flash: GeometryInstance3D = $Flash
@onready var _star: GeometryInstance3D = $Star
@onready var _ring: GeometryInstance3D = $Ring
@onready var _sparks: CPUParticles3D = $Sparks
@onready var _smoke: CPUParticles3D = $Smoke
@onready var _light: OmniLight3D = $Light


## [param sparks] < 0 = by size. [param gravity] of the sparks (y).
## [param lit] = false: no light pulse (small launch puffs).
func play(color: Color, size: float = 1.0, sparks: int = -1, gravity: float = -7.0, smoke: bool = false, lit: bool = true) -> void:
	_sparks.color = color
	_sparks.amount = maxi(4, sparks if sparks >= 0 else roundi(28 * size))
	_sparks.gravity = Vector3(0.0, gravity, 0.0)
	_sparks.initial_velocity_max = 3.0 + 2.0 * size
	_sparks.restart()
	if smoke:
		_smoke.amount = maxi(3, roundi(6 * size))
		_smoke.scale_amount_min = 0.4 + 0.3 * size
		_smoke.scale_amount_max = 0.6 + 0.5 * size
		_smoke.restart()
	_light.light_color = color
	_light.visible = lit
	_light.light_energy = 2.0 + 2.5 * size
	_light.omni_range = 2.0 + 1.5 * size
	_ring.set_instance_shader_parameter(&"disc_color", color)
	_ring.scale = Vector3.ONE * 0.2
	# The soft round glow does not fit the pixel art: only for big blasts.
	_flash.visible = size >= 1.6
	_flash.scale = Vector3.ONE * 0.25 * size
	_star.scale = Vector3.ONE * (0.55 + 0.45 * size)
	_star.rotation.z = randf() * 0.6
	_star.set_instance_shader_parameter(&"tint", color)
	var tween := create_tween().set_parallel()
	tween.tween_property(_ring, "scale", Vector3.ONE * 1.6 * size, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(_set_ring_alpha.bind(color), 1.0, 0.0, 0.45)
	tween.tween_property(_flash, "scale", Vector3.ONE * 0.9 * size, 0.16).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_flash_alpha.bind(color), 1.0, 0.0, 0.22)
	tween.tween_method(_set_star_progress, 0.0, 1.0, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_light, "light_energy", 0.0, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	get_tree().create_timer(maxf(_smoke.lifetime if smoke else _sparks.lifetime, 0.5) + 0.2).timeout.connect(queue_free)


func _set_ring_alpha(alpha: float, color: Color) -> void:
	_ring.set_instance_shader_parameter(&"disc_color", Color(color, alpha))


func _set_flash_alpha(alpha: float, color: Color) -> void:
	_flash.set_instance_shader_parameter(&"tint", Color(color, alpha * 0.8))


func _set_star_progress(progress: float) -> void:
	_star.set_instance_shader_parameter(&"progress", progress)
	_star.visible = progress < 0.999
