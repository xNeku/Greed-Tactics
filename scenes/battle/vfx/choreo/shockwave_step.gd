class_name ShockwaveStep
extends VfxStep
## An expanding ring on the ground (landings, explosions).

@export var color := Color(1.0, 0.9, 0.7)
@export_range(0.5, 8.0) var radius := 2.5
@export_range(0.05, 2.0) var duration := 0.45
@export var scene: PackedScene = preload("res://scenes/battle/vfx/effects/vfx_shockwave.tscn")


func run(ctx: ChoreoContext, at: Vector3) -> void:
	var wave: VfxShockwave = scene.instantiate()
	ctx.spawn(wave, at)
	await wave.play(color, radius, duration)
