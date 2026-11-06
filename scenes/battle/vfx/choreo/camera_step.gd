class_name CameraStep
extends VfxStep
## Cinematic camera: focus on the anchor, zoom in (distance factor) and/or shake.
## The zoom is released at the end of the choreography.

## < 1 zooms in (0.6 = 40% closer); 1 = keep the zoom.
@export_range(0.3, 1.5) var zoom := 1.0
@export var focus := true
@export_range(0.0, 1.0) var shake := 0.0


func is_cinematic() -> bool:
	return true


func run(ctx: ChoreoContext, at: Vector3) -> void:
	if focus:
		ctx.camera_rig.focus_on(at)
	if not is_equal_approx(zoom, 1.0):
		ctx.camera_rig.set_cinematic_zoom(zoom)
		ctx.on_finish(ctx.camera_rig.set_cinematic_zoom.bind(1.0))
	if shake > 0.0:
		ctx.camera_rig.shake(shake)
