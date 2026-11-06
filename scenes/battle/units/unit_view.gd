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
const HEAL_COLOR := Color(0.45, 1.0, 0.55)
const RAGE_COLOR := Color(1.0, 0.45, 0.35)

@export var step_duration := 0.14
@export var hop_height := 0.3
@export var damage_popup_scene: PackedScene
@export var held_weapon_scene: PackedScene

@onready var _body: Node3D = $Body
@onready var _sprite: AnimatedSprite3D = $Body/Sprite
@onready var _info_label: Label3D = $Body/InfoLabel
@onready var _ring: GeometryInstance3D = $Ring
@onready var _facing_pivot: Node3D = $FacingPivot
@onready var _status_icons: Node3D = $Body/StatusIcons
@onready var _aura_disc: GeometryInstance3D = $AuraDisc

var unit: UnitState
var _map: BattleMapView
var _camera: Camera3D
var _facing_tween: Tween
var _state: StringName = &"idle"
var _view: StringName = &"front"
var _label_base_y := 0.0
var _icons_base_y := 0.0
## Sprite colour when not flashing: white, or tinted by the strongest status.
var _base_modulate := Color.WHITE
## Weapon drawn in the hand (two for dual weapons).
var _held_weapons: Array[HeldWeapon] = []


func setup(p_unit: UnitState, map_view: BattleMapView, camera: Camera3D) -> void:
	unit = p_unit
	_map = map_view
	_camera = camera
	name = "Unit%d_%s" % [unit.id, unit.data.id]
	_facing_pivot.visible = not unit.is_structure()
	_setup_aura()
	_sprite.sprite_frames = _build_frames()
	_sprite.animation_finished.connect(_on_animation_finished)
	_play_state(&"idle")
	_sprite.pixel_size *= unit.data.sprite_scale
	_setup_weapon()
	_info_label.position.y *= unit.data.sprite_scale
	_status_icons.position.y *= unit.data.sprite_scale
	_label_base_y = _info_label.position.y
	_icons_base_y = _status_icons.position.y
	_ring.scale = Vector3.ONE * clampf(unit.data.sprite_scale, 1.0, 1.3)
	set_active(false)
	sync_to_state()


func _process(_delta: float) -> void:
	_update_sprite_flip()
	_compensate_camera_pitch()
	_update_weapons()


## Snaps position, facing and labels to the current state, without animating.
func sync_to_state() -> void:
	global_position = _map.cell_to_world(unit.cell)
	_facing_pivot.rotation.y = GridDir.to_yaw(unit.facing)
	refresh_info()


func refresh_info() -> void:
	var resource := ""
	if unit.uses_rage():
		resource = " · Ira %d" % unit.rage
	elif unit.uses_mana():
		resource = " · MP %d" % unit.mp
	var star := "★ " if unit.is_protagonist else ""
	_info_label.text = "%s%s\nHP %d/%d%s" % [star, unit.display_name, unit.hp, unit.max_hp, resource]
	_info_label.modulate = get_team_color().lightened(0.35)
	_refresh_statuses()


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


## Where projectiles leave from (chest height).
func get_cast_position() -> Vector3:
	return global_position + Vector3.UP * 0.55 * unit.data.sprite_scale


func get_head_position() -> Vector3:
	return _info_label.global_position


#region Animations

## Walks cell by cell from [param from_cell] along [param path], hopping on
## height changes. The state is already at the destination when this runs.
func play_move(from_cell: Vector2i, path: Array[Vector2i]) -> void:
	if path.is_empty():
		return
	_play_state(&"walk")
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
	_play_state(&"idle")
	sync_to_state()


## Skill motion (teleport, charge, appear behind): an arc jump to [param to_cell].
func play_leap(to_cell: Vector2i) -> void:
	var start := global_position
	var target := _map.cell_to_world(to_cell)
	var peak := maxf(start.y, target.y) + 1.2
	var tween := create_tween()
	tween.tween_method(_set_leap_progress.bind(start, target, peak), 0.0, 1.0, 0.32)
	await tween.finished
	sync_to_state()


