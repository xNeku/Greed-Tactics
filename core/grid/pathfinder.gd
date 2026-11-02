class_name Pathfinder
extends RefCounted
## Dijkstra over the orthogonal grid using GridRules step costs.
##
## [param blocked] = cells the mover cannot enter (enemies).
## [param occupied] = cells the mover can cross but not stop on (any unit).


static func find_reachable(
		grid: BattleGrid,
		rules: RulesConfig,
		start: Vector2i,
		budget: int,
		blocked: Dictionary[Vector2i, bool] = {},
		occupied: Dictionary[Vector2i, bool] = {}) -> ReachMap:
	var reach := ReachMap.new(start, occupied)
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var current := _pop_cheapest(frontier, reach.costs)
		var current_cost := reach.costs[current]
		for dir in GridDir.ALL:
			var next := current + GridDir.to_vector(dir)
			if blocked.has(next):
				continue
			var step := GridRules.get_step_cost(grid, rules, current, next)
			if step < 0:
				continue
			var new_cost := current_cost + step
			if new_cost > budget:
				continue
			if reach.costs.has(next) and reach.costs[next] <= new_cost:
				continue
			reach.add_step(next, new_cost, current)
			if not frontier.has(next):
				frontier.append(next)
	return reach


## Unbounded walking distance (in PM) from [param start] to every reachable cell.
## Used by the AI to approach targets that are out of range this turn.
static func distance_field(
		grid: BattleGrid,
		rules: RulesConfig,
		start: Vector2i,
		blocked: Dictionary[Vector2i, bool] = {}) -> Dictionary[Vector2i, int]:
	var reach := find_reachable(grid, rules, start, 1 << 20, blocked)
	return reach.costs


static func _pop_cheapest(frontier: Array[Vector2i], costs: Dictionary[Vector2i, int]) -> Vector2i:
	var best_index := 0
	for i in range(1, frontier.size()):
		if costs[frontier[i]] < costs[frontier[best_index]]:
			best_index = i
	var cell := frontier[best_index]
	frontier.remove_at(best_index)
	return cell
