class_name CombatState
extends RefCounted
## Authoritative state and rules of one combat. Has no nodes and no visuals:
## the presentation calls the command methods and listens to the signals.
##
## Commands validate their input and return an empty/null result when the
## action is illegal, so the UI can never put the combat in an invalid state.
## Skills are always resolved through their EffectiveSkill (rage mutation +
## modifiers, see ResolutionPipeline).

signal turn_started(unit: UnitState)
signal unit_moved(unit: UnitState, path: Array[Vector2i])
signal unit_facing_changed(unit: UnitState)
signal skill_resolved(result: SkillResult)
signal unit_stats_changed(unit: UnitState)
signal unit_defeated(unit: UnitState)
signal turn_ended(unit: UnitState)
## A skill created a new unit (totem...). Already in [member units].
signal unit_summoned(unit: UnitState)
## Statuses acted at the start of [param unit]'s turn (damage, expiry, lost turn).
signal statuses_ticked(unit: UnitState, events: Array[StatusEvent])
signal combat_finished(winner: UnitState.Team)

const NO_WINNER := -1
const NO_CELL := Vector2i(-1, -1)

var grid: BattleGrid
var rules: RulesConfig
var units: Array[UnitState] = []
var active_unit: UnitState
var winner: int = NO_WINNER
## Number of turns started so far (for stats and balance).
var turn_count: int = 0
## Unit turns in a row in which nobody lost HP (the AI gets bolder as it grows).
var turns_without_damage: int = 0
## Last opponent each team hit (Team -> UnitState), for focus fire.
var focus_target: Dictionary[int, UnitState] = {}
## Summons that died because their summoner died, not yet announced.
var _orphaned: Array[UnitState] = []
## What statuses did at the start of the current turn.
var last_status_events: Array[StatusEvent] = []
## Summons that died at the start of this turn with their summoner (status damage).
var last_orphaned: Array[UnitState] = []

var _turn_queue: TurnQueue
var _rng := RandomNumberGenerator.new()
var _next_id := 0


func _init(p_grid: BattleGrid, p_rules: RulesConfig, rng_seed: int = 0) -> void:
	grid = p_grid
	rules = p_rules
	_turn_queue = TurnQueue.new(rules.ct_threshold)
	if rng_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = rng_seed


static func from_setup(setup: BattleSetup, p_rules: RulesConfig) -> CombatState:
	var combat := CombatState.new(BattleGrid.new(setup.map), p_rules, setup.rng_seed)
	var players := combat._spawn_team(setup.player_units, setup.map.player_spawns, UnitState.Team.PLAYER,
		setup.player_level, 1.0)
	for i in players.size():
		players[i].modifiers = setup.player_modifiers.duplicate()
		if i < setup.player_hp.size() and setup.player_hp[i] > 0:
			players[i].hp = mini(setup.player_hp[i], players[i].max_hp)
	combat._spawn_team(setup.enemy_units, setup.map.enemy_spawns, UnitState.Team.ENEMY,
		setup.enemy_level, setup.enemy_stat_scale)
	return combat


#region Setup

func add_unit(data: UnitData, team: UnitState.Team, cell: Vector2i, facing := GridDir.Dir.SOUTH,
		level: int = -1, stat_scale: float = 1.0) -> UnitState:
	var unit := UnitState.new(_next_id, data, team, cell, facing, level, stat_scale)
	_next_id += 1
	units.append(unit)
	return unit


func _spawn_team(roster: Array[UnitData], spawns: Array[Vector2i], team: UnitState.Team,
		level: int, stat_scale: float) -> Array[UnitState]:
	var spawned: Array[UnitState] = []
	var name_counts: Dictionary[String, int] = {}
	for data in roster:
		name_counts[data.display_name] = name_counts.get(data.display_name, 0) + 1
	var seen: Dictionary[String, int] = {}
	var center := Vector2(grid.size) * 0.5
	for i in mini(roster.size(), spawns.size()):
		var facing := GridDir.from_delta(Vector2i(center.round()) - spawns[i])
		var unit := add_unit(roster[i], team, spawns[i], facing, level, stat_scale)
		if name_counts[unit.display_name] > 1:
			seen[unit.display_name] = seen.get(unit.display_name, 0) + 1
			unit.display_name += " " + char(64 + seen[unit.display_name])
		spawned.append(unit)
	return spawned

