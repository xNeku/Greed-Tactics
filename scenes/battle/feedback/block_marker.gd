class_name BlockMarker
extends Node3D
## Red cross shown where an action gets interrupted (push cut by an obstacle).

@export var pulse_speed := 6.0


func _process(_delta: float) -> void:
	if visible:
		var s := 1.0 + sin(Time.get_ticks_msec() / 1000.0 * pulse_speed) * 0.12
		scale = Vector3(s, s, s)
