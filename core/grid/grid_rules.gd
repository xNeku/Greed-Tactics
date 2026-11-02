class_name GridRules
extends RefCounted
## Pure grid rules: step legality/cost and attack orientation (GDD §3 and §5).

enum AttackSide { FRONT, SIDE, BACK }


## PM cost of stepping from [param from] to the orthogonal neighbour [param to].
## Returns -1 when the step is not allowed.
static func get_step_cost(grid: BattleGrid, rules: RulesConfig, from: Vector2i, to: Vector2i) -> int:
	if BattleGrid.manhattan(from, to) != 1 or not grid.is_walkable(to):
		return -1
	var climb := grid.get_height(to) - grid.get_height(from)
	if absi(climb) > rules.max_climb:
		return -1
	var cost := grid.get_terrain(to).move_cost
	if climb > 0:
		cost += climb * rules.climb_up_cost
	elif climb < 0:
		cost += -climb * rules.climb_down_cost
	return cost


## Side of the target that an attack coming from [param attacker_cell] hits.
##
## The relation is decided by the dominant axis between attacker and target,
## relative to where the target faces (ties count as SIDE).
## BACK additionally requires the cell right behind the target to be free:
## inside the map, walkable, reachable in height and not occupied by anyone but
## the attacker. Otherwise the target "has its back covered" and it is a SIDE hit.
## [param occupied] holds cells with units on them.
static func get_attack_side(
		grid: BattleGrid,
		rules: RulesConfig,
		attacker_cell: Vector2i,
		target_cell: Vector2i,
		target_facing: GridDir.Dir,
		occupied: Dictionary[Vector2i, bool]) -> AttackSide:
	var delta := attacker_cell - target_cell
	if delta == Vector2i.ZERO:
		return AttackSide.FRONT
	var forward := GridDir.to_vector(target_facing)
	var along := delta.x * forward.x + delta.y * forward.y
	var across := absi(delta.x * forward.y - delta.y * forward.x)
	if absi(along) <= across:
		return AttackSide.SIDE
	if along > 0:
		return AttackSide.FRONT
	var back_cell := target_cell - forward
	if is_back_covered(grid, rules, target_cell, back_cell, attacker_cell, occupied):
		return AttackSide.SIDE
	return AttackSide.BACK


static func is_back_covered(
		grid: BattleGrid,
		rules: RulesConfig,
		target_cell: Vector2i,
		back_cell: Vector2i,
		attacker_cell: Vector2i,
		occupied: Dictionary[Vector2i, bool]) -> bool:
	if not grid.is_walkable(back_cell):
		return true
	if absi(grid.get_height(back_cell) - grid.get_height(target_cell)) > rules.max_climb:
		return true
	return back_cell != attacker_cell and occupied.has(back_cell)
