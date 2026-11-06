class_name BeamStep
extends VfxStep
## A glowing projectile with a light and a pixel trail flying from the user to
## the anchor (wait = true holds the hits until it lands).

@export var color := Color(1.0, 0.95, 0.7)
@export_range(1.0, 80.0) var speed := 30.0
@export_range(0.02, 0.5) var thickness := 0.08
@export_range(0.0, 3.0) var arc_height := 0.15
@export var scene: PackedScene = preload("res://scenes/battle/vfx/effects/vfx_beam.tscn")


func run(ctx: ChoreoContext, at: Vector3) -> void:
	var beam: VfxBeam = scene.instantiate()
	var from := ctx.user_view.get_cast_position()
	ctx.spawn(beam, from)
	await beam.fly(from, at, color, speed, thickness, arc_height)
