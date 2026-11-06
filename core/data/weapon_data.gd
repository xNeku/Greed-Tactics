class_name WeaponData
extends Resource
## A weapon a hero carries (GDD §4.5): its sprite, where it is held and how it
## is posed in each view. Placed by hand in the armory (tools/armory), then
## imported with tools/armory/import_weapons.py. Stats and basic attack come
## later (GT-277).

enum Kind { FISTS, DAGGER, SWORD, SABRE, GREATSWORD, AXE, GREATAXE, HAMMER, BOW, PISTOL, STAFF, WAND, MAGIC_HANDS }

@export var id: StringName = &""
@export var display_name: String = ""
@export var kind: Kind = Kind.SWORD
@export_multiline var description: String = ""
## Pixel art at game scale. Empty for weapons that are not drawn (fists, magic hands).
@export var sprite: Texture2D
## Pixel of [member sprite] that sits in the hand.
@export var grip: Vector2i = Vector2i.ZERO
@export var front_pose: WeaponPose
@export var side_pose: WeaponPose
## One in each hand: the second copy is the mirror of the first in the front
## view, and peeks out behind the body in the side view.
@export var dual: bool = false


func is_drawn() -> bool:
	return sprite != null


func get_pose(side_view: bool) -> WeaponPose:
	var pose := side_pose if side_view else front_pose
	return pose if pose != null else WeaponPose.new()


## Pose of the second copy of a dual weapon.
func get_off_pose(side_view: bool) -> WeaponPose:
	var pose := get_pose(side_view)
	if not side_view:
		return pose.mirrored()
	var behind := pose.duplicate() as WeaponPose
	behind.behind = true
	return behind
