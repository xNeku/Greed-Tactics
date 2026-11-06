class_name ParticlesStep
extends VfxStep
## A burst or a rain of square "pixel" particles (VfxBurst), configured here.

enum Shape { POINT, SPHERE, AREA_RAIN, CONVERGE }

@export var shape: Shape = Shape.POINT
@export var color_start := Color(1.0, 0.8, 0.3)
@export var color_end := Color(0.6, 0.1, 0.05, 0.0)
@export_range(1, 600) var amount := 40
@export_range(0.05, 5.0) var lifetime := 0.6
@export_range(0.0, 30.0) var speed := 4.0
@export_range(0.0, 180.0) var spread := 180.0
@export var direction := Vector3.UP
@export var gravity := Vector3(0, -6, 0)
@export_range(0.01, 0.5) var size := 0.07
## > 1 makes the start colour glow (bloom).
@export_range(0.5, 6.0) var brightness := 2.0
## Additive (fire, light, magic) or normal blending (dust, smoke).
@export var additive := true
@export_range(0.0, 2.0) var radius := 0.3
## Emit continuously for this long (0 = one burst).
@export_range(0.0, 5.0) var emit_time := 0.0
## Height the rain falls from (AREA_RAIN).
@export_range(0.0, 12.0) var rain_height := 6.0
@export var scene: PackedScene = preload("res://scenes/battle/vfx/effects/vfx_burst.tscn")


func run(ctx: ChoreoContext, at: Vector3) -> void:
	var burst: VfxBurst = scene.instantiate()
	var extents := ctx.area_extents() if shape == Shape.AREA_RAIN else Vector3(radius, radius, radius)
	var origin := at + (Vector3.UP * rain_height if shape == Shape.AREA_RAIN else Vector3.ZERO)
	ctx.spawn(burst, origin)
	burst.play(self, extents)
	await ctx.wait(emit_time + lifetime)
