class_name ReachMap
extends RefCounted
## Result of a movement search: every cell reachable with the PM budget, its
## cost, and how to get there. Built by Pathfinder.

var origin: Vector2i
## Cheapest PM cost to every visited cell (including pass-through-only cells).
var costs: Dictionary[Vector2i, int] = {}

var _came_from: Dictionary[Vector2i, Vector2i] = {}
var _occupied: Dictionary[Vector2i, bool] = {}


func _init(p_origin: Vector2i, p_occupied: Dictionary[Vector2i, bool]) -> void:
	origin = p_origin
	_occupied = p_occupied
	costs[origin] = 0


## True if the unit can END its movement on [param cell].
func can_stop_at(cell: Vector2i) -> bool:
	return cell != origin and costs.has(cell) and not _occupied.has(cell)


func get_destinations() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in costs:
		if can_stop_at(cell):
			result.append(cell)
	return result


func get_cost(cell: Vector2i) -> int:
	return costs.get(cell, -1)


## Steps from origin (excluded) to [param cell] (included). Empty if unreachable.
func get_path_to(cell: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not costs.has(cell) or cell == origin:
		return path
	var current := cell
	while current != origin:
		path.push_front(current)
		current = _came_from[current]
	return path


func add_step(cell: Vector2i, cost: int, previous: Vector2i) -> void:
	costs[cell] = cost
	_came_from[cell] = previous
