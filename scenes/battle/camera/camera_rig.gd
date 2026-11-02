class_name CameraRig
extends Node3D
## Free isometric-style camera (GDD §11).
##   Q / E ............. rotate 90º
##   Mouse wheel ....... zoom
##   WASD / arrows ..... pan
##   Middle drag ....... pan
##   Space ............. back to the active unit ([member home_position])
## The rig node is the focus point; Yaw > Pitch > Camera3D hang below it.

@export_range(15.0, 80.0) var pitch_degrees := 42.0
@export var initial_yaw_degrees := 45.0
@export var yaw_step_degrees := 90.0
@export var distance := 24.0
@export var min_distance := 7.0
@export var max_distance := 30.0
@export var zoom_step := 1.5
@export var pan_speed := 9.0
@export var drag_pan_factor := 0.0025
## Higher = snappier camera.
@export var smoothing := 9.0

## Where Space takes the camera back to. BattleController keeps it on the active unit.
var home_position := Vector3.ZERO

@onready var _yaw: Node3D = $Yaw
@onready var _pitch: Node3D = $Yaw/Pitch
@onready var _camera: Camera3D = $Yaw/Pitch/Camera3D

var _target_position := Vector3.ZERO
var _target_yaw := 0.0
var _target_distance := 0.0
var _bounds := AABB()
var _dragging := false


func _ready() -> void:
	_target_position = global_position
	_target_yaw = deg_to_rad(initial_yaw_degrees)
	_target_distance = distance
	_yaw.rotation.y = _target_yaw
	_apply_pitch_and_distance()


func get_camera() -> Camera3D:
	return _camera


## Limits panning to [param bounds] (usually the map AABB).
func set_bounds(bounds: AABB) -> void:
	_bounds = bounds


func focus_on(world_position: Vector3, instant := false) -> void:
	_target_position = _clamp_to_bounds(world_position)
	if instant:
		global_position = _target_position


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_rotate_left"):
		_target_yaw -= deg_to_rad(yaw_step_degrees)
	elif event.is_action_pressed("camera_rotate_right"):
		_target_yaw += deg_to_rad(yaw_step_degrees)
	elif event.is_action_pressed("camera_zoom_in"):
		_target_distance = maxf(_target_distance - zoom_step, min_distance)
	elif event.is_action_pressed("camera_zoom_out"):
		_target_distance = minf(_target_distance + zoom_step, max_distance)
	elif event.is_action_pressed("camera_focus"):
		focus_on(home_position)
	elif event.is_action("camera_drag"):
		_dragging = event.is_pressed()
	elif event is InputEventMouseMotion and _dragging:
		var motion: Vector2 = event.relative * drag_pan_factor * distance
		_pan(Vector2(-motion.x, -motion.y))


func _process(delta: float) -> void:
	var input := Input.get_vector("camera_pan_left", "camera_pan_right", "camera_pan_up", "camera_pan_down")
	if input != Vector2.ZERO:
		_pan(input * pan_speed * delta)

	var weight := 1.0 - exp(-smoothing * delta)
	global_position = global_position.lerp(_target_position, weight)
	_yaw.rotation.y = lerp_angle(_yaw.rotation.y, _target_yaw, weight)
	distance = lerpf(distance, _target_distance, weight)
	_apply_pitch_and_distance()


## Moves the focus point in screen-aligned ground directions.
func _pan(amount: Vector2) -> void:
	var right := _yaw.global_basis.x
	var forward := -_yaw.global_basis.z
	right.y = 0.0
	forward.y = 0.0
	var offset := right.normalized() * amount.x - forward.normalized() * amount.y
	_target_position = _clamp_to_bounds(_target_position + offset)


func _apply_pitch_and_distance() -> void:
	_pitch.rotation.x = -deg_to_rad(pitch_degrees)
	_camera.position = Vector3(0.0, 0.0, distance)


func _clamp_to_bounds(world_position: Vector3) -> Vector3:
	if _bounds.size.x <= 0.0 and _bounds.size.z <= 0.0:
		return world_position
	var end := _bounds.end
	return Vector3(
		clampf(world_position.x, _bounds.position.x, end.x),
		world_position.y,
		clampf(world_position.z, _bounds.position.z, end.z))
