class_name HeldWeapon
extends MeshInstance3D
## One weapon drawn in a unit's hand (the second copy of a dual weapon is
## another HeldWeapon). UnitView updates it every frame from the body sprite:
## current view, frame size, mirroring and colour.

## Distance from the body plane, in world units (in front or behind).
@export var depth_bias := 0.012

var _weapon: WeaponData
var _unit_data: UnitData
var _off_hand := false
var _material: ShaderMaterial


func setup(weapon: WeaponData, unit_data: UnitData, off_hand: bool) -> void:
	_weapon = weapon
	_unit_data = unit_data
	_off_hand = off_hand
	_material = (material_override as ShaderMaterial).duplicate() as ShaderMaterial
	material_override = _material
	_material.set_shader_parameter(&"weapon_texture", weapon.sprite)
	_material.set_shader_parameter(&"weapon_size", Vector2(weapon.sprite.get_size()))
	_material.set_shader_parameter(&"grip", Vector2(weapon.grip))


## [param body] is the unit sprite; [param side_view] whether it shows the side view.
func follow(body: SpriteBase3D, frame: Texture2D, side_view: bool, flipped: bool) -> void:
	if _weapon == null or frame == null:
		visible = false
		return
	var size := Vector2i(frame.get_size())
	var hand := _unit_data.get_off_hand(side_view, size.x) if _off_hand else _unit_data.get_hand(side_view)
	visible = hand != UnitData.NO_HAND
	if not visible:
		return
	var pose := _weapon.get_off_pose(side_view) if _off_hand else _weapon.get_pose(side_view)
	_material.set_shader_parameter(&"body_size", Vector2(size))
	_material.set_shader_parameter(&"hand", Vector2(hand))
	_material.set_shader_parameter(&"rotation", deg_to_rad(pose.rotation_degrees))
	_material.set_shader_parameter(&"weapon_scale", pose.scale)
	_material.set_shader_parameter(&"flip", -1.0 if pose.flip else 1.0)
	_material.set_shader_parameter(&"body_flip", -1.0 if flipped else 1.0)
	_material.set_shader_parameter(&"pixel_size", body.pixel_size)
	_material.set_shader_parameter(&"depth_bias", -depth_bias if pose.behind else depth_bias)
	_material.set_shader_parameter(&"tint", body.modulate)
