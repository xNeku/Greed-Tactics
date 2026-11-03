class_name VfxProjectile
extends Node3D
## Placeholder projectile: glowing core + halo + particle trail + light.
## [method fly] follows a parabola and returns on arrival; the trail fades
## out on its own and the node frees itself.

@onready var _core: GeometryInstance3D = $Core
@onready var _halo: GeometryInstance3D = $Halo
@onready var _trail: CPUParticles3D = $Trail
@onready var _light: OmniLight3D = $Light


func set_color(color: Color, size: float = 1.0) -> void:
	_core.set_instance_shader_parameter(&"tint", color)
	_halo.set_instance_shader_parameter(&"tint", Color(color, 0.35))
	_trail.color = color
	_light.light_color = color
	scale = Vector3.ONE * size


func fly(from: Vector3, to: Vector3, arc_height: float, duration: float) -> void:
	global_position = from
	var tween := create_tween()
	tween.tween_method(_place.bind(from, to, arc_height), 0.0, 1.0, duration)
	await tween.finished
	_core.visible = false
	_halo.visible = false
	_light.visible = false
	_trail.emitting = false
	get_tree().create_timer(_trail.lifetime + 0.1).timeout.connect(queue_free)


func _place(t: float, from: Vector3, to: Vector3, arc_height: float) -> void:
	var p := from.lerp(to, t)
	p.y += 4.0 * arc_height * t * (1.0 - t)
	global_position = p
