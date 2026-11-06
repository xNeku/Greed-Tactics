class_name DamagePopup
extends Label3D
## Floating combat text. [method show_hit] pops a damage number: it punches in
## big, flashes white, flies off in a little arc and fades; criticals are
## bigger, golden, shiver and carry a "¡CRÍTICO!" tag. Consecutive hits of a
## multi-strike skill fan out so every number reads. [method show_text] is the
## plain rising text (statuses, misses, buffs).

const CRIT_COLOR := Color(1.0, 0.78, 0.2)
const CRIT_OUTLINE := Color(0.45, 0.08, 0.04)

@export var rise := 0.7
@export var duration := 0.9
## Seconds a damage number lives.
@export var hit_duration := 1.05


func show_text(value: String, color: Color) -> void:
	text = value
	modulate = color
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y + rise, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	tween.chain().tween_callback(queue_free)


## [param weight] 0..1 = share of the target's max HP (bigger numbers for big
## hits). [param index] = place in a streak of hits (fans them out).
func show_hit(amount: int, critical: bool, weight: float, index: int, color: Color = Color.WHITE) -> void:
	text = ("%d!" if critical else "%d") % amount
	var final_color := CRIT_COLOR if critical else color
	if critical:
		outline_modulate = CRIT_OUTLINE
	var size := (0.85 + clampf(weight, 0.0, 0.6) * 0.7) * (1.4 if critical else 1.0)
	var side := (1.0 if index % 2 == 0 else -1.0) if index > 0 else (1.0 if randf() < 0.5 else -1.0)
	var start := position + Vector3(side * 0.36 * signf(index), 0.24 * mini(index, 4), 0.0)
	position = start
	scale = Vector3.ONE * 0.2
	modulate = Color(1.6, 1.6, 1.6)
	# Punch in, overshoot, settle.
	var pop := create_tween()
	pop.tween_property(self, "scale", Vector3.ONE * size * 1.45, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pop.tween_property(self, "scale", Vector3.ONE * size, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_interval(hit_duration * 0.45)
	pop.tween_property(self, "scale", Vector3.ONE * size * 0.7, hit_duration * 0.3)
	# White flash into its colour, then fade.
	var tint := create_tween()
	tint.tween_property(self, "modulate", final_color, 0.14)
	tint.tween_interval(hit_duration * 0.55)
	tint.tween_property(self, "modulate:a", 0.0, hit_duration * 0.3)
	# Flight: up and a bit to the side, slowing down.
	var fly := create_tween().set_parallel()
	var drift := side * randf_range(0.12, 0.22)
	fly.tween_property(self, "position:x", start.x + drift, hit_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fly.tween_property(self, "position:y", start.y + 0.32, hit_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if critical:
		_shiver()
		_tag("¡CRÍTICO!", CRIT_COLOR)
	get_tree().create_timer(hit_duration + 0.05).timeout.connect(queue_free)


## Criticals shiver for a moment as they land.
func _shiver() -> void:
	var tween := create_tween()
	for i in 6:
		tween.tween_property(self, "offset", Vector2(randf_range(-6, 6), randf_range(-4, 4)), 0.025)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.03)


## Small label riding above the number.
func _tag(value: String, color: Color) -> void:
	var tag := Label3D.new()
	tag.text = value
	tag.font = font
	tag.font_size = 30
	tag.outline_size = 9
	tag.outline_modulate = CRIT_OUTLINE
	tag.pixel_size = pixel_size
	tag.billboard = billboard
	tag.no_depth_test = true
	tag.render_priority = render_priority
	tag.outline_render_priority = outline_render_priority
	tag.modulate = color
	tag.position = Vector3(0.0, 0.2, 0.0)
	add_child(tag)
	var fade := tag.create_tween()
	fade.tween_interval(hit_duration * 0.7)
	fade.tween_property(tag, "modulate:a", 0.0, hit_duration * 0.25)
