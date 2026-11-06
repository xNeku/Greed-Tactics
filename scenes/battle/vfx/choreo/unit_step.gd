class_name UnitStep
extends VfxStep
## Acts on the user's sprite: vanish into shadow, reappear, or shake while charging.

enum Action { VANISH, APPEAR, CHARGE }

@export var action: Action = Action.CHARGE
@export_range(0.02, 2.0) var duration := 0.25
@export var glow := Color(1, 1, 1)


func run(ctx: ChoreoContext, _at: Vector3) -> void:
	match action:
		Action.VANISH:
			await ctx.user_view.fade_sprite(0.0, duration)
		Action.APPEAR:
			await ctx.user_view.fade_sprite(1.0, duration)
		Action.CHARGE:
			await ctx.user_view.play_charge(glow, duration)
