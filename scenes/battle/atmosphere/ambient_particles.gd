class_name AmbientParticles
extends CPUParticles3D
## Atmosphere particles (fireflies, dust, motes) that float over the whole map.
## The zone picks the scene; BattleController calls [method cover].

## Height of the particle volume above the ground.
@export var volume_height := 3.0
## Particles per map cell.
@export var density := 0.25


func cover(bounds: AABB) -> void:
	var size := Vector3(bounds.size.x, volume_height, bounds.size.z)
	global_position = bounds.position + size * 0.5 + Vector3.UP * 0.4
	emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	emission_box_extents = size * 0.5
	amount = maxi(8, roundi(bounds.size.x * bounds.size.z * density))
	preprocess = lifetime
	emitting = true
