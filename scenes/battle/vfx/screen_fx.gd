class_name ScreenFx
extends CanvasLayer
## Full-screen skill effects (flash, chromatic aberration, tinted vignette).
## Hidden while idle so it costs nothing.

@onready var _rect: ColorRect = $Rect

var _held_tint := 0.0
var _busy := 0


func _ready() -> void:
	_rect.visible = false


## Flash and aberration go back to 0 over [param duration]; the tint stays when
## [param hold_tint] until release_tint().
func pulse(flash_color: Color, flash: float, aberration: float, tint_color: Color, tint: float,
		duration: float, hold_tint: bool) -> void:
	var material := _rect.material as ShaderMaterial
	_busy += 1
	_rect.visible = true
	material.set_shader_parameter(&"flash_color", flash_color)
	material.set_shader_parameter(&"tint_color", tint_color)
	if hold_tint:
		_held_tint = maxf(_held_tint, tint)
	var tween := create_tween().set_parallel().set_ignore_time_scale()
	tween.tween_method(_set_param.bind(&"flash"), flash, 0.0, duration)
	tween.tween_method(_set_param.bind(&"aberration"), aberration, 0.0, duration)
	if hold_tint:
		tween.tween_method(_set_param.bind(&"tint"), 0.0, tint, minf(duration, 0.35))
	elif tint > 0.0:
		tween.tween_method(_set_param.bind(&"tint"), maxf(tint, _held_tint), _held_tint, duration)
	await tween.finished
	_busy -= 1
	_hide_if_idle()


func release_tint() -> void:
	var start := _held_tint
	_held_tint = 0.0
	var tween := create_tween().set_ignore_time_scale()
	tween.tween_method(_set_param.bind(&"tint"), start, 0.0, 0.45)
	await tween.finished
	_hide_if_idle()


func _set_param(value: float, parameter: StringName) -> void:
	(_rect.material as ShaderMaterial).set_shader_parameter(parameter, value)


func _hide_if_idle() -> void:
	if _busy <= 0 and _held_tint <= 0.0:
		_rect.visible = false