## Quadratic arc between [param start] and [param target] peaking at [param peak].
func _set_leap_progress(t: float, start: Vector3, target: Vector3, peak: float) -> void:
	var p := start.lerp(target, t)
	p.y = lerpf(lerpf(start.y, peak, t), lerpf(peak, target.y, t), t)
	global_position = p


## Knockback: slide to the cell the target was pushed to.
func play_push(to_cell: Vector2i) -> void:
	var tween := create_tween()
	tween.tween_property(self, "global_position", _map.cell_to_world(to_cell), 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished


func play_heal(amount: int) -> void:
	if amount > 0:
		_spawn_popup("+%d" % amount, HEAL_COLOR)
	refresh_info()


func play_text(text: String, color: Color = RAGE_COLOR) -> void:
	_spawn_popup(text, color)


## Fades the sprite (and its labels) to [param alpha]: shadow steps, burrowing.
func fade_sprite(alpha: float, duration: float) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "modulate:a", alpha, duration)
	tween.tween_property(_info_label, "modulate:a", alpha, duration)
	_status_icons.visible = alpha > 0.5
	await tween.finished


## Charging a skill: shivers and glows with [param glow].
func play_charge(glow: Color, duration: float) -> void:
	var tween := create_tween()
	var steps := maxi(2, int(duration / 0.05))
	for i in steps:
		tween.tween_property(_body, "position", Vector3(randf_range(-0.04, 0.04), randf_range(0.0, 0.05), 0.0), 0.05)
	tween.tween_property(_body, "position", Vector3.ZERO, 0.05)
	var glow_tween := create_tween()
	glow_tween.tween_property(_sprite, "modulate", Color(glow.r * 1.6, glow.g * 1.6, glow.b * 1.6, _sprite.modulate.a), duration * 0.6)
	glow_tween.tween_property(_sprite, "modulate", Color(_base_modulate, _sprite.modulate.a), duration * 0.4)
	await tween.finished


func play_attack(target_cell: Vector2i) -> void:
	var direction := (_map.cell_to_world(target_cell) - global_position)
	direction.y = 0.0
	var lunge := direction.normalized() * 0.3 if direction.length() > 0.01 else Vector3.ZERO
	_play_state(&"attack")
	_animate_weapons()
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
	_play_state(&"hit")
	var flash := create_tween()
	for i in 2:
		flash.tween_property(_sprite, "modulate", Color(1.0, 0.35, 0.35), 0.06)
		flash.tween_property(_sprite, "modulate", _base_modulate, 0.06)
	await flash.finished


func play_defeat() -> void:
	_aura_disc.visible = false
	_play_state(&"hit")
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_property(_body, "position:y", -0.2, 0.4)
	tween.tween_property(_ring, "transparency", 1.0, 0.4)
	tween.tween_property(_facing_pivot, "scale", Vector3.ZERO, 0.2)
	await tween.finished
	visible = false

#endregion


## Floating texts for statuses that stuck on this unit after a hit.
func play_statuses_applied(statuses: Array[StatusData]) -> void:
	for status in statuses:
		_spawn_popup("¡%s!" % status.display_name, status.color, 0.35)
		if status.kind == StatusData.Kind.KNOCKUP:
			await _play_knockup()
	refresh_info()


