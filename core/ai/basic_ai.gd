class_name BasicAI
extends RefCounted
## Simple greedy AI used by enemies (and by autoplay / companions later).
##
## Call [method decide] repeatedly during the unit's turn until it returns
## END_TURN. Priorities:
##   1. Use the best skill from the current cell (expected damage, kills,
##      backstabs; motion skills included).
##   2. Move to the cell with the best attack available after moving.
##   3. Walk towards the nearest opponent.
##   4. End the turn facing the nearest opponent.

const KILL_BONUS := 50.0
const MOVE_COST_WEIGHT := 0.01


func decide(combat: CombatState, unit: UnitState) -> AiAction:
	var attack := best_attack_from(combat, unit, unit.cell)
	if not attack.is_empty():
		return AiAction.use_skill(attack.skill, attack.cell)

	if unit.pm > 0:
		var destination := _best_destination(combat, unit)
		if destination != unit.cell:
			return AiAction.move(destination)

	return AiAction.end_turn(_facing_towards_nearest_opponent(combat, unit))


## Returns {skill, cell, score} or an empty dictionary if nothing is worth it.
func best_attack_from(combat: CombatState, unit: UnitState, from_cell: Vector2i) -> Dictionary:
	var opponents := _opponent_cells(combat, unit)
	var best := {}
	for skill in unit.data.skills:
		var effective := unit.get_effective(skill)
		if not effective.deals_damage() or not unit.can_afford(effective):
			continue
		var reach := 2 * effective.area_size + effective.explode_radius
		for cell in combat.get_targetable_cells(unit, skill, from_cell):
			if not _near_any(cell, opponents, reach):
				continue
			var score := 0.0
			for preview in combat.preview_skill(unit, skill, from_cell, cell):
				var value := preview.damage * preview.hit_chance / 100.0
				if preview.damage >= preview.target.hp:
					value += KILL_BONUS
				score += value if preview.target.is_enemy_of(unit) else -value
			# Spending rage/mana/cooldowns should be worth it.
			score -= effective.rage_cost * 0.1 + effective.mp_cost * 0.2 + effective.cooldown * 1.5
			if score > 0.0 and (best.is_empty() or score > best.score):
				best = {"skill": skill, "cell": cell, "score": score}
	return best


func _best_destination(combat: CombatState, unit: UnitState) -> Vector2i:
	var reach := combat.get_reach_map(unit)
	var destinations := reach.get_destinations()

	var best_cell := unit.cell
	var best_score := 0.0
	for cell in destinations:
		var attack := best_attack_from(combat, unit, cell)
		if attack.is_empty():
			continue
		var score: float = attack.score - reach.get_cost(cell) * MOVE_COST_WEIGHT
		if score > best_score:
			best_score = score
			best_cell = cell
	if best_cell != unit.cell:
		return best_cell

	return _closest_to_opponents(combat, unit, destinations)


func _closest_to_opponents(combat: CombatState, unit: UnitState, destinations: Array[Vector2i]) -> Vector2i:
	var field := _distance_to_opponents(combat, unit)
	var best_cell := unit.cell
	var best_distance: int = field.get(unit.cell, 1 << 20)
	for cell in destinations:
		var distance: int = field.get(cell, 1 << 20)
		if distance < best_distance:
			best_distance = distance
			best_cell = cell
	return best_cell


## Walking distance from every cell to the closest opponent.
func _distance_to_opponents(combat: CombatState, unit: UnitState) -> Dictionary[Vector2i, int]:
	var blocked: Dictionary[Vector2i, bool] = {}
	var opponents: Array[UnitState] = []
	for other in combat.get_living_units():
		if other.is_enemy_of(unit):
			opponents.append(other)
			blocked[other.cell] = true
	var merged: Dictionary[Vector2i, int] = {}
	for opponent in opponents:
		var others := blocked.duplicate()
		others.erase(opponent.cell)
		var field := Pathfinder.distance_field(combat.grid, combat.rules, opponent.cell, others)
		for cell in field:
			if not merged.has(cell) or field[cell] < merged[cell]:
				merged[cell] = field[cell]
	return merged


func _facing_towards_nearest_opponent(combat: CombatState, unit: UnitState) -> GridDir.Dir:
	var nearest: UnitState = null
	for other in combat.get_living_units():
		if not other.is_enemy_of(unit):
			continue
		if nearest == null or BattleGrid.manhattan(unit.cell, other.cell) < BattleGrid.manhattan(unit.cell, nearest.cell):
			nearest = other
	if nearest == null:
		return unit.facing
	return GridDir.from_delta(nearest.cell - unit.cell, unit.facing)


func _opponent_cells(combat: CombatState, unit: UnitState) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for other in combat.get_living_units():
		if other.is_enemy_of(unit):
			cells.append(other.cell)
	return cells


func _near_any(cell: Vector2i, cells: Array[Vector2i], distance: int) -> bool:
	for other in cells:
		if BattleGrid.manhattan(cell, other) <= distance:
			return true
	return false
