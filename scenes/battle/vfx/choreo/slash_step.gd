class_name SlashStep
extends VfxStep
## Melee swing arcs (the VfxSlash crescent); several crossing ones for flurries.

@export var color := Color(1, 1, 1)
@export_range(1, 4) var count := 1
@export_range(0.05, 1.0) var duration := 0.18
@export_range(0.5, 3.0) var size := 1.0
@export var scene: PackedScene = preload("res://scenes/battle/vfx/vfx_slash.tscn")


func run(ctx: ChoreoContext, at: Vector3) -> void:
	for i in count:
		var slash: VfxSlash = scene.instantiate()
		ctx.spawn(slash, at)
		slash.scale = Vector3.ONE * size
		slash.rotation.z = deg_to_rad(-35.0 + 70.0 * i)
		slash.play(color, duration)
		await ctx.wait(duration * 0.45)
