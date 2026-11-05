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
## How much more a run protagonist fears threatened cells.
const PROTAGONIST_CAUTION := 2.0

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

	var escape := _best_escape(combat, unit, reach, threat, profile)
	if not escape.is_empty():
		return AiAction.use_skill(escape.skill, escape.cell)

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
		var support := effective.supports_allies()
		if not (effective.deals_damage() or support) or not unit.can_afford(effective):
			continue
		var reach := 2 * effective.area_size + effective.explode_radius
		var long_area := effective.motion == SkillData.Motion.ROLL
		for cell in combat.get_targetable_cells(unit, skill, from_cell):
			if not support and not long_area and not _near_any(cell, opponents, reach):
				continue
			var value := 0.0
			for preview in combat.preview_skill(unit, skill, from_cell, cell):
				value += _hit_value(combat, unit, preview, profile)
				if preview.target == _focus_of(combat, unit, profile):
					value += profile.shared_focus_weight * preview.hit_chance / 100.0
			for healed: int in combat.preview_heals(unit, skill, from_cell, cell).values():
				value += profile.heal_weight * healed
			for ally in combat.preview_buffs(unit, skill, from_cell, cell):
				if not ally.has_status(effective.ally_status):
					value += profile.status_value * (0.5 if ally == unit else 1.0)
			if value <= 0.0:
				continue
			value -= profile.resource_cost_weight * (effective.rage_cost * 0.1 + effective.mp_cost * 0.2 + effective.cooldown * 1.5)
			var landing := combat.get_final_cell(unit, effective, from_cell, cell)
			var score := value + ATTACK_POSITION_WEIGHT * position_value(combat, unit, landing, threat, profile)
			if value > 0.0 and (best.is_empty() or score > best.score):
				best = {"skill": skill, "cell": cell, "score": score, "landing": landing}
	return best


## The opponent this unit's team is focusing (shared_focus_weight > 0), or null.
func _focus_of(combat: CombatState, unit: UnitState, profile: AiProfile) -> UnitState:
	if profile.shared_focus_weight <= 0.0:
		return null
	var focus: UnitState = combat.focus_target.get(unit.team)
	if focus == null or not focus.is_alive() or not focus.is_enemy_of(unit):
		return null
	return focus


func _hit_value(combat: CombatState, unit: UnitState, preview: AttackPreview, profile: AiProfile) -> float:
	var target := preview.target
	var taunter := unit.get_taunter()
	if taunter != null and target.is_enemy_of(unit) and target != taunter:
		return 0.0  # Taunted: only the taunter is worth hitting.
	var chance := preview.hit_chance / 100.0
	# Expected damage with crits: units that always crit poisoned targets go for them.
	var crit := preview.crit_chance / 100.0
	var expected := (preview.damage * (1.0 - crit) + preview.crit_damage * crit) * preview.strikes
	var value := expected * chance
	if preview.get_total_damage() >= target.hp:
		value += profile.kill_bonus * chance
	else:
		value += profile.focus_weight * (1.0 - float(target.hp) / target.max_hp) * chance
		for app in preview.statuses:
			if not target.has_status(app.status):
				var odds := app.chance / 100.0 * chance
				value += profile.status_value * odds
				value += profile.combo_weight * _combo_potential(combat, unit, app.status) * odds
	value += profile.dangerous_target_weight * target.attack * chance
	if target.is_enemy_of(unit):
		if target.data.skills.any(func(s: SkillData) -> bool: return target.get_effective(s).supports_allies()):
			value += profile.support_target_weight * chance  # Healers and buffers first.
		if target.is_protagonist:
			value += profile.protagonist_target_weight * chance
	return value if target.is_enemy_of(unit) else -value * 1.5


## How many of the unit's team (itself included) can exploit [param status]
## on a target: skills that always crit its kind, and vulnerability / lower
## defense that every hit benefits from. 0 = nobody cares.
func _combo_potential(combat: CombatState, unit: UnitState, status: StatusData) -> float:
	var potential := 0.0
	for ally in combat.get_living_units():
		if ally.is_enemy_of(unit) or ally.is_structure():
			continue
		for skill in ally.data.skills:
			var effective := ally.get_effective(skill)
			if effective.crit_vs_status_kind >= 0 and effective.crit_vs_status_kind == status.kind:
				potential += 1.0
				break
		if status.damage_taken_percent_bonus > 0 or status.defense_percent_bonus < 0:
			potential += 0.5  # Every ally hits harder.
	return potential


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
		var alive := combat.get_living_units().filter(
			func(u: UnitState) -> bool: return u.summoner == unit and u.data == effective.summon).size()
		if alive >= effective.summon_limit:
			continue
		for cell in combat.get_targetable_cells(unit, skill, unit.cell):
			var score := _summon_cell_value(combat, unit, effective.summon, cell)
			if score > 10.0 and (best.is_empty() or score > best.score):
				best = {"skill": skill, "cell": cell, "score": score}
	return best


