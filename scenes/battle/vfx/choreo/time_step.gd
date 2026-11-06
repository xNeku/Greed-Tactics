class_name TimeStep
extends VfxStep
## Hit stop (scale near 0 for a few frames) or slow motion, in real seconds.

@export_range(0.0, 1.0) var time_scale := 0.05
@export_range(0.01, 2.0) var duration := 0.08


func run(ctx: ChoreoContext, _at: Vector3) -> void:
	var previous := Engine.time_scale
	Engine.time_scale = previous * time_scale
	await ctx.wait(duration)
	Engine.time_scale = previous
