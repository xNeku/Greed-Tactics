class_name PixelProjectile
extends Node3D
## A projectile with a ProjectileLook: pixel sprite (or magic orb) turned
## towards where it flies, ribbon trail, sparkles and a moving light that
## lights the ground. [method fly] returns on arrival; the node frees itself
## once its trail and sparkles are gone.

@onready var _body: MeshInstance3D = $Body
@onready var _trail: VfxTrail = $Trail
@onready var _sparkles: CPUParticles3D = $Sparkles
@onready var _light: OmniLight3D = $Light

var _look: ProjectileLook
var _material: ShaderMaterial
var _spin_angle := 0.0
var _direction := Vector3.RIGHT


func setup(look: ProjectileLook, weapon_sprite: Texture2D = null) -> void:
	_look = look
	_material = (_body.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	_body.material_override = _material
	var texture := weapon_sprite if look.body == ProjectileLook.Body.WEAPON and weapon_sprite != null else look.sprite
	if look.body == ProjectileLook.Body.ORB or texture == null:
		_material.set_shader_parameter(&"orb", true)
		_material.set_shader_parameter(&"quad_size", Vector2(look.orb_size * (1.0 + look.tail * 1.8), look.orb_size))
		_material.set_shader_parameter(&"orb_pixels", look.orb_size / look.pixel_size)
		_material.set_shader_parameter(&"core_color", look.core_color)
		_material.set_shader_parameter(&"mid_color", look.mid_color)
		_material.set_shader_parameter(&"edge_color", look.edge_color)
		_material.set_shader_parameter(&"tail", look.tail)
		_material.set_shader_parameter(&"seed", randf() * 100.0)
	else:
		_material.set_shader_parameter(&"sprite", texture)
		_material.set_shader_parameter(&"quad_size", Vector2(texture.get_size()) * look.pixel_size)
	_material.set_shader_parameter(&"emission", look.emission)
	_trail.width = look.trail_width
	_trail.lifetime = look.trail_time
	_trail.emitting = look.trail_width > 0.0 and look.trail_time > 0.0
	var trail_material := (_trail.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	trail_material.set_shader_parameter(&"color", look.trail_color)
	trail_material.set_shader_parameter(&"emission", look.trail_emission)
	_trail.material_override = trail_material
	_sparkles.emitting = look.sparkle_amount > 0
	if look.sparkle_amount > 0:
		_sparkles.amount = look.sparkle_amount
		_sparkles.color = look.sparkle_color
		_sparkles.gravity = look.sparkle_gravity
	_light.light_color = look.light_color
	_light.light_energy = look.light_energy
	_light.omni_range = look.light_range
	_light.visible = look.light_energy > 0.0


## Flies from [param from] to [param to] along an arc of [param arc_height].
func fly(from: Vector3, to: Vector3, arc_height: float, duration: float) -> void:
	global_position = from
	_direction = (to - from).normalized()
	_apply_direction()
	var tween := create_tween()
	tween.tween_method(_place.bind(from, to, arc_height), 0.0, 1.0, duration)
	await tween.finished
	_land()


func get_direction() -> Vector3:
	return _direction


func _process(delta: float) -> void:
	if _look == null:
		return
	if _look.spin != 0.0 and _body.visible:
		_spin_angle -= _look.spin * TAU * delta
		_material.set_shader_parameter(&"spin", _spin_angle)
	_trail.push(global_position)


func _place(t: float, from: Vector3, to: Vector3, arc_height: float) -> void:
	var p := from.lerp(to, t)
	p.y += 4.0 * arc_height * t * (1.0 - t)
	if p.distance_squared_to(global_position) > 0.000001:
		_direction = (p - global_position).normalized()
		_apply_direction()
	global_position = p


func _apply_direction() -> void:
	_material.set_shader_parameter(&"direction", _direction)


## Arrival: the body vanishes (or sticks in the target a moment), the trail
## and sparkles die out, then the node frees itself.
func _land() -> void:
	_trail.emitting = false
	_sparkles.emitting = false
	var fade := create_tween().set_parallel()
	fade.tween_property(_light, "light_energy", 0.0, 0.2)
	if _look.sticks:
		# Sunk a little into the target, then fades.
		global_position += _direction * 0.12
		fade.tween_method(_set_alpha, 1.0, 0.0, 0.35).set_delay(0.7)
	else:
		_body.visible = false
	await get_tree().create_timer(maxf(_sparkles.lifetime, 1.1)).timeout
	while not _trail.is_done():
		await get_tree().process_frame
	queue_free()


func _set_alpha(alpha: float) -> void:
	_material.set_shader_parameter(&"tint", Color(1, 1, 1, alpha))