## Thrown up in the air and back down.
func _play_knockup() -> void:
	var tween := create_tween()
	tween.tween_property(_body, "position:y", 0.9, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tween.finished


## Start-of-turn status effects (damage over time, lost turn, expiry).
func play_status_events(events: Array[StatusEvent]) -> void:
	for event in events:
		if event.damage > 0:
			_spawn_popup("%d" % event.damage, event.status.color)
			var flash := create_tween()
			flash.tween_property(_sprite, "modulate", event.status.color, 0.08)
			flash.tween_property(_sprite, "modulate", _base_modulate, 0.12)
			await flash.finished
		if event.skipped_turn:
			_spawn_popup("%s: pierde el turno" % event.status.display_name, event.status.color, 0.35)
		elif event.expired:
			_spawn_popup("Fin de %s" % event.status.display_name.to_lower(), Color(0.85, 0.88, 1.0), 0.35)
	refresh_info()


func _refresh_statuses() -> void:
	for child in _status_icons.get_children():
		child.queue_free()
	var tint := Color.WHITE
	var x := -0.14 * (unit.statuses.size() - 1)
	for status in unit.statuses:
		tint = tint.lerp(status.color, 0.45)
		if status.icon == null:
			continue
		var icon := Sprite3D.new()
		icon.texture = status.icon
		icon.pixel_size = 0.028
		icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		icon.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		icon.no_depth_test = true
		icon.render_priority = 7
		icon.shaded = false
		icon.position.x = x
		x += 0.28
		_status_icons.add_child(icon)
		var stacks := unit.get_stacks(status)
		if stacks > 1:
			var count := Label3D.new()
			count.text = str(stacks)
			count.pixel_size = 0.006
			count.font_size = 40
			count.outline_size = 10
			count.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			count.no_depth_test = true
			count.render_priority = 8
			count.modulate = status.color.lightened(0.4)
			count.position = Vector3(0.11, -0.09, 0.0)
			icon.add_child(count)
	_base_modulate = tint
	if unit.is_alive():
		_sprite.modulate = Color(tint, _sprite.modulate.a)


func _spawn_popup(text: String, color: Color, height_offset: float = 0.0) -> void:
	if damage_popup_scene == null:
		return
	var popup: DamagePopup = damage_popup_scene.instantiate()
	add_child(popup)
	popup.global_position = get_head_position() + Vector3.UP * (0.2 + height_offset)
	popup.show_text(text, color)


## Pop-in for summoned units (totems).
func play_appear() -> void:
	var tween := create_tween()
	_body.scale = Vector3(0.2, 0.2, 0.2)
	tween.tween_property(_body, "scale", Vector3(1.15, 1.15, 1.15), 0.14).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_body, "scale", Vector3.ONE, 0.1)
	await tween.finished


## Area shown on the ground for units with an aura, gently pulsing.
func _setup_aura() -> void:
	var aura := unit.data.aura
	_aura_disc.visible = aura != null
	if aura == null:
		return
	var size := aura.radius * 2.0 + 1.0
	_aura_disc.scale = Vector3(size, 1.0, size)
	_aura_disc.set_instance_shader_parameter(&"disc_color", aura.color)
	var pulse := create_tween().set_loops()
	pulse.tween_method(_set_aura_alpha.bind(aura.color), 1.0, 0.55, 1.2).set_trans(Tween.TRANS_SINE)
	pulse.tween_method(_set_aura_alpha.bind(aura.color), 0.55, 1.0, 1.2).set_trans(Tween.TRANS_SINE)


func _set_aura_alpha(factor: float, color: Color) -> void:
	_aura_disc.set_instance_shader_parameter(&"disc_color", Color(color, color.a * factor))


#region Sprite animation

## Plays [param state] (idle / walk / attack / hit) in the current view.
func _play_state(state: StringName) -> void:
	_state = state
	_apply_animation()


func _apply_animation() -> void:
	var frames := _sprite.sprite_frames
	var wanted := StringName("%s_%s" % [_state, _view])
	for candidate in [wanted, StringName("%s_front" % _state), StringName("idle_%s" % _view), &"idle_front"]:
		if frames.has_animation(candidate):
			if _sprite.animation != candidate or not _sprite.is_playing():
				_sprite.play(candidate)
				_fit_offset()
			return


func _on_animation_finished() -> void:
	# One-shot animations (attack, hit) go back to idle.
	if _state != &"idle" and _state != &"walk":
		_play_state(&"idle")


