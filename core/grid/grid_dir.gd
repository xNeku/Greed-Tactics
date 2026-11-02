class_name GridDir
extends RefCounted
## Orthogonal directions and helpers.
##
## Grid convention: x grows to the EAST (world +X) and y grows to the SOUTH
## (world +Z). A Node3D looks along its local -Z, so NORTH has yaw 0.

enum Dir { NORTH, EAST, SOUTH, WEST }

const ALL: Array[Dir] = [Dir.NORTH, Dir.EAST, Dir.SOUTH, Dir.WEST]

const _VECTORS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
]


static func to_vector(dir: Dir) -> Vector2i:
	return _VECTORS[dir]


static func opposite(dir: Dir) -> Dir:
	return ((dir + 2) % 4) as Dir


## Direction of the dominant axis of [param delta]. Ties favour the x axis.
static func from_delta(delta: Vector2i, fallback: Dir = Dir.SOUTH) -> Dir:
	if delta == Vector2i.ZERO:
		return fallback
	if absi(delta.x) >= absi(delta.y):
		return Dir.EAST if delta.x > 0 else Dir.WEST
	return Dir.SOUTH if delta.y > 0 else Dir.NORTH


## Y rotation (radians) that makes a Node3D look towards [param dir].
static func to_yaw(dir: Dir) -> float:
	return -float(dir) * PI * 0.5


static func to_world(dir: Dir) -> Vector3:
	var v := to_vector(dir)
	return Vector3(v.x, 0.0, v.y)


static func dir_name(dir: Dir) -> String:
	return Dir.keys()[dir]
