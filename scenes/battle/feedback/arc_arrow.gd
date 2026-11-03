class_name ArcArrow
extends MeshInstance3D
## A curved feedback arrow (GDD §11 previsión): a ribbon along a parabola from
## [member from] to [member to] with a head at the end. Rebuilt every frame so
## it always faces the camera; endpoints glide to their targets smoothly.

@export var segments := 22
@export var width := 0.11
@export var head_length := 0.34
@export var head_width := 0.32
## Arc height = distance * height_factor, clamped.
@export var height_factor := 0.3
@export var min_height := 0.35
@export var max_height := 2.2
## Higher = endpoints snap faster to new targets.
@export var follow_speed := 16.0

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _target_from := Vector3.ZERO
var _target_to := Vector3.ZERO
var _mesh := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false


## Points the arrow. When it was hidden it appears at once, otherwise it glides.
func point(from: Vector3, to: Vector3, color: Color) -> void:
	_target_from = from
	_target_to = to
	if not visible:
		_from = from
		_to = to
	set_instance_shader_parameter(&"arrow_color", color)
	visible = true
	_rebuild()


func hide_arrow() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	var weight := 1.0 - exp(-follow_speed * delta)
	_from = _from.lerp(_target_from, weight)
	_to = _to.lerp(_target_to, weight)
	_rebuild()


func _rebuild() -> void:
	_mesh.clear_surfaces()
	var camera := get_viewport().get_camera_3d()
	var length := _from.distance_to(_to)
	if camera == null or length < 0.05:
		return
	var height := clampf(length * height_factor, min_height, max_height)
	var control := (_from + _to) * 0.5 + Vector3.UP * height
	# Stop the ribbon where the head starts (approximate along the curve).
	var body_end := clampf(1.0 - head_length / maxf(length + height, 0.01), 0.5, 0.97)

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous_left := Vector3.ZERO
	var previous_right := Vector3.ZERO
	var previous_u := 0.0
	for i in segments + 1:
		var t := body_end * float(i) / segments
		var p := _bezier(t, control)
		var side := _side(t, control, p, camera) * width * 0.5
		var left := p - side
		var right := p + side
		var u := t / body_end
		if i > 0:
			_quad(previous_left, previous_right, left, right, previous_u, u)
		previous_left = left
		previous_right = right
		previous_u = u
	# Head: a triangle from the end of the ribbon to the tip.
	var base := _bezier(body_end, control)
	var head_side := _side(body_end, control, base, camera) * head_width * 0.5
	_vertex(base - head_side, Vector2(1.0, 0.0))
	_vertex(base + head_side, Vector2(1.0, 1.0))
	_vertex(_to, Vector2(1.5, 0.5))
	_mesh.surface_end()


func _bezier(t: float, control: Vector3) -> Vector3:
	var a := _from.lerp(control, t)
	var b := control.lerp(_to, t)
	return a.lerp(b, t)


func _side(t: float, control: Vector3, at: Vector3, camera: Camera3D) -> Vector3:
	var tangent := 2.0 * (1.0 - t) * (control - _from) + 2.0 * t * (_to - control)
	var view := (camera.global_position - at).normalized()
	var side := tangent.cross(view)
	return side.normalized() if side.length() > 0.0001 else Vector3.RIGHT


func _quad(a_left: Vector3, a_right: Vector3, b_left: Vector3, b_right: Vector3, ua: float, ub: float) -> void:
	_vertex(a_left, Vector2(ua, 0.0))
	_vertex(a_right, Vector2(ua, 1.0))
	_vertex(b_left, Vector2(ub, 0.0))
	_vertex(a_right, Vector2(ua, 1.0))
	_vertex(b_right, Vector2(ub, 1.0))
	_vertex(b_left, Vector2(ub, 0.0))


func _vertex(position_: Vector3, uv: Vector2) -> void:
	_mesh.surface_set_uv(uv)
	_mesh.surface_add_vertex(position_)