#endregion


#region Queries

func is_finished() -> bool:
	return winner != NO_WINNER


func get_unit_at(cell: Vector2i) -> UnitState:
	for unit in units:
		if unit.is_alive() and unit.cell == cell:
			return unit
	return null


func get_living_units(team: int = -1) -> Array[UnitState]:
	return units.filter(func(u: UnitState) -> bool: return u.is_alive() and (team < 0 or u.team == team))


func get_turn_preview(count: int) -> Array[UnitState]:
	return _turn_queue.preview(units, count, active_unit)


func get_occupied_cells(except: UnitState = null) -> Dictionary[Vector2i, bool]:
	var cells: Dictionary[Vector2i, bool] = {}
	for unit in get_living_units():
		if unit != except:
			cells[unit.cell] = true
	return cells


## Movement options for [param unit] with its current PM.
## Enemies block the way; allies can be crossed but not stood on.
func get_reach_map(unit: UnitState) -> ReachMap:
	var blockers := _movement_blockers(unit)
	return Pathfinder.find_reachable(grid, rules, unit.cell, unit.pm, blockers.blocked, blockers.occupied)


## Movement towards [param cell] even if it is out of PM range ("a medias").
## Returns {} if there is no way to get closer, otherwise
## {"destination": Vector2i, "path": Array[Vector2i], "partial": bool}.
## A partial move stops on the last cell of the way that the PM allow.
func get_move_preview(unit: UnitState, cell: Vector2i) -> Dictionary:
	var reach := get_reach_map(unit)
	if reach.can_stop_at(cell):
		return {"destination": cell, "path": reach.get_path_to(cell), "partial": false}
	var blockers := _movement_blockers(unit)
	var unlimited := Pathfinder.find_reachable(grid, rules, unit.cell, 1 << 20, blockers.blocked, blockers.occupied)
	if not unlimited.costs.has(cell):
		return {}
	var best := unit.cell
	for step in unlimited.get_path_to(cell):
		if unlimited.get_cost(step) > unit.pm:
			break
		if reach.can_stop_at(step):
			best = step
	if best == unit.cell:
		return {}
	return {"destination": best, "path": reach.get_path_to(best), "partial": true}


## Where a push of [param distance] cells in [param direction] would leave
## [param target]. {"to": Vector2i, "blocked_at": Vector2i (NO_CELL if complete)}.
func predict_push(target: UnitState, direction: GridDir.Dir, distance: int) -> Dictionary:
	return predict_slide(target, target.cell, direction, distance)


## Like [method predict_push] but starting from [param from_cell] (recoil
## is computed from where the user lands, before it actually moves).
func predict_slide(unit: UnitState, from_cell: Vector2i, direction: GridDir.Dir, distance: int) -> Dictionary:
	var cell := from_cell
	for i in distance:
		var next := cell + GridDir.to_vector(direction)
		if not _is_free(next, unit) or grid.get_height(next) - grid.get_height(cell) > rules.max_climb:
			return {"to": cell, "blocked_at": next}
		cell = next
	return {"to": cell, "blocked_at": NO_CELL}


## Where [param user] ends after [param skill]: the landing cell, moved back
## by the skill's recoil (away from the target, stopped by obstacles).
func get_final_cell(user: UnitState, skill: EffectiveSkill, from_cell: Vector2i, target_cell: Vector2i) -> Vector2i:
	var landing := get_landing_cell(user, skill, from_cell, target_cell)
	if landing == NO_CELL or skill.recoil <= 0 or target_cell == landing:
		return landing
	var away := GridDir.from_delta(landing - target_cell, user.facing)
	return predict_slide(user, landing, away, skill.recoil).to


