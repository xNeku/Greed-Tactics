class_name BasicAI
extends RefCounted
## Tactical AI used by enemies (and by autoplay). Weights come from the unit's
## AiProfile (UnitData.ai_profile) or a default one.
##
## Call [method decide] repeatedly during the unit's turn until it returns
## END_TURN. Each call:
##   1. Builds a threat map: how much damage the opponents could deal to each
##      cell next turn (their movement + skill range + damage).
##   2. Scores every (move, skill, target) combination: expected damage, kills,
##      wounded/dangerous targets, statuses, resource costs and the threat of
##      the cell where the unit ends up.
##   3. Uses the skill now, moves to set up the best one, or repositions
##      (approach for melee, keep distance for ranged, avoid danger).
##   4. Ends the turn facing the nearest opponent.
## A taunted unit (UnitState.get_taunter) only values hits on its taunter and
## only approaches it.

const MOVE_COST_WEIGHT := 0.05
## How much the danger of the landing cell counts when the unit is attacking.
## Lower than 1 so cautious units still shoot instead of kiting forever.
const ATTACK_POSITION_WEIGHT := 0.35

var _default_profile := AiProfile.new()


func decide(combat: CombatState, unit: UnitState) -> AiAction:
	var profile := get_profile(unit)
	var threat := build_threat_map(combat, unit)

	var summon := _best_summon(combat, unit)
	if not summon.is_empty():
		return AiAction.use_skill(summon.skill, summon.cell)

	var here := best_attack_from(combat, unit, unit.cell, threat)
	var best_move := {}
	var reach: ReachMap = null
	if unit.pm > 0:
		reach = combat.get_reach_map(unit)
		best_move = _best_attack_after_moving(combat, unit, reach, threat)
	if not here.is_empty() and (best_move.is_empty() or here.score >= best_move.score - 0.5):
		return AiAction.use_skill(here.skill, here.cell)
	if not best_move.is_empty():
		return AiAction.move(best_move.destination)

	if reach != null:
		var destination := _best_reposition(combat, unit, reach, threat, profile)
		if destination != unit.cell:
			return AiAction.move(destination)

	return AiAction.end_turn(_facing_towards_nearest_opponent(combat, unit))


func get_profile(unit: UnitState) -> AiProfile:
	return unit.data.ai_profile if unit.data.ai_profile != null else _default_profile


#region Attack scoring

## Best skill to use from [param from_cell]: {skill, cell, score, landing}
## or {} if nothing is worth it. The score already includes the position
## value of the cell where the unit ends up.
func best_attack_from(combat: CombatState, unit: UnitState, from_cell: Vector2i,
		threat: Dictionary[Vector2i, float] = {}) -> Dictionary:
	var profile := get_profile(unit)
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
			var value := 0.0
			for preview in combat.preview_skill(unit, skill, from_cell, cell):
				value += _hit_value(unit, preview, profile)
			for healed: int in combat.preview_heals(unit, skill, from_cell, cell).values():
				value += profile.heal_weight * healed
			if value <= 0.0:
				continue
			value -= profile.resource_cost_weight * (effective.rage_cost * 0.1 + effective.mp_cost * 0.2 + effective.cooldown * 1.5)
			var landing := combat.get_final_cell(unit, effective, from_cell, cell)
			var score := value + ATTACK_POSITION_WEIGHT * position_value(combat, unit, landing, threat, profile)
			if value > 0.0 and (best.is_empty() or score > best.score):
				best = {"skill": skill, "cell": cell, "score": score, "landing": landing}
	return best


func _hit_value(unit: UnitState, preview: AttackPreview, profile: AiProfile) -> float:
	var target := preview.target
	var taunter := unit.get_taunter()
	if taunter != null and target.is_enemy_of(unit) and target != taunter:
		return 0.0  # Taunted: only the taunter is worth hitting.
	var chance := preview.hit_chance / 100.0
	var value := preview.get_total_damage() * chance
	if preview.get_total_damage() >= target.hp:
		value += profile.kill_bonus * chance
	else:
		value += profile.focus_weight * (1.0 - float(target.hp) / target.max_hp) * chance
		for app in preview.statuses:
			if not target.has_status(app.status):
				value += profile.status_value * app.chance / 100.0 * chance
	value += profile.dangerous_target_weight * target.attack * chance
	return value if target.is_enemy_of(unit) else -value * 1.5


