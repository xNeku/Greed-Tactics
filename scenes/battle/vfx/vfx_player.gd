class_name VfxPlayer
extends Node3D
## Plays the visuals of a resolved skill: projectiles with their
## ProjectileLook (picked per skill by [member projectile_library]), slash and
## nova placeholders, area bursts on every affected cell and the hit feedback
## (impact, hit-stop, shake). Scenes are exported so they can be swapped for
## final art without touching gameplay code.

@export var projectile_scene: PackedScene
@export var pixel_projectile_scene: PackedScene
@export var impact_scene: PackedScene
@export var slash_scene: PackedScene
@export var projectile_library: ProjectileLibrary
## Units per second of a fast placeholder projectile.
@export var projectile_speed := 16.0
@export var lob_duration := 0.55
@export var lob_height := 2.6
@export_group("Hit feedback")
## Freeze frames of a normal / critical hit without a projectile look (melee).
@export_range(0.0, 0.2) var hit_stop := 0.035
@export_range(0.0, 0.3) var crit_hit_stop := 0.08
@export_range(0.0, 1.0) var hit_shake := 0.08
@export_range(0.0, 1.0) var crit_shake := 0.22

## Set by BattleController: shake and screen effects on hits.
var camera_rig: CameraRig
var screen_fx: ScreenFx

var _particle_material: ShaderMaterial


## The projectile look of [param skill], or null when it has no projectile.
func look_for(skill: EffectiveSkill) -> ProjectileLook:
	var style: SkillData.VfxStyle = skill.get_vfx_style()
	if projectile_library == null or (style != SkillData.VfxStyle.PROJECTILE and style != SkillData.VfxStyle.LOB):
		return null
	return projectile_library.pick(skill)


## Everything that happens before the hits land.
func play_cast(result: SkillResult, map: BattleMapView, user_view: UnitView) -> void:
	var skill := result.skill
	var color := skill.vfx_color
	var origin := user_view.get_cast_position()
	var target := map.cell_to_world(result.target_cell) + Vector3.UP * 0.45
	var look := look_for(skill)
	var style: SkillData.VfxStyle = skill.get_vfx_style()
	if look != null:
		var weapon := user_view.unit.data.weapon
		var weapon_sprite := weapon.sprite if weapon != null else null
		if style == SkillData.VfxStyle.LOB and look.one_per_cell and result.affected_cells.size() > 1:
			await _volley(look, origin, result, map, weapon_sprite)
		else:
			var arc := lob_height if style == SkillData.VfxStyle.LOB else look.arc_per_unit * origin.distance_to(target)
			for shot in look.count - 1:
				_shoot(look, origin, target, arc, weapon_sprite, shot == 0)
				await get_tree().create_timer(look.interval).timeout
			await _shoot(look, origin, target, arc, weapon_sprite, look.count == 1)
		_area_bursts(result, map, color, look)
		return
	match style:
		SkillData.VfxStyle.PROJECTILE:
			var duration := clampf(origin.distance_to(target) / projectile_speed, 0.12, 0.4)
			await _projectile(origin, target, color, 0.5, duration, 1.0)
		SkillData.VfxStyle.LOB:
			await _projectile(origin, target, color, lob_height, lob_duration, 1.5)
		SkillData.VfxStyle.SLASH:
			slash(target, color)
			await get_tree().create_timer(0.12).timeout
		SkillData.VfxStyle.NOVA:
			impact(user_view.global_position + Vector3.UP * 0.2, color, 1.0 + skill.area_size)
	_area_bursts(result, map, color)


## A projectile jumping from the previous target to this bounce target.
func play_bounce(to: Vector3, hit: SkillResult.Hit, views: Dictionary[UnitState, UnitView], skill: EffectiveSkill) -> void:
	var from := to
	for unit in views:
		if unit.cell == hit.origin_cell:
			from = views[unit].get_cast_position()
			break
	if from.is_equal_approx(to):
		return
	var look := look_for(skill)
	if look != null:
		await _shoot(look, from, to, 0.6, null, false)
	else:
		await _projectile(from, to, skill.vfx_color, 0.8, 0.22, 0.8)