## Units a bouncing skill would chain to after hitting [param first]
## (assuming every hop lands).
func predict_bounces(user: UnitState, skill: EffectiveSkill, first: UnitState) -> Array[UnitState]:
	var chain: Array[UnitState] = []
	var exclude: Array[UnitState] = [first]
	var from_cell := first.cell
	for i in skill.bounce_hops:
		var next := _nearest_enemy(user, from_cell, exclude)
		if next == null:
			break
		chain.append(next)
		exclude.append(next)
		from_cell = next.cell
	return chain


func get_effective(user: UnitState, skill: SkillData) -> EffectiveSkill:
	return user.get_effective(skill)


## True if [param user] can pay for [param skill] and has at least one target.
func can_use_skill(user: UnitState, skill: SkillData) -> bool:
	var effective := get_effective(user, skill)
	return user.can_afford(effective) and not get_targetable_cells(user, skill, user.cell).is_empty()


## Cells [param skill] can target if [param user] stood on [param from_cell].
func get_targetable_cells(user: UnitState, skill: SkillData, from_cell: Vector2i) -> Array[Vector2i]:
	var effective := get_effective(user, skill)
	var result: Array[Vector2i] = []
	if effective.target_rule == SkillData.TargetRule.SELF:
		result.append(from_cell)
		return result
	var from_height := grid.get_height(from_cell)
	for cell in AreaShape.get_ring(from_cell, effective.range_min, effective.range_max):
		if not grid.is_inside(cell):
			continue
		if absi(grid.get_height(cell) - from_height) > effective.vertical_reach:
			continue
		if effective.requires_straight_line and cell.x != from_cell.x and cell.y != from_cell.y:
			continue
		if not _matches_target_rule(user, effective, cell):
			continue
		if get_landing_cell(user, effective, from_cell, cell) == NO_CELL:
			continue
		result.append(cell)
	return result


## Where the user ends up after using [param skill] on [param target_cell]
## from [param from_cell]. NO_CELL if the motion is impossible.
func get_landing_cell(user: UnitState, skill: EffectiveSkill, from_cell: Vector2i, target_cell: Vector2i) -> Vector2i:
	match skill.motion:
		SkillData.Motion.TELEPORT:
			return target_cell if _is_free(target_cell, user) else NO_CELL
		SkillData.Motion.CHARGE:
			return _get_charge_landing(user, from_cell, target_cell)
		SkillData.Motion.BEHIND_TARGET:
			var target := get_unit_at(target_cell)
			if target == null:
				return NO_CELL
			var back := target_cell - GridDir.to_vector(target.facing)
			if not _is_free(back, user) and back != from_cell:
				return NO_CELL
			if absi(grid.get_height(back) - grid.get_height(target_cell)) > rules.max_climb:
				return NO_CELL
			return back
		_:
			return from_cell


func get_effect_cells(skill: EffectiveSkill, from_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]:
	var direction := GridDir.from_delta(target_cell - from_cell)
	var cells := AreaShape.get_cells(skill.area_shape, target_cell, skill.area_size, direction)
	return cells.filter(func(c: Vector2i) -> bool: return grid.is_inside(c))


## Units affected by [param skill] aimed at [param target_cell].
func get_skill_targets(user: UnitState, skill: EffectiveSkill, from_cell: Vector2i, target_cell: Vector2i) -> Array[UnitState]:
	var targets: Array[UnitState] = []
	if not skill.deals_damage():
		return targets
	var landing := get_landing_cell(user, skill, from_cell, target_cell)
	for cell in get_effect_cells(skill, landing, target_cell):
		var unit := get_unit_at(cell)
		if unit == null or unit == user:
			continue
		if unit.is_enemy_of(user) or skill.affects_allies:
			targets.append(unit)
	return targets


func preview_skill(user: UnitState, skill: SkillData, from_cell: Vector2i, target_cell: Vector2i) -> Array[AttackPreview]:
	var effective := get_effective(user, skill)
	var landing := get_landing_cell(user, effective, from_cell, target_cell)
	var previews: Array[AttackPreview] = []
	if landing == NO_CELL:
		return previews
	var occupied := get_occupied_cells(user)
	for target in get_skill_targets(user, effective, from_cell, target_cell):
		previews.append(_preview_hit(user, effective, landing, target, occupied))
	return previews