## Aura summons (totems) go where the aura covers the most units; fighting
## summons go between the summoner and its opponents (towards them, as cover).
func _summon_cell_value(combat: CombatState, unit: UnitState, summon: UnitData, cell: Vector2i) -> float:
	var score := 0.0
	if summon.aura != null:
		for other in combat.get_living_units():
			if other.is_structure() or BattleGrid.manhattan(other.cell, cell) > summon.aura.radius:
				continue
			score += 6.0 if other.is_enemy_of(unit) else 10.0
		return score
	score = 30.0 - 2.0 * _nearest_opponent_distance(combat, unit, cell)
	if BattleGrid.manhattan(cell, unit.cell) == 1:
		score += 4.0
	return score

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
	if unit.is_protagonist:
		value *= PROTAGONIST_CAUTION  # Losing it loses the battle: keep it safer.
	var nearest := _nearest_opponent_distance(combat, unit, cell)
	if nearest < profile.preferred_distance:
		value -= profile.too_close_weight * (profile.preferred_distance - nearest)
	if profile.ally_cover_weight > 0.0:
		for other in combat.get_living_units():
			if other != unit and not other.is_enemy_of(unit) and not other.is_structure() \
					and BattleGrid.manhattan(other.cell, cell) == 1:
				value += profile.ally_cover_weight
	return value


func _best_reposition(combat: CombatState, unit: UnitState, reach: ReachMap,
		threat: Dictionary[Vector2i, float], profile: AiProfile) -> Vector2i:
	var walk := _distance_to_attack_spots(combat, unit)
	if not _has_damaging_skill(unit):
		walk = _distance_to_allies(combat, unit)  # Healers stay with their team.
	elif not reach.get_destinations().any(func(c: Vector2i) -> bool: return walk.has(c)):
		walk = _distance_to_opponents(combat, unit)
	var best_cell := unit.cell
	var best_value := _reposition_value(combat, unit, unit.cell, threat, walk, profile)
	for cell in reach.get_destinations():
		var value := _reposition_value(combat, unit, cell, threat, walk, profile) - reach.get_cost(cell) * MOVE_COST_WEIGHT
		if value > best_value + profile.reposition_margin:
			best_value = value
			best_cell = cell
	return best_cell


## Teleport skills that deal no damage (burrowing, blink) used to reposition
## when they reach a clearly better cell than walking does.
func _best_escape(combat: CombatState, unit: UnitState, reach: ReachMap,
		threat: Dictionary[Vector2i, float], profile: AiProfile) -> Dictionary:
	var walk := _distance_to_attack_spots(combat, unit)
	var baseline := _reposition_value(combat, unit, unit.cell, threat, walk, profile)
	if reach != null:
		for cell in reach.get_destinations():
			baseline = maxf(baseline, _reposition_value(combat, unit, cell, threat, walk, profile))
	var best := {}
	for skill in unit.data.skills:
		var effective := unit.get_effective(skill)
		if effective.motion != SkillData.Motion.TELEPORT or effective.deals_damage() or not unit.can_afford(effective):
			continue
		for cell in combat.get_targetable_cells(unit, skill, unit.cell):
			var value := _reposition_value(combat, unit, cell, threat, walk, profile)
			if value > baseline + 2.0 * profile.reposition_margin and (best.is_empty() or value > best.value):
				best = {"skill": skill, "cell": cell, "value": value}
	return best


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
	if taunter == null:
		taunter = _focus_of(combat, unit, get_profile(unit))  # Swarms walk to the shared target.
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


func _has_damaging_skill(unit: UnitState) -> bool:
	return unit.data.skills.any(func(s: SkillData) -> bool: return unit.get_effective(s).deals_damage())


## Walking distance from every cell to the cells next to the unit's allies.
func _distance_to_allies(combat: CombatState, unit: UnitState) -> Dictionary[Vector2i, int]:
	var blocked: Dictionary[Vector2i, bool] = {}
	var spots: Array[Vector2i] = []
	for other in combat.get_living_units():
		if other == unit:
			continue
		blocked[other.cell] = true
		if not other.is_enemy_of(unit) and not other.is_structure():
			for dir in GridDir.ALL:
				var spot := other.cell + GridDir.to_vector(dir)
				if combat.grid.is_inside(spot) and combat.grid.is_walkable(spot):
					spots.append(spot)
	if spots.is_empty():
		return {}
	return Pathfinder.distance_field_many(combat.grid, combat.rules, spots, blocked)


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