## Animations from UnitData.sprite_frames, or a minimal set made from the
## static sprites (idle_front / idle_side).
func _build_frames() -> SpriteFrames:
	if unit.data.sprite_frames != null:
		return unit.data.sprite_frames
	var frames := SpriteFrames.new()
	frames.rename_animation(&"default", &"idle_front")
	if unit.data.sprite != null:
		frames.add_frame(&"idle_front", unit.data.sprite)
	if unit.data.sprite_side != null:
		frames.add_animation(&"idle_side")
		frames.add_frame(&"idle_side", unit.data.sprite_side)
	return frames


## Feet on the unit origin whatever the frame height.
func _fit_offset() -> void:
	var texture := _sprite.sprite_frames.get_frame_texture(_sprite.animation, 0)
	if texture != null:
		_sprite.offset.y = texture.get_height() * 0.5

#endregion


## Picks the view and the flip from where the unit faces on screen:
## towards the camera = front view, away from it = side view (if the unit
## has one) flipped to the side it walks to. Units without a side view use
## their single sprite, drawn facing right and flipped when needed.
func _update_sprite_flip() -> void:
	if _camera == null or unit == null:
		return
	var facing := -_facing_pivot.global_basis.z
	var screen_x := facing.dot(_camera.global_basis.x)
	var away := facing.dot(-_camera.global_basis.z) > 0.0
	var has_side := _sprite.sprite_frames.has_animation(&"idle_side")
	var view := &"side" if away and has_side else &"front"
	if view != _view:
		_view = view
		_apply_animation()
	if view == &"side" or not has_side:
		if absf(screen_x) > 0.05:
			_sprite.flip_h = screen_x < 0.0
	else:
		_sprite.flip_h = false


## The starting weapon of the unit in its hand(s), if it is drawn.
func _setup_weapon() -> void:
	var weapon := unit.data.weapon
	if weapon == null or not weapon.is_drawn() or held_weapon_scene == null:
		return
	for off_hand in ([false, true] if weapon.dual else [false]):
		var held: HeldWeapon = held_weapon_scene.instantiate()
		_sprite.add_child(held)
		held.setup(weapon, unit.data, off_hand)
		_held_weapons.append(held)


## Melee weapons swing (wind-up, strike, back); bows and guns kick back.
func _animate_weapons() -> void:
	if _held_weapons.is_empty():
		return
	var kind := unit.data.weapon.kind
	var ranged := kind == WeaponData.Kind.BOW or kind == WeaponData.Kind.PISTOL
	for held in _held_weapons:
		var tween := create_tween()
		if ranged:
			tween.tween_property(held, "kick", Vector2(-2.0, 0.0), 0.04)
			tween.parallel().tween_property(held, "swing", -14.0, 0.04)
			tween.tween_property(held, "kick", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(held, "swing", 0.0, 0.18)
		else:
			tween.tween_property(held, "swing", -55.0, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(held, "swing", 85.0, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(held, "swing", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_weapons() -> void:
	if _held_weapons.is_empty():
		return
	var frame := _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	var side_view := _view == &"side"
	for held in _held_weapons:
		held.follow(_sprite, frame, side_view, _sprite.flip_h)


## The sprite is a vertical (Y-fixed) billboard and the camera looks down at
## it, so on screen it would look squashed by cos(pitch). Stretch it back so
## pixel art keeps square pixels whatever the camera pitch is.
func _compensate_camera_pitch() -> void:
	if _camera == null:
		return
	# The camera looks along -Z: when it looks down, its +Z axis points up.
	var down := clampf(_camera.global_basis.z.y, 0.0, 0.95)
	var stretch := 1.0 / sqrt(1.0 - down * down)
	_sprite.scale.y = stretch
	# Keep the floating info above the (now taller) sprite.
	_info_label.position.y = _label_base_y * stretch
	_status_icons.position.y = _icons_base_y * stretch