## HP each ally would recover from [param skill] (heal_percent), capped by missing HP.
func preview_heals(user: UnitState, skill: SkillData, from_cell: Vector2i, target_cell: Vector2i) -> Dictionary[UnitState, int]:
	var effective := get_effective(user, skill)
	var heals: Dictionary[UnitState, int] = {}
	if effective.heal_percent <= 0:
		return heals
	var landing := get_landing_cell(user, effective, from_cell, target_cell)
	if landing == NO_CELL:
		return heals
	for cell in get_effect_cells(effective, landing, target_cell):
		var unit := user if cell == landing else get_unit_at(cell)
		if unit == null or unit.is_enemy_of(user) or not unit.is_alive():
			continue
		heals[unit] = mini(roundi(unit.max_hp * effective.heal_percent / 100.0), unit.max_hp - unit.hp)
	return heals

#endregion


#region Commands

## Starts the next turn in speed order and returns the acting unit.
func start_next_turn() -> UnitState:
	if is_finished():
		return null
	active_unit = _turn_queue.advance(units)
	active_unit.begin_turn(rules)
	last_orphaned = []
	turn_count += 1
	turns_without_damage += 1
	last_status_events = _tick_statuses(active_unit)
	_apply_auras(active_unit)
	turn_started.emit(active_unit)
	if not last_status_events.is_empty():
		statuses_ticked.emit(active_unit, last_status_events)
		unit_stats_changed.emit(active_unit)
		if not active_unit.is_alive():
			unit_defeated.emit(active_unit)
			last_orphaned = take_orphaned()
			_check_victory()
	return active_unit


## Moves the active unit to [param destination]. Returns the walked path
## (empty if the move is illegal).
func move_active_unit(destination: Vector2i) -> Array[Vector2i]:
	var unit := active_unit
	var reach := get_reach_map(unit)
	if not reach.can_stop_at(destination):
		return []
	var path := reach.get_path_to(destination)
	var previous := unit.cell if path.size() < 2 else path[-2]
	unit.pm -= reach.get_cost(destination)
	unit.cell = destination
	unit.facing = GridDir.from_delta(destination - previous, unit.facing)
	unit.gain_momentum(path.size())
	unit_moved.emit(unit, path)
	unit_stats_changed.emit(unit)
	return path


## Uses [param skill] (an equipped SkillData) on [param target_cell].
## Returns null if illegal.
func use_skill(skill: SkillData, target_cell: Vector2i) -> SkillResult:
	var user := active_unit
	var effective := get_effective(user, skill)
	if not user.can_afford(effective) or not get_targetable_cells(user, skill, user.cell).has(target_cell):
		return null

	var result := SkillResult.new()
	result.user = user
	result.skill = effective
	result.target_cell = target_cell
	result.user_from = user.cell
	# Targets are chosen before moving, from the landing cell.
	var landing := get_landing_cell(user, effective, user.cell, target_cell)
	var targets := get_skill_targets(user, effective, user.cell, target_cell)

	user.pay_for(effective)
	user.cell = landing
	result.user_to = landing
	if target_cell != user.cell:
		user.facing = GridDir.from_delta(target_cell - user.cell, user.facing)
	result.affected_cells = get_effect_cells(effective, landing, target_cell)

	var already_hit: Array[UnitState] = []
	for target in targets:
		for strike in effective.strikes:
			if target.is_alive():
				_resolve_hit(result, target, user.cell, SkillResult.HitSource.PRIMARY, already_hit)
	if effective.self_status != null:
		user.add_status(effective.self_status, effective.self_status.default_duration)
	if effective.heal_percent > 0:
		for ally in preview_heals(user, skill, result.user_from, target_cell).keys():
			result.heals[ally] = ally.heal(roundi(ally.max_hp * effective.heal_percent / 100.0))
	_resolve_bounces(result, already_hit)
	if effective.recoil > 0 and user.is_alive():
		var recoil_to := get_final_cell(user, effective, result.user_from, target_cell)
		if recoil_to != user.cell:
			result.recoil_from = user.cell
			result.recoil_to = recoil_to
			user.cell = recoil_to
	_resolve_kill_refund(result)
	if effective.summon != null:
		_summon(result, effective.summon, target_cell)

	if result.user_moved() or result.has_recoil():
		unit_moved.emit(user, [user.cell] as Array[Vector2i])
	unit_facing_changed.emit(user)
	unit_stats_changed.emit(user)
	skill_resolved.emit(result)
	for ally in result.heals:
		unit_stats_changed.emit(ally)
	for hit in result.hits:
		unit_stats_changed.emit(hit.target)
		if hit.defeated:
			unit_defeated.emit(hit.target)
	result.orphaned = take_orphaned()
	_check_victory()
	return result


