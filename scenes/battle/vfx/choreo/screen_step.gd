class_name ScreenStep
extends VfxStep
## Full-screen punch: colour flash, chromatic aberration and a tinted vignette.

@export var flash_color := Color(1, 1, 1)
@export_range(0.0, 1.0) var flash := 0.0
@export_range(0.0, 3.0) var aberration := 0.0
@export var tint_color := Color(0, 0, 0)
@export_range(0.0, 1.0) var tint := 0.0
@export_range(0.02, 3.0) var duration := 0.3
## Keep the tint until the end of the choreography (fades with the sky).
@export var hold_tint := false


func is_cinematic() -> bool:
	return true


func run(ctx: ChoreoContext, _at: Vector3) -> void:
	await ctx.screen_fx.pulse(flash_color, flash, aberration, tint_color, tint, duration, hold_tint)
	if hold_tint:
		ctx.on_finish(ctx.screen_fx.release_tint)
