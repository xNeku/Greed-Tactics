class_name SkyStep
extends VfxStep
## Darkens and tints the whole scene (sky, ambient light, sun, fog). Undone at the end.

@export var tint := Color(0.6, 0.1, 0.05)
## 0 = normal light, 1 = almost black.
@export_range(0.0, 1.0) var darkness := 0.6
## Volumetric fog density (Forward+ only): makes skill lights show as glowing beams.
@export_range(0.0, 0.2) var volumetric_fog := 0.03
@export_range(0.0, 3.0) var glow_boost := 0.6
@export_range(0.05, 3.0) var fade_in := 0.35


func run(ctx: ChoreoContext, _at: Vector3) -> void:
	ctx.save_sky()
	var env := ctx.environment
	var keep := 1.0 - darkness
	if volumetric_fog > 0.0:
		env.volumetric_fog_enabled = true
		env.volumetric_fog_albedo = tint.lightened(0.4)
	env.fog_enabled = true
	var tween := ctx.root.create_tween().set_parallel().set_ignore_time_scale()
	tween.tween_property(env, "background_color", env.background_color.lerp(tint.darkened(0.6), darkness), fade_in)
	tween.tween_property(env, "ambient_light_energy", env.ambient_light_energy * keep, fade_in)
	tween.tween_property(env, "ambient_light_color", env.ambient_light_color.lerp(tint, darkness * 0.7), fade_in)
	tween.tween_property(env, "fog_light_color", tint.darkened(0.3), fade_in)
	tween.tween_property(env, "fog_density", maxf(env.fog_density, 0.01 * darkness), fade_in)
	tween.tween_property(env, "volumetric_fog_density", volumetric_fog, fade_in)
	tween.tween_property(env, "glow_intensity", env.glow_intensity + glow_boost, fade_in)
	tween.tween_property(ctx.sun, "light_energy", ctx.sun.light_energy * keep * 0.8, fade_in)
	tween.tween_property(ctx.sun, "light_color", ctx.sun.light_color.lerp(tint, darkness), fade_in)
	await tween.finished
