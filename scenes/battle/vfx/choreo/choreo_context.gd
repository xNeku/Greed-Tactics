class_name ChoreoContext
extends RefCounted
## What a choreography can touch while a skill plays: the scene's environment,
## sun, camera, screen effects and the units involved. Collects the restore
## actions so END leaves the battle exactly as it was.

var result: SkillResult
var root: Node3D
var tree: SceneTree
var environment: Environment
var sun: DirectionalLight3D
var camera_rig: CameraRig
var screen_fx: ScreenFx
var map: BattleMapView
var user_view: UnitView

var _restore: Array[Callable] = []
var _sky_saved := {}


func _init(p_result: SkillResult, p_root: Node3D, p_environment: Environment, p_sun: DirectionalLight3D,
		p_camera: CameraRig, p_screen: ScreenFx, p_map: BattleMapView, p_user_view: UnitView) -> void:
	result = p_result
	root = p_root
	tree = p_root.get_tree()
	environment = p_environment
	sun = p_sun
	camera_rig = p_camera
	screen_fx = p_screen
	map = p_map
	user_view = p_user_view


## Waits [param seconds] of real time (hit stops and slow motion do not stretch it).
func wait(seconds: float) -> void:
	await tree.create_timer(seconds, true, false, true).timeout


func anchor_position(anchor: VfxStep.Anchor) -> Vector3:
	match anchor:
		VfxStep.Anchor.USER:
			return user_view.global_position
		VfxStep.Anchor.AREA_CENTER:
			var cells := result.affected_cells
			if cells.is_empty():
				return map.cell_to_world(result.target_cell)
			var sum := Vector3.ZERO
			for cell in cells:
				sum += map.cell_to_world(cell)
			return sum / cells.size()
	return map.cell_to_world(result.target_cell)


## Size of the affected area on the ground (x, z), at least one cell.
func area_extents() -> Vector3:
	var cells := result.affected_cells if not result.affected_cells.is_empty() else ([result.target_cell] as Array[Vector2i])
	var low := Vector3(INF, 0, INF)
	var high := Vector3(-INF, 0, -INF)
	for cell in cells:
		var p := map.cell_to_world(cell)
		low = Vector3(minf(low.x, p.x), 0, minf(low.z, p.z))
		high = Vector3(maxf(high.x, p.x), 0, maxf(high.z, p.z))
	return Vector3(high.x - low.x + 1.0, 0.0, high.z - low.z + 1.0) * 0.5


func spawn(node: Node3D, at: Vector3) -> void:
	root.add_child(node)
	node.global_position = at


## Remembers the sky once so every SkyStep can be undone in one go at the end.
func save_sky() -> void:
	if not _sky_saved.is_empty():
		return
	_sky_saved = {
		"background": environment.background_color,
		"ambient": environment.ambient_light_energy,
		"ambient_color": environment.ambient_light_color,
		"fog": environment.fog_enabled,
		"fog_color": environment.fog_light_color,
		"fog_density": environment.fog_density,
		"vfog": environment.volumetric_fog_enabled,
		"vfog_density": environment.volumetric_fog_density,
		"vfog_albedo": environment.volumetric_fog_albedo,
		"glow": environment.glow_intensity,
		"sun_energy": sun.light_energy,
		"sun_color": sun.light_color,
	}
	on_finish(_restore_sky)


func _restore_sky() -> void:
	var s := _sky_saved
	var tween := root.create_tween().set_parallel().set_ignore_time_scale()
	tween.tween_property(environment, "background_color", s.background, 0.45)
	tween.tween_property(environment, "ambient_light_energy", s.ambient, 0.45)
	tween.tween_property(environment, "ambient_light_color", s.ambient_color, 0.45)
	tween.tween_property(environment, "fog_light_color", s.fog_color, 0.45)
	tween.tween_property(environment, "fog_density", s.fog_density, 0.45)
	tween.tween_property(environment, "volumetric_fog_density", s.vfog_density, 0.45)
	tween.tween_property(environment, "glow_intensity", s.glow, 0.45)
	tween.tween_property(sun, "light_energy", s.sun_energy, 0.45)
	tween.tween_property(sun, "light_color", s.sun_color, 0.45)
	await tween.finished
	environment.fog_enabled = s.fog
	environment.volumetric_fog_enabled = s.vfog
	environment.volumetric_fog_albedo = s.vfog_albedo


func on_finish(action: Callable) -> void:
	_restore.append(action)


## Undoes sky, camera and anything else the steps changed.
func finish() -> void:
	for action in _restore:
		await action.call()
	_restore.clear()
