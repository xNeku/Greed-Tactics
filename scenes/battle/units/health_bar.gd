class_name HealthBar
extends Node3D
## Overhead health bar of a unit (pixel art, health_bar.gdshader) with its HP
## number. It only shows while it matters: hovered, active turn, or for a
## moment after the unit is hit or healed. Damage drops the bar at once and
## leaves a ghost that drains after a short delay; heals fill a light part
## first. The number rolls to the new value.

## HP per tick mark on the bar.
@export var hp_per_tick := 25
@export var ghost_delay := 0.35
@export var ghost_drain := 0.45
## Seconds the bar stays after a hit or heal.
@export var linger := 1.8
@export var fade_time := 0.18

@onready var _bar: MeshInstance3D = $Bar
@onready var _number: Label3D = $Number

var hovered := false
var active := false
## Show it anyway (hold Alt to see every bar).
var forced := false

var _material: ShaderMaterial
var _max_hp := 1
var _hp := 1
var _shown_hp := 1.0
var _ghost := 1.0
var _alpha := 0.0
var _linger_left := 0.0
var _ghost_tween: Tween
var _number_tween: Tween
var _shake_tween: Tween


func setup(max_hp: int, hp: int, player: bool) -> void:
	_material = (_bar.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	_bar.material_override = _material
	if player:
		_material.set_shader_parameter(&"fill_color", Color(0.42, 0.9, 0.45))
		_material.set_shader_parameter(&"fill_dark", Color(0.2, 0.55, 0.28))
	else:
		_material.set_shader_parameter(&"fill_color", Color(0.95, 0.32, 0.3))
		_material.set_shader_parameter(&"fill_dark", Color(0.6, 0.15, 0.16))
	_max_hp = maxi(1, max_hp)
	_hp = hp
	_shown_hp = hp
	_ghost = _ratio(hp)
	_apply()
	_set_alpha(0.0)


func get_shown_hp() -> int:
	return _hp


## Moves the bar to [param hp] (of [param max_hp]). Animated: damage leaves a
## draining ghost and a flash, heals fill first; the bar shows for a while.
func set_hp(hp: int, max_hp: int, animate: bool = true) -> void:
	var previous := _hp
	_max_hp = maxi(1, max_hp)
	_hp = clampi(hp, 0, _max_hp)
	if not animate or previous == _hp:
		_shown_hp = _hp
		_ghost = _ratio(_hp)
		_apply()
		return
	_linger_left = linger
	if _ghost_tween != null:
		_ghost_tween.kill()
	_ghost_tween = create_tween()
	if _hp < previous:
		# Ghost starts where the bar was, flashes, waits, then drains.
		_ghost = maxf(_ghost, _ratio(previous))
		_ghost_tween.tween_method(_set_flash, 1.0, 0.0, 0.18)
		_ghost_tween.tween_interval(maxf(ghost_delay - 0.18, 0.0))
		_ghost_tween.tween_method(_set_ghost, _ghost, _ratio(_hp), ghost_drain).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_shake(clampf(float(previous - _hp) / _max_hp * 3.0, 0.3, 1.0))
	else:
		# Heal: the new part shows light first, then the bar fills to it.
		_ghost = _ratio(previous)
		_ghost_tween.tween_method(_set_ghost, _ghost, _ratio(_hp), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _number_tween != null:
		_number_tween.kill()
	_number_tween = create_tween()
	_number_tween.tween_method(_set_shown_hp, _shown_hp, float(_hp), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_apply()


func _process(delta: float) -> void:
	# Face the camera so the number sits right of the bar on screen.
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		var keep := global_basis.get_scale()
		global_basis = camera.global_basis.orthonormalized().scaled(keep)
	_linger_left = maxf(_linger_left - delta, 0.0)
	var want := 1.0 if hovered or active or forced or _linger_left > 0.0 else 0.0
	if not is_equal_approx(_alpha, want):
		_set_alpha(move_toward(_alpha, want, delta / fade_time))
	if _material != null:
		var low := _ratio(_hp) <= 0.3 and _hp > 0
		_material.set_shader_parameter(&"low_pulse", (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)) if low else 0.0)


func _ratio(hp: float) -> float:
	return clampf(hp / _max_hp, 0.0, 1.0)


func _apply() -> void:
	_material.set_shader_parameter(&"hp", _ratio(_hp))
	_material.set_shader_parameter(&"ghost", _ghost)
	_material.set_shader_parameter(&"tick", clampf(float(hp_per_tick) / _max_hp, 0.0, 1.0))
	_number.text = "%d" % roundi(_shown_hp)


func _set_ghost(value: float) -> void:
	_ghost = value
	_material.set_shader_parameter(&"ghost", value)


func _set_flash(value: float) -> void:
	_material.set_shader_parameter(&"flash", value)


func _set_shown_hp(value: float) -> void:
	_shown_hp = value
	_number.text = "%d" % roundi(value)


func _set_alpha(value: float) -> void:
	_alpha = value
	visible = value > 0.001
	if _material != null:
		_material.set_shader_parameter(&"alpha", value)
	_number.modulate.a = value
	_number.outline_modulate.a = value


## A short horizontal shiver, stronger for bigger chunks.
func _shake(strength: float) -> void:
	if _shake_tween != null:
		_shake_tween.kill()
	_shake_tween = create_tween()
	for i in 4:
		var side := (1.0 if i % 2 == 0 else -1.0) * 0.035 * strength * (1.0 - i * 0.22)
		_shake_tween.tween_property(_bar, "position:x", side, 0.03)
	_shake_tween.tween_property(_bar, "position:x", 0.0, 0.04)
