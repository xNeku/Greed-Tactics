class_name UnitAura
extends Node3D
## Aura of a unit (GDD §11, v0.9.1): pixelated flames around the body in up
## to three colours, rising embers, a glow on the ground, a light, and for
## bosses lightning arcs crackling around. UnitView decides the colours from
## the unit's rank, rage and buffs.

@onready var _flames: MeshInstance3D = $Flames
@onready var _embers: CPUParticles3D = $Embers
@onready var _glow: MeshInstance3D = $Glow
@onready var _light: OmniLight3D = $Light
@onready var _bolts: MeshInstance3D = $Bolts

var _material: ShaderMaterial
var _lightning := false
var _bolt_color := Color.WHITE
var _bolt_mesh := ImmediateMesh.new()
var _bolt_timer := 0.0
var _bolt_visible := 0.0
var _height := 1.0


func _ready() -> void:
	_material = (_flames.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	_flames.material_override = _material
	_material.set_shader_parameter(&"seed", randf() * 50.0)
	_bolts.mesh = _bolt_mesh
	_bolts.top_level = true
	_bolts.global_transform = Transform3D.IDENTITY
	visible = false


## [param colors] outer -> inner (1 to 3). [param body_height] in world units.
## [param size] scales the flames (bosses are bigger). Empty colors hide it.
func show_aura(colors: PackedColorArray, strength: float, wildness: float, lightning: bool,
		body_height: float, pixel_size: float, size: float = 1.0) -> void:
	visible = not colors.is_empty()
	if not visible:
		_light.visible = false
		return
	_height = body_height * size
	var outer := colors[0]
	var mid := colors[mini(1, colors.size() - 1)]
	var inner := colors[mini(2, colors.size() - 1)] if colors.size() > 2 else mid.lerp(Color.WHITE, 0.6)
	_material.set_shader_parameter(&"outer", outer)
	_material.set_shader_parameter(&"mid", mid)
	_material.set_shader_parameter(&"inner", inner)
	_material.set_shader_parameter(&"strength", strength)
	_material.set_shader_parameter(&"wildness", wildness)
	_material.set_shader_parameter(&"pixel_size", pixel_size)
	_material.set_shader_parameter(&"quad_size", Vector2(_height * 0.85, _height * 1.25))
	_embers.color = mid
	_embers.amount = 10 + roundi(wildness * 20.0)
	_embers.emission_box_extents = Vector3(_height * 0.3, 0.05, 0.1)
	_glow.set_instance_shader_parameter(&"disc_color", Color(outer, 0.5 * clampf(strength, 0.0, 1.0)))
	_glow.scale = Vector3.ONE * (0.9 + 0.5 * wildness) * size
	_light.visible = true
	_light.light_color = mid
	_light.light_energy = 0.6 + strength * 0.8
	_light.position.y = _height * 0.5
	_lightning = lightning
	_bolt_color = inner.lerp(Color(0.7, 0.85, 1.0), 0.5)


func _process(delta: float) -> void:
	if not visible or not _lightning:
		_bolt_mesh.clear_surfaces()
		return
	_bolt_timer -= delta
	_bolt_visible -= delta
	if _bolt_timer <= 0.0:
		_bolt_timer = randf_range(0.25, 0.9)
		_bolt_visible = randf_range(0.08, 0.18)
	if _bolt_visible > 0.0:
		_draw_bolts()
	else:
		_bolt_mesh.clear_surfaces()


## Two or three jagged arcs around the body, facing the camera.
func _draw_bolts() -> void:
	_bolt_mesh.clear_surfaces()
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var right := camera.global_basis.x
	var up := Vector3.UP
	var toward := -camera.global_basis.z * -1.0
	var center := global_position + up * _height * 0.5 + toward * 0.05
	_bolt_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_bolt_mesh.surface_set_color(Color(_bolt_color.r * 3.0, _bolt_color.g * 3.0, _bolt_color.b * 3.0))
	for b in randi_range(2, 3):
		var angle := randf() * TAU
		var point := center + (right * cos(angle) * 0.35 + up * sin(angle) * 0.55) * _height
		for s in 5:
			var next := point + (right * randf_range(-0.22, 0.22) + up * randf_range(-0.05, 0.25)) * _height * 0.5
			_segment(point, next, right, 0.025)
			point = next
	_bolt_mesh.surface_end()


func _segment(a: Vector3, b: Vector3, right: Vector3, width: float) -> void:
	var dir := (b - a).normalized()
	var side := dir.cross(right.cross(Vector3.UP).normalized()).normalized() * width
	if side.length() < 0.001:
		side = right * width
	for v in [a - side, a + side, b + side, a - side, b + side, b - side]:
		_bolt_mesh.surface_add_vertex(v)
