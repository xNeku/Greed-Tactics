class_name ProjectileStep
extends VfxStep
## A projectile with a ProjectileLook flying from the user to the anchor
## (wait = true holds the hits until it lands). The impact itself is left to
## the IMPACT steps of the choreography.

@export var look: ProjectileLook
## Arc height in world units.
@export_range(0.0, 3.0) var arc_height := 0.1
@export var scene: PackedScene = preload("res://scenes/battle/vfx/projectiles/pixel_projectile.tscn")


func run(ctx: ChoreoContext, at: Vector3) -> void:
	if look == null:
		return
	var projectile: PixelProjectile = scene.instantiate()
	var from := ctx.user_view.get_cast_position()
	ctx.spawn(projectile, from)
	var weapon := ctx.user_view.unit.data.weapon
	projectile.setup(look, weapon.sprite if weapon != null else null)
	await projectile.fly(from, at, arc_height, clampf(from.distance_to(at) / look.speed, 0.05, 1.4))
