class_name VfxPlayer
extends Node3D
## Plays the placeholder visuals of a resolved skill (SkillData.vfx_style and
## vfx_color): projectile / lob / slash / nova, area bursts on every affected
## cell, impacts on hit units. Scenes are exported so they can be swapped for
## final art without touching gameplay code.

@export var projectile_scene: PackedScene
@export var impact_scene: PackedScene
@export var slash_scene: PackedScene
## Units per second of a fast projectile.
@export var projectile_speed := 16.0
@export var lob_duration := 0.55
@export var lob_height := 2.6


## Everything that happens before the hits land.
func play_cast(result: SkillResult, map: BattleMapView, user_view: UnitView) -> void:
	var skill := result.skill
	var color := skill.vfx_color
	var origin := user_view.get_cast_position()
	var target := map.cell_to_world(result.target_cell) + Vector3.UP * 0.45
	match skill.get_vfx_style():
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
	if skill.deals_damage() and result.affected_cells.size() > 1:
		for cell in result.affected_cells:
			impact(map.cell_to_world(cell) + Vector3.UP * 0.1, color, 0.6)


## A projectile jumping from the previous target to this bounce target.
func play_bounce(to: Vector3, hit: SkillResult.Hit, views: Dictionary[UnitState, UnitView], color: Color) -> void:
	var from := to
	for unit in views:
		if unit.cell == hit.origin_cell:
			from = views[unit].get_cast_position()
			break
	if from.is_equal_approx(to):
		return
	await _projectile(from, to, color, 0.8, 0.22, 0.8)


func impact(world_position: Vector3, color: Color, size: float = 1.0) -> void:
	var fx: VfxImpact = impact_scene.instantiate()
	add_child(fx)
	fx.global_position = world_position
	fx.play(color, size)


func slash(world_position: Vector3, color: Color) -> void:
	var fx: VfxSlash = slash_scene.instantiate()
	add_child(fx)
	fx.global_position = world_position
	fx.play(color)


func _projectile(from: Vector3, to: Vector3, color: Color, height: float, duration: float, size: float) -> void:
	var fx: VfxProjectile = projectile_scene.instantiate()
	add_child(fx)
	fx.set_color(color, size)
	await fx.fly(from, to, height, duration)
	impact(to, color, size)