func set_active_facing(facing: GridDir.Dir) -> void:
	if active_unit.facing == facing:
		return
	active_unit.facing = facing
	unit_facing_changed.emit(active_unit)


func end_turn(facing: GridDir.Dir) -> void:
	var unit := active_unit
	set_active_facing(facing)
	_turn_queue.pay_turn(unit)
	turn_ended.emit(unit)

#endregion


#region Resolution

func _preview_hit(user: UnitState, skill: EffectiveSkill, from_cell: Vector2i, target: UnitState,
		occupied: Dictionary[Vector2i, bool]) -> AttackPreview:
	var side := GridRules.get_attack_side(grid, rules, from_cell, target.cell, target.facing, occupied)
	var height_diff := grid.get_height(from_cell) - grid.get_height(target.cell)
	var preview := CombatFormulas.build_preview(rules, user, skill, target, side, height_diff)
	var fx := ResolutionPipeline.get_impact_effects(skill, side, false)
	preview.statuses = fx.statuses
	preview.push_to = target.cell
	if preview.knockback > 0:
		var push := predict_push(target, GridDir.from_delta(target.cell - from_cell), preview.knockback)
		preview.push_to = push.to
		preview.push_blocked_at = push.blocked_at
	return preview


func _resolve_hit(result: SkillResult, target: UnitState, from_cell: Vector2i,
		source: SkillResult.HitSource, already_hit: Array[UnitState]) -> SkillResult.Hit:
	var user := result.user
	var skill := result.skill
	var preview := _preview_hit(user, skill, from_cell, target, get_occupied_cells(user))
	var hit := SkillResult.Hit.new()
	hit.target = target
	hit.source = source
	hit.origin_cell = from_cell
	hit.side = preview.side
	hit.pushed_from = target.cell
	hit.pushed_to = target.cell
	hit.landed = _rng.randi_range(1, 100) <= preview.hit_chance
	result.hits.append(hit)
	already_hit.append(target)
	if not hit.landed:
		return hit

	hit.critical = _rng.randi_range(1, 100) <= preview.crit_chance
	hit.damage = preview.crit_damage if hit.critical else preview.damage
	_apply_damage(target, hit.damage)
	if target.is_enemy_of(user):
		focus_target[user.team] = target
	user.add_rage(rules.rage_on_hit_dealt + skill.rage_on_hit, rules)
	hit.defeated = not target.is_alive()

	var fx := ResolutionPipeline.get_impact_effects(skill, hit.side, hit.critical)
	if fx.lifesteal > 0:
		hit.healed = user.heal(roundi(hit.damage * fx.lifesteal / 100.0))
	if target.is_alive():
		for app: StatusApplication in fx.statuses:
			if _rng.randi_range(1, 100) <= app.chance:
				target.add_status(app.status, app.duration, user)
				hit.applied_statuses.append(app.status)
	if fx.knockback > 0 and target.is_alive():
		var push := predict_push(target, GridDir.from_delta(target.cell - from_cell), fx.knockback)
		hit.pushed_to = push.to
		hit.push_blocked_at = push.blocked_at
		target.cell = hit.pushed_to
	if fx.explode_percent > 0 and source != SkillResult.HitSource.EXPLOSION:
		_resolve_explosion(result, hit, fx.explode_percent, fx.explode_radius, already_hit)
	return hit