## Feedback of a landed hit at [param at]: impact (shaped by the projectile
## look when there is one), hit-stop, shake and aberration.
func hit(at: Vector3, skill: EffectiveSkill, critical: bool, explosion: bool) -> void:
	var look := look_for(skill)
	var strong := critical or explosion
	if look != null:
		impact(at, look.impact_color, look.impact_size * (1.5 if strong else 1.0), look.impact_sparks * (2 if strong else 1),
			look.impact_gravity, look.impact_smoke)
		_shake(look.shake * (1.8 if strong else 1.0))
		_aberrate(look.aberration + (0.35 if critical else 0.0))
		await _hit_stop(look.hit_stop * (2.0 if critical else 1.0))
	else:
		impact(at, skill.vfx_color, 1.4 if strong else 0.8)
		_shake(crit_shake if strong else hit_shake)
		_aberrate(0.35 if critical else 0.0)
		await _hit_stop(crit_hit_stop if critical else hit_stop)


func impact(world_position: Vector3, color: Color, size: float = 1.0, sparks: int = -1, gravity: float = -7.0, smoke: bool = false, lit: bool = true) -> void:
	var fx: VfxImpact = impact_scene.instantiate()
	add_child(fx)
	fx.global_position = world_position
	fx.play(color, size, sparks, gravity, smoke, lit)


func slash(world_position: Vector3, color: Color) -> void:
	var fx: VfxSlash = slash_scene.instantiate()
	add_child(fx)
	fx.global_position = world_position
	fx.play(color)


#region Projectiles with a look

## Launch effect + flight of one projectile. Returns when it arrives.
func _shoot(look: ProjectileLook, from: Vector3, to: Vector3, arc: float, weapon_sprite: Texture2D, with_launch: bool) -> void:
	var fx: PixelProjectile = pixel_projectile_scene.instantiate()
	add_child(fx)
	fx.global_position = from
	fx.setup(look, weapon_sprite)
	var direction := (to - from).normalized()
	if with_launch or look.launch == ProjectileLook.Launch.MUZZLE:
		await _launch(look, fx, from, direction)
	var duration := clampf(from.distance_to(to) / look.speed, 0.05, 1.4)
	await fx.fly(from, to, arc, duration)


## One projectile to every affected cell, from above the user, staggered.
func _volley(look: ProjectileLook, origin: Vector3, result: SkillResult, map: BattleMapView, weapon_sprite: Texture2D) -> void:
	var cells := result.affected_cells.duplicate()
	cells.shuffle()
	# Lambdas capture locals by value: count the flights in an array.
	var flying: Array[int] = [0]
	for cell in cells:
		var to := map.cell_to_world(cell) + Vector3.UP * 0.1
		flying[0] += 1
		_volley_shot(look, origin, to, weapon_sprite, flying)
		await get_tree().create_timer(look.per_cell_stagger).timeout
	while flying[0] > 0:
		await get_tree().process_frame


func _volley_shot(look: ProjectileLook, from: Vector3, to: Vector3, weapon_sprite: Texture2D, flying: Array[int]) -> void:
	await _shoot(look, from, to, lob_height * 0.8, weapon_sprite, false)
	flying[0] -= 1


