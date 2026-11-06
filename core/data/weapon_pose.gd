class_name WeaponPose
extends Resource
## How a weapon sits in the hand in one view (front or side), as placed in the
## armory (tools/armory). Values are in the hero's sprite pixel space, y down.

## Clockwise rotation on screen, in degrees, around the grip.
@export_range(-360.0, 360.0) var rotation_degrees: float = 0.0
## Size multiplier of the weapon pixels (they stay square: never re-sampled
## into the hero's grid).
@export_range(0.25, 3.0) var scale: float = 1.0
## Mirrored horizontally.
@export var flip: bool = false
## Drawn behind the body instead of in front.
@export var behind: bool = false


## The same pose seen in a mirror (the other hand of a dual weapon).
func mirrored() -> WeaponPose:
	var pose := WeaponPose.new()
	pose.rotation_degrees = -rotation_degrees
	pose.scale = scale
	pose.flip = not flip
	pose.behind = behind
	return pose