## Stage 3: splash damage around a landed hit. Always hits, never crits.
func _resolve_explosion(result: SkillResult, origin: SkillResult.Hit, percent: int, radius: int,
		already_hit: Array[UnitState]) -> void:
	var damage := maxi(roundi(origin.damage * percent / 100.0), rules.min_damage)
	for cell in AreaShape.get_cells(AreaShape.Shape.DIAMOND, origin.pushed_from, maxi(radius, 1)):
		var unit := get_unit_at(cell)
		if unit == null or unit == origin.target or not unit.is_enemy_of(result.user) or already_hit.has(unit):
			continue
		var hit := SkillResult.Hit.new()
		hit.target = unit
		hit.source = SkillResult.HitSource.EXPLOSION
		hit.origin_cell = origin.pushed_from
		hit.landed = true
		hit.damage = damage
		hit.pushed_from = unit.cell
		hit.pushed_to = unit.cell
		_apply_damage(unit, damage)
		hit.defeated = not unit.is_alive()
		result.hits.append(hit)
		already_hit.append(unit)


## Stage 4: chains. Each hop jumps from the last landed target to the nearest
## enemy not hit yet, capped by the bounce limit.
func _resolve_bounces(result: SkillResult, already_hit: Array[UnitState]) -> void:
	var hops := result.skill.bounce_hops
	if hops <= 0:
		return
	var last: SkillResult.Hit = null
	for hit in result.hits:
		if hit.landed and hit.source == SkillResult.HitSource.PRIMARY:
			last = hit
	while hops > 0 and last != null:
		var from_cell := last.pushed_to if last.target.is_alive() else last.pushed_from
		var next := _nearest_enemy(result.user, from_cell, already_hit)
		if next == null:
			return
		last = _resolve_hit(result, next, from_cell, SkillResult.HitSource.BOUNCE, already_hit)
		hops -= 1
		if not last.landed:
			return


func _resolve_kill_refund(result: SkillResult) -> void:
	var refund := ResolutionPipeline.get_kill_refund(result.skill)
	if refund.x <= 0:
		return
	var user := result.user
	for hit in result.hits:
		if hit.defeated and user.refunds_this_turn < refund.y:
			user.refunds_this_turn += 1
			user.pa += refund.x
			result.refunded_ap += refund.x


func _apply_damage(target: UnitState, damage: int) -> void:
	if damage > 0:
		turns_without_damage = 0
	target.hp = maxi(target.hp - damage, 0)
	if target.is_alive():
		target.add_rage(CombatFormulas.rage_from_damage_taken(rules, target, damage), rules)
	else:
		_kill_summons_of(target)


## A summoner's death takes its summons with it (GDD: invocadores).
func _kill_summons_of(summoner: UnitState) -> void:
	for unit in get_living_units():
		if unit.summoner == summoner:
			unit.hp = 0
			_orphaned.append(unit)
			_kill_summons_of(unit)


## Summons killed by their summoner's death since the last call.
func take_orphaned() -> Array[UnitState]:
	var list := _orphaned.duplicate()
	_orphaned.clear()
	for unit in list:
		unit_defeated.emit(unit)
	return list


## Start of turn: damage over time, lost turns and expiry.
## Pushes stop at obstacles, units, the map edge or walls higher than
## max_climb (drops are fine): see [method predict_push].
func _tick_statuses(unit: UnitState) -> Array[StatusEvent]:
	var events: Array[StatusEvent] = []
	for status: StatusData in unit.statuses.keys():
		var event := StatusEvent.new()
		event.unit = unit
		event.status = status
		var stacks := unit.get_stacks(status)
		event.stacks = stacks
		var damage := (roundi(unit.max_hp * status.damage_percent_per_turn / 100.0) + status.damage_flat_per_turn) * stacks
		if damage > 0 and unit.is_alive():
			event.damage = damage
			_apply_damage(unit, damage)
		if status.heal_percent_per_turn > 0 and unit.is_alive():
			event.healed = unit.heal(roundi(unit.max_hp * status.heal_percent_per_turn / 100.0) * stacks)
		if status.skips_turn:
			event.skipped_turn = true
			unit.skip_turn = true
			unit.pm = 0
			unit.pa = 0
		unit.statuses[status] -= 1
		if unit.statuses[status] <= 0:
			unit.remove_status(status)
			event.expired = true
		events.append(event)
	if not unit.is_alive():
		unit.skip_turn = true
	return events


