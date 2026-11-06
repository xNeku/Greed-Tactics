class_name VfxTrail
extends MeshInstance3D
## Camera-facing ribbon through the last positions of a moving node (world
## space, rebuilt every frame). Its colour and pixel bands come from
## pixel_trail.gdshader; vertex alpha carries the life left of each point.

var width := 0.12
## Seconds a point lives.
var lifetime := 0.18
var emitting := true

var _points: Array[Vector3] = []
var _ages: Array[float] = []
var _mesh := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 16384.0


## Adds the current head position (call every frame while flying).
func push(point: Vector3) -> void:
	if emitting and (_points.is_empty() or _points[-1].distance_squared_to(point) > 0.0004):
		_points.append(point)
		_ages.append(0.0)


func is_done() -> bool:
	return not emitting and _points.is_empty()


func _process(delta: float) -> void:
	for i in _ages.size():
		_ages[i] += delta
	while not _ages.is_empty() and _ages[0] > lifetime:
		_ages.pop_front()
		_points.pop_front()
	_rebuild()


func _rebuild() -> void:
	_mesh.clear_surfaces()
	var camera := get_viewport().get_camera_3d()
	if _points.size() < 2 or camera == null or lifetime <= 0.0:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in _points.size():
		var point := _points[i]
		var tangent := (_points[mini(i + 1, _points.size() - 1)] - _points[maxi(i - 1, 0)]).normalized()
		var to_camera := (camera.global_position - point).normalized()
		var side := tangent.cross(to_camera).normalized() * width * 0.5
		var life := 1.0 - _ages[i] / lifetime
		_mesh.surface_set_color(Color(1, 1, 1, life))
		_mesh.surface_set_uv(Vector2(float(i) / (_points.size() - 1), 0.0))
		_mesh.surface_add_vertex(point - side)
		_mesh.surface_set_color(Color(1, 1, 1, life))
		_mesh.surface_set_uv(Vector2(float(i) / (_points.size() - 1), 1.0))
		_mesh.surface_add_vertex(point + side)
	_mesh.surface_end()
