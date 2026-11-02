class_name UnitView
extends Node3D
## Visual representation of a UnitState: billboard sprite, team ring, facing
## arrow and floating info. It never changes rules; it only mirrors the state
## and plays animations that BattleController awaits.

const PLAYER_COLOR := Color(0.26, 0.56, 1.0)
const ENEMY_COLOR := Color(0.95, 0.27, 0.3)
const ACTIVE_COLOR := Color(1.0, 0.82, 0.2)
const MISS_COLOR := Color(0.85, 0.9, 1.0)
const DAMAGE_COLOR := Color(1.0, 1.0, 1.0)
const CRIT_COLOR := Color(1.0, 0.75, 0.2)

@export var step_duration := 0.14
@export var hop_height := 0.3
@export var damage_popup_scene: PackedScene

@onready var _body: Node3D = $Body
@onready var _sprite: Sprite3D = $Body/Sprite
@onready var _info_label: Label3D = $Body/InfoLabel
@onready var _ring: GeometryInstance3D = $Ring
@onready var _facing_pivot: Node3D = $FacingPivot

var unit: UnitState
var _map: BattleMapView
var _camera: Camera3D
var _facing_tween: Tween


func setup(p_unit: UnitState, map_view: BattleMapView, camera: Camera3D) -> void:
	unit = p_unit
	_map = map_view
	_camera = camera
	name = "Unit%d_%s" % [unit.id, unit.data.id]
	_sprite.texture = unit.data.sprite
	if _sprite.texture != null:
		_sprite.offset.y = _sprite.texture.get_height() * 0.5
	set_active(false)
	sync_to_state()


func _process(_delta: float) -> void:
	_update_sprite_flip()


## Snaps position, facing and labels to the current state, without animating.
func sync_to_state() -> void:
	global_position = _map.cell_to_world(unit.cell)
	_facing_pivot.rotation.y = GridDir.to_yaw(unit.facing)
	refresh_info()


func refresh_info() -> void:
	_info_label.text = "%s\nHP %d/%d" % [unit.display_name, unit.hp, unit.data.max_hp]
	_info_label.modulate = get_team_color().lightened(0.35)


func get_team_color() -> Color:
	return PLAYER_COLOR if unit.team == UnitState.Team.PLAYER else ENEMY_COLOR


func set_active(active: bool) -> void:
	_ring.set_instance_shader_parameter(&"disc_color", ACTIVE_COLOR if active else get_team_color())


## Turns the facing arrow (and sprite flip) towards [param dir].
func face(dir: GridDir.Dir) -> void:
	if _facing_tween != null:
		_facing_tween.kill()
	var target := _facing_pivot.rotation.y + angle_difference(_facing_pivot.rotation.y, GridDir.to_yaw(dir))
	_facing_tween = create_tween()
	_facing_tween.tween_property(_facing_pivot, "rotation:y", target, 0.12)


func get_head_position() -> Vector3:
	return _info_label.global_position


#region Animations

## Walks cell by cell from [param from_cell] along [param path], hopping on
## height changes. The state is already at the destination when this runs.
func play_move(from_cell: Vector2i, path: Array[Vector2i]) -> void:
	if path.is_empty():
		return
	var tween := create_tween()
	var previous := from_cell
	var last_position := _map.cell_to_world(from_cell)
	for cell in path:
		var target := _map.cell_to_world(cell)
		tween.tween_callback(face.bind(GridDir.from_delta(cell - previous)))
		var mid := last_position.lerp(target, 0.5)
		if absf(target.y - last_position.y) > 0.01:
			mid.y = maxf(last_position.y, target.y) + hop_height
		tween.tween_property(self, "global_position", mid, step_duration * 0.5)
		tween.tween_property(self, "global_position", target, step_duration * 0.5)
		previous = cell
		last_position = target
	await tween.finished
	sync_to_state()


func play_attack(target_cell: Vector2i) -> void:
	var direction := (_map.cell_to_world(target_cell) - global_position)
	direction.y = 0.0
	var lunge := direction.normalized() * 0.3 if direction.length() > 0.01 else Vector3.ZERO
	var tween := create_tween()
	tween.tween_property(_body, "position", lunge, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "position", Vector3.ZERO, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished


func play_hit(hit: SkillResult.Hit) -> void:
	if not hit.landed:
		_spawn_popup("Fallo", MISS_COLOR)
		var dodge := create_tween()
		dodge.tween_property(_body, "position:x", 0.15, 0.06)
		dodge.tween_property(_body, "position:x", 0.0, 0.1)
		await dodge.finished
		return
	_spawn_popup(("%d!" if hit.critical else "%d") % hit.damage, CRIT_COLOR if hit.critical else DAMAGE_COLOR)
	refresh_info()
	var flash := create_tween()
	for i in 2:
		flash.tween_property(_sprite, "modulate", Color(1.0, 0.35, 0.35), 0.06)
		flash.tween_property(_sprite, "modulate", Color.WHITE, 0.06)
	await flash.finished


func play_defeat() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_property(_body, "position:y", -0.2, 0.4)
	tween.tween_property(_ring, "transparency", 1.0, 0.4)
	tween.tween_property(_facing_pivot, "scale", Vector3.ZERO, 0.2)
	await tween.finished
	visible = false

#endregion


func _spawn_popup(text: String, color: Color) -> void:
	if damage_popup_scene == null:
		return
	var popup: DamagePopup = damage_popup_scene.instantiate()
	add_child(popup)
	popup.global_position = get_head_position() + Vector3.UP * 0.2
	popup.show_text(text, color)


## Sprites are drawn facing right: flip them when the unit faces screen-left.
func _update_sprite_flip() -> void:
	if _camera == null or unit == null:
		return
	var facing := -_facing_pivot.global_basis.z
	var screen_x := facing.dot(_camera.global_basis.x)
	if absf(screen_x) > 0.05:
		_sprite.flip_h = screen_x < 0.0