func _nearest_enemy(user: UnitState, from_cell: Vector2i, exclude: Array[UnitState]) -> UnitState:
	var best: UnitState = null
	var best_distance := rules.bounce_search_radius + 1
	for unit in get_living_units():
		if not unit.is_enemy_of(user) or exclude.has(unit):
			continue
		var distance := BattleGrid.manhattan(from_cell, unit.cell)
		if distance < best_distance:
			best_distance = distance
			best = unit
	return best


func _movement_blockers(unit: UnitState) -> Dictionary:
	var blocked: Dictionary[Vector2i, bool] = {}
	var occupied: Dictionary[Vector2i, bool] = {}
	for other in get_living_units():
		if other == unit:
			continue
		occupied[other.cell] = true
		if other.is_enemy_of(unit):
			blocked[other.cell] = true
	return {"blocked": blocked, "occupied": occupied}


func _get_charge_landing(user: UnitState, from_cell: Vector2i, target_cell: Vector2i) -> Vector2i:
	if from_cell.x != target_cell.x and from_cell.y != target_cell.y:
		return NO_CELL
	var step := GridDir.to_vector(GridDir.from_delta(target_cell - from_cell))
	var cell := from_cell
	while cell + step != target_cell:
		var next := cell + step
		if not _is_free(next, user):
			return NO_CELL
		if absi(grid.get_height(next) - grid.get_height(cell)) > rules.max_climb:
			return NO_CELL
		cell = next
	return cell


func _matches_target_rule(user: UnitState, skill: EffectiveSkill, cell: Vector2i) -> bool:
	match skill.target_rule:
		SkillData.TargetRule.ENEMY_UNIT:
			var unit := get_unit_at(cell)
			return unit != null and unit.is_enemy_of(user)
		SkillData.TargetRule.EMPTY_CELL:
			return _is_free(cell, user)
		_:
			return true


## Walkable and without any living unit other than [param ignore].
func _is_free(cell: Vector2i, ignore: UnitState) -> bool:
	if not grid.is_walkable(cell):
		return false
	var unit := get_unit_at(cell)
	return unit == null or unit == ignore


## Auras of nearby units refresh their statuses on [param unit] (until its next turn).
func _apply_auras(unit: UnitState) -> void:
	if not unit.is_alive():
		return
	for source in get_living_units():
		var aura := source.data.aura
		if aura == null or source == unit:
			continue
		if BattleGrid.manhattan(source.cell, unit.cell) > aura.radius:
			continue
		var status := aura.enemy_status if source.is_enemy_of(unit) else aura.ally_status
		if status != null:
			unit.add_status(status, 1)


func _summon(result: SkillResult, data: UnitData, cell: Vector2i) -> void:
	var user := result.user
	var alive := get_living_units().filter(
		func(u: UnitState) -> bool: return u.summoner == user and u.data == data)
	if alive.size() >= result.skill.summon_limit:
		var oldest: UnitState = alive[0]
		oldest.hp = 0
		result.replaced = oldest
	var unit := add_unit(data, user.team, cell, user.facing, user.level)
	unit.summoner = user
	result.summoned = unit
	unit_summoned.emit(unit)
	if result.replaced != null:
		unit_defeated.emit(result.replaced)


## Units that decide the combat (structures do not count).
func _fighters(team: int) -> Array[UnitState]:
	return get_living_units(team).filter(func(u: UnitState) -> bool: return not u.is_structure())


func _check_victory() -> void:
	if is_finished():
		return
	var players_alive := not _fighters(UnitState.Team.PLAYER).is_empty()
	var enemies_alive := not _fighters(UnitState.Team.ENEMY).is_empty()
	if players_alive and enemies_alive:
		return
	winner = UnitState.Team.PLAYER if players_alive else UnitState.Team.ENEMY
	combat_finished.emit(winner)

#endregion