func _launch(look: ProjectileLook, fx: PixelProjectile, at: Vector3, direction: Vector3) -> void:
	match look.launch:
		ProjectileLook.Launch.CHARGE:
			# The orb grows in the hand while sparks gather into it.
			_gather(at, look.launch_color, look.charge_time)
			fx.scale = Vector3.ONE * 0.05
			var grow := create_tween()
			grow.tween_property(fx, "scale", Vector3.ONE, look.charge_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			await grow.finished
		ProjectileLook.Launch.MUZZLE:
			impact(at + direction * 0.45, look.launch_color, 0.45, 10, -3.0, true)
			_shell_casing(at, direction)
			_shake(look.shake * 0.6)
		ProjectileLook.Launch.RELEASE:
			impact(at + direction * 0.3, look.launch_color, 0.25, 6, -1.0, false, false)


## Sparks pulled in from around [param at] for [param duration].
func _gather(at: Vector3, color: Color, duration: float) -> void:
	var sparks := CPUParticles3D.new()
	add_child(sparks)
	sparks.global_position = at
	sparks.mesh = _pixel_mesh(0.05)
	sparks.amount = 36
	sparks.lifetime = maxf(duration, 0.1)
	sparks.one_shot = true
	sparks.explosiveness = 0.6
	sparks.local_coords = true
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
	sparks.emission_sphere_radius = 0.7
	sparks.gravity = Vector3.ZERO
	sparks.radial_accel_min = -14.0
	sparks.radial_accel_max = -10.0
	sparks.color = color
	sparks.emitting = true
	get_tree().create_timer(duration + 0.3).timeout.connect(sparks.queue_free)


## A brass pixel jumping out of the gun and bouncing on the floor.
func _shell_casing(at: Vector3, direction: Vector3) -> void:
	var casing := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.045, 0.045)
	casing.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.8, 0.35)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	casing.material_override = material
	add_child(casing)
	var side := direction.cross(Vector3.UP).normalized() * randf_range(-0.3, -0.15) - direction * 0.15
	var ground := at.y - 0.5
	var land := at + side * 2.0
	land.y = ground
	var tween := create_tween()
	tween.tween_method(_place_casing.bind(casing, at, land), 0.0, 1.0, 0.4)
	tween.tween_property(casing, "global_position:y", ground + 0.06, 0.08)
	tween.tween_property(casing, "global_position:y", ground, 0.08)
	tween.tween_interval(0.4)
	tween.tween_callback(casing.queue_free)


func _place_casing(t: float, casing: Node3D, start: Vector3, land: Vector3) -> void:
	var p := start.lerp(land, t)
	p.y += 4.0 * 0.35 * t * (1.0 - t)
	casing.global_position = p


func _pixel_mesh(size: float) -> QuadMesh:
	if _particle_material == null:
		_particle_material = ShaderMaterial.new()
		_particle_material.shader = load("res://assets/shaders/pixel_particle.gdshader")
		_particle_material.set_shader_parameter(&"energy", 1.35)
		_particle_material.render_priority = 9
	var mesh := QuadMesh.new()
	mesh.size = Vector2(size, size)
	mesh.material = _particle_material
	return mesh

#endregion


#region Feedback

func _shake(strength: float) -> void:
	if camera_rig != null and strength > 0.0:
		camera_rig.shake(strength)


func _aberrate(amount: float) -> void:
	if screen_fx != null and amount > 0.0:
		screen_fx.pulse(Color.WHITE, 0.0, amount, Color.BLACK, 0.0, 0.25, false)


## Freezes the action for [param seconds] of real time.
func _hit_stop(seconds: float) -> void:
	if seconds <= 0.0:
		return
	var previous := Engine.time_scale
	Engine.time_scale = previous * 0.05
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = previous

#endregion


## Small bursts on every cell of an area attack.
func _area_bursts(result: SkillResult, map: BattleMapView, color: Color, look: ProjectileLook = null) -> void:
	if not result.skill.deals_damage() or result.affected_cells.size() <= 1:
		return
	for cell in result.affected_cells:
		var at := map.cell_to_world(cell) + Vector3.UP * 0.1
		if look != null:
			impact(at, look.impact_color, 0.6, look.impact_sparks / 2, look.impact_gravity, look.impact_smoke, false)
		else:
			impact(at, color, 0.6)


func _projectile(from: Vector3, to: Vector3, color: Color, height: float, duration: float, size: float) -> void:
	var fx: VfxProjectile = projectile_scene.instantiate()
	add_child(fx)
	fx.set_color(color, size)
	await fx.fly(from, to, height, duration)
	impact(to, color, size)
