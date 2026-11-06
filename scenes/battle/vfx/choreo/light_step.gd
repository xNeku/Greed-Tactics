class_name LightStep
extends VfxStep
## A dynamic light that lights the terrain and units around it (and the
## volumetric fog), fades in, holds (optionally flickering) and fades out.

@export var color := Color(1.0, 0.55, 0.2)
@export_range(0.0, 40.0) var energy := 6.0
@export_range(0.5, 20.0) var light_range := 5.0
@export_range(0.0, 3.0) var fade_in := 0.08
@export_range(0.0, 5.0) var hold := 0.4
@export_range(0.0, 3.0) var fade_out := 0.5
## 0 = steady, 1 = fire-like flicker.
@export_range(0.0, 1.0) var flicker := 0.0
@export var shadows := true


func run(ctx: ChoreoContext, at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.omni_range = light_range
	light.light_energy = 0.0
	light.shadow_enabled = shadows
	light.light_volumetric_fog_energy = 2.0
	ctx.spawn(light, at)
	var tween := light.create_tween().set_ignore_time_scale()
	tween.tween_property(light, "light_energy", energy, fade_in)
	if flicker > 0.0:
		var steps := maxi(1, int(hold / 0.06))
		for i in steps:
			tween.tween_property(light, "light_energy", energy * randf_range(1.0 - flicker * 0.6, 1.0 + flicker * 0.3), 0.06)
	else:
		tween.tween_interval(hold)
	tween.tween_property(light, "light_energy", 0.0, fade_out)
	tween.tween_callback(light.queue_free)
	await tween.finished