func _best_attack_after_moving(combat: CombatState, unit: UnitState, reach: ReachMap,
		threat: Dictionary[Vector2i, float]) -> Dictionary:
	var best := {}
	for cell in reach.get_destinations():
		var attack := best_attack_from(combat, unit, cell, threat)
		if attack.is_empty():
			continue
		var score: float = attack.score - reach.get_cost(cell) * MOVE_COST_WEIGHT
		if best.is_empty() or score > best.score:
			best = {"destination": cell, "score": score}
	return best

#endregion


#region Summons

## Places a summon (totem) where its aura covers the most allies and enemies,
## if the unit does not have one on the field already.
func _best_summon(combat: CombatState, unit: UnitState) -> Dictionary:
	var best := {}
	for skill in unit.data.skills:
		var effective := unit.get_effective(skill)
		if effective.summon == null or not unit.can_afford(effective):
			continue
		var has_one := combat.get_living_units().any(
			func(u: UnitState) -> bool: return u.summoner == unit and u.data == effective.summon)
		if has_one:
			continue
		var radius := effective.summon.aura.radius if effective.summon.aura != null else 1
		for cell in combat.get_targetable_cells(unit, skill, unit.cell):
			var score := 0.0
			for other in combat.get_living_units():
				if other.is_structure() or BattleGrid.manhattan(other.cell, cell) > radius:
					continue
				score += 6.0 if other.is_enemy_of(unit) else 10.0
			if score > 10.0 and (best.is_empty() or score > best.score):
				best = {"skill": skill, "cell": cell, "score": score}
	return best

#endregion


#region Positioning

## Expected damage the opponents of [param unit] could deal to each cell
## next turn. Cells nobody threatens are absent (0).
func build_threat_map(combat: CombatState, unit: UnitState) -> Dictionary[Vector2i, float]:
	var threat: Dictionary[Vector2i, float] = {}
	var own_team: Dictionary[Vector2i, bool] = {}
	for other in combat.get_living_units():
		if not other.is_enemy_of(unit) and other != unit:
			own_team[other.cell] = true
	for opponent in combat.get_living_units():
		if not opponent.is_enemy_of(unit):
			continue
		var max_range := 1
		var best_power := 0
		for skill in opponent.data.skills:
			var effective := opponent.get_effective(skill)
			if effective.deals_damage():
				max_range = maxi(max_range, effective.range_max + effective.area_size)
				best_power = maxi(best_power, effective.power)
		var damage := maxf(best_power + opponent.attack - unit.defense, 1.0)
		var moves := Pathfinder.find_reachable(combat.grid, combat.rules, opponent.cell,
			opponent.move_points, own_team)
		var covered: Dictionary[Vector2i, bool] = {}
		for origin in moves.costs:
			for cell in AreaShape.get_cells(AreaShape.Shape.DIAMOND, origin, max_range):
				covered[cell] = true
		for cell in covered:
			threat[cell] = threat.get(cell, 0.0) + damage
	return threat


## How good it is to end the turn on [param cell] (higher is better).
## 1 = normal fear of threatened cells, 0 = none. Drops as turns go by without
## anyone taking damage, so two sides waiting at the edge of each other's
## reach end up engaging instead of stalling forever.
func get_caution(combat: CombatState, profile: AiProfile) -> float:
	return clampf(1.0 - float(combat.turns_without_damage) / profile.patience_turns, 0.0, 1.0)


func position_value(combat: CombatState, unit: UnitState, cell: Vector2i,
		threat: Dictionary[Vector2i, float], profile: AiProfile) -> float:
	var value: float = -profile.threat_weight * get_caution(combat, profile) * threat.get(cell, 0.0)
	var nearest := _nearest_opponent_distance(combat, unit, cell)
	if nearest < profile.preferred_distance:
		value -= profile.too_close_weight * (profile.preferred_distance - nearest)
	return value


func _best_reposition(combat: CombatState, unit: UnitState, reach: ReachMap,
		threat: Dictionary[Vector2i, float], profile: AiProfile) -> Vector2i:
	var walk := _distance_to_attack_spots(combat, unit)
	if not reach.get_destinations().any(func(c: Vector2i) -> bool: return walk.has(c)):
		walk = _distance_to_opponents(combat, unit)
	var best_cell := unit.cell
	var best_value := _reposition_value(combat, unit, unit.cell, threat, walk, profile)
	for cell in reach.get_destinations():
		var value := _reposition_value(combat, unit, cell, threat, walk, profile) - reach.get_cost(cell) * MOVE_COST_WEIGHT
		if value > best_value + profile.reposition_margin:
			best_value = value
			best_cell = cell
	return best_cell


