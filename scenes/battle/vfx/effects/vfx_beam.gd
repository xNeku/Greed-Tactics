class_name VfxBeam
extends Node3D
## A bright projectile (glowing core + light + pixel trail) that flies along a
## shallow arc and then vanishes. Frees itself.

@onready var _core: MeshInstance3D = $Core
@onready var _light: OmniLight3D = $Light
@onready var _trail: GPUParticles3D = $Trail


func fly(from: Vector3, to: Vector3, color: Color, speed: float, thickness: float, arc_height: float) -> void:
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_color = Color(color.r * 4.0, color.g * 4.0, color.b * 4.0)
	_core.material_override = look
	_core.scale = Vector3(thickness, thickness, thickness * 7.0)
	_light.light_color = color
	var trail_material := _trail.process_material as ParticleProcessMaterial
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color.r * 3.0, color.g * 3.0, color.b * 3.0))
	ramp.set_color(1, Color(color, 0.0))
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = ramp
	trail_material.color_ramp = ramp_texture
	_trail.emitting = true
	var duration := clampf(from.distance_to(to) / speed, 0.08, 1.2)
	var tween := create_tween()
	tween.tween_method(_place.bind(from, to, arc_height), 0.0, 1.0, duration)
	await tween.finished
	_core.visible = false
	_trail.emitting = false
	var fade := create_tween()
	fade.tween_property(_light, "light_energy", 0.0, 0.25)
	fade.tween_interval(_trail.lifetime)
	fade.tween_callback(queue_free)


func _place(t: float, from: Vector3, to: Vector3, arc_height: float) -> void:
	var p := from.lerp(to, t)
	p.y += sin(t * PI) * arc_height
	if p.distance_to(global_position) > 0.001:
		look_at_from_position(global_position, p, Vector3.UP)
	global_position = p