func _reposition_value(combat: CombatState, unit: UnitState, cell: Vector2i,
		threat: Dictionary[Vector2i, float], walk: Dictionary[Vector2i, int], profile: AiProfile) -> float:
	var value := position_value(combat, unit, cell, threat, profile)
	# Get closer to a cell from where some skill can hit an opponent. If none is
	# reachable (walled off, on a cliff), at least close the straight distance.
	var distance: int = walk.get(cell, 2 * _nearest_opponent_distance(combat, unit, cell) + 20)
	value -= profile.approach_weight * distance
	return value

#endregion


#region Helpers

## Walking distance from every cell to the closest "attack spot": a cell from
## where one of the unit's damaging skills could reach an opponent (range, area,
## vertical reach, straight line). This is what makes units on low ground find
## the ramp, and ranged units step into range instead of hugging the target.
func _distance_to_attack_spots(combat: CombatState, unit: UnitState) -> Dictionary[Vector2i, int]:
	var grid := combat.grid
	var blocked: Dictionary[Vector2i, bool] = {}
	var targets: Array[UnitState] = []
	var taunter := unit.get_taunter()
	for other in combat.get_living_units():
		if other == unit:
			continue
		blocked[other.cell] = true
		if other.is_enemy_of(unit) and not other.data.is_structure and (taunter == null or other == taunter):
			targets.append(other)
	var spots: Array[Vector2i] = []
	for skill in unit.data.skills:
		var effective := unit.get_effective(skill)
		if not effective.deals_damage():
			continue
		var self_cast := effective.target_rule == SkillData.TargetRule.SELF
		var near := 1 if self_cast else maxi(effective.range_min - effective.area_size, 1)
		var far := effective.area_size if self_cast else effective.range_max + effective.area_size
		for target in targets:
			for cell in AreaShape.get_ring(target.cell, near, maxi(far, near)):
				if not grid.is_inside(cell) or not grid.is_walkable(cell) or blocked.has(cell):
					continue
				if absi(grid.get_height(cell) - grid.get_height(target.cell)) > effective.vertical_reach:
					continue
				if effective.requires_straight_line and cell.x != target.cell.x and cell.y != target.cell.y:
					continue
				spots.append(cell)
	if spots.is_empty():
		return {}
	return Pathfinder.distance_field_many(grid, combat.rules, spots, blocked)


## Walking distance from every cell to the closest opponent.
func _distance_to_opponents(combat: CombatState, unit: UnitState) -> Dictionary[Vector2i, int]:
	var blocked: Dictionary[Vector2i, bool] = {}
	var opponents: Array[UnitState] = []
	var taunter := unit.get_taunter()
	for other in combat.get_living_units():
		if other.is_enemy_of(unit):
			blocked[other.cell] = true
			if taunter == null or other == taunter:
				opponents.append(other)
	var merged: Dictionary[Vector2i, int] = {}
	for opponent in opponents:
		var others := blocked.duplicate()
		others.erase(opponent.cell)
		var field := Pathfinder.distance_field(combat.grid, combat.rules, opponent.cell, others)
		for cell in field:
			if not merged.has(cell) or field[cell] < merged[cell]:
				merged[cell] = field[cell]
	return merged


func _nearest_opponent_distance(combat: CombatState, unit: UnitState, cell: Vector2i) -> int:
	var best := 99
	for other in combat.get_living_units():
		if other.is_enemy_of(unit):
			best = mini(best, BattleGrid.manhattan(cell, other.cell))
	return best


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
	var taunter := unit.get_taunter()
	if taunter != null:
		cells.append(taunter.cell)
		return cells
	for other in combat.get_living_units():
		if other.is_enemy_of(unit):
			cells.append(other.cell)
	return cells


func _near_any(cell: Vector2i, cells: Array[Vector2i], distance: int) -> bool:
	for other in cells:
		if BattleGrid.manhattan(cell, other) <= distance:
			return true
	return false

#endregion
