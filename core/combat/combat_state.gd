class_name CombatState
extends RefCounted
## Authoritative state and rules of one combat. Has no nodes and no visuals:
## the presentation calls the command methods and listens to the signals.
##
## Commands validate their input and return an empty/false result when the
## action is illegal, so the UI can never put the combat in an invalid state.

signal turn_started(unit: UnitState)
signal unit_moved(unit: UnitState, path: Array[Vector2i])
signal unit_facing_changed(unit: UnitState)
signal skill_resolved(result: SkillResult)
signal unit_stats_changed(unit: UnitState)
signal unit_defeated(unit: UnitState)
signal turn_ended(unit: UnitState)
signal combat_finished(winner: UnitState.Team)

const NO_WINNER := -1

var grid: BattleGrid
var rules: RulesConfig
var units: Array[UnitState] = []
var active_unit: UnitState
var winner: int = NO_WINNER

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
	combat._spawn_team(setup.player_units, setup.map.player_spawns, UnitState.Team.PLAYER, GridDir.Dir.NORTH)
	combat._spawn_team(setup.enemy_units, setup.map.enemy_spawns, UnitState.Team.ENEMY, GridDir.Dir.SOUTH)
	return combat


#region Setup

func add_unit(data: UnitData, team: UnitState.Team, cell: Vector2i, facing := GridDir.Dir.SOUTH) -> UnitState:
	var unit := UnitState.new(_next_id, data, team, cell, facing)
	_next_id += 1
	units.append(unit)
	return unit


func _spawn_team(roster: Array[UnitData], spawns: Array[Vector2i], team: UnitState.Team, facing: GridDir.Dir) -> void:
	var name_counts: Dictionary[String, int] = {}
	for data in roster:
		name_counts[data.display_name] = name_counts.get(data.display_name, 0) + 1
	var seen: Dictionary[String, int] = {}
	for i in mini(roster.size(), spawns.size()):
		var unit := add_unit(roster[i], team, spawns[i], facing)
		if name_counts[unit.display_name] > 1:
			seen[unit.display_name] = seen.get(unit.display_name, 0) + 1
			unit.display_name += " " + char(64 + seen[unit.display_name])

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


func get_occupied_cells() -> Dictionary[Vector2i, bool]:
	var cells: Dictionary[Vector2i, bool] = {}
	for unit in get_living_units():
		cells[unit.cell] = true
	return cells


## Movement options for [param unit] with its current PM.
## Enemies block the way; allies can be crossed but not stood on.
func get_reach_map(unit: UnitState) -> ReachMap:
	var blocked: Dictionary[Vector2i, bool] = {}
	var occupied: Dictionary[Vector2i, bool] = {}
	for other in get_living_units():
		if other == unit:
			continue
		occupied[other.cell] = true
		if other.is_enemy_of(unit):
			blocked[other.cell] = true
	return Pathfinder.find_reachable(grid, rules, unit.cell, unit.pm, blocked, occupied)


## Cells [param skill] can target if its user stood on [param from_cell].
## [param _user] is unused for now; modifiers (M1) will extend the range per unit.
func get_targetable_cells(_user: UnitState, skill: SkillData, from_cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var from_height := grid.get_height(from_cell)
	for cell in AreaShape.get_ring(from_cell, skill.range_min, skill.range_max):
		if not grid.is_inside(cell):
			continue
		if absi(grid.get_height(cell) - from_height) > skill.vertical_reach:
			continue
		result.append(cell)
	return result


func get_effect_cells(skill: SkillData, from_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]:
	var direction := GridDir.from_delta(target_cell - from_cell)
	var cells := AreaShape.get_cells(skill.area_shape, target_cell, skill.area_size, direction)
	return cells.filter(func(c: Vector2i) -> bool: return grid.is_inside(c))


## Units affected by [param skill] aimed at [param target_cell].
func get_skill_targets(user: UnitState, skill: SkillData, from_cell: Vector2i, target_cell: Vector2i) -> Array[UnitState]:
	var targets: Array[UnitState] = []
	for cell in get_effect_cells(skill, from_cell, target_cell):
		var unit := get_unit_at(cell)
		if unit == null or unit == user:
			continue
		if unit.is_enemy_of(user) or skill.affects_allies:
			targets.append(unit)
	return targets


func preview_skill(user: UnitState, skill: SkillData, from_cell: Vector2i, target_cell: Vector2i) -> Array[AttackPreview]:
	var occupied := get_occupied_cells()
	occupied.erase(user.cell)
	var previews: Array[AttackPreview] = []
	for target in get_skill_targets(user, skill, from_cell, target_cell):
		var side := GridRules.get_attack_side(grid, rules, from_cell, target.cell, target.facing, occupied)
		previews.append(CombatFormulas.build_preview(rules, user, skill, target, side))
	return previews


func can_use_skill_at(user: UnitState, skill: SkillData, target_cell: Vector2i) -> bool:
	return user.can_afford(skill) and get_targetable_cells(user, skill, user.cell).has(target_cell)

#endregion


#region Commands

## Starts the next turn in speed order and returns the acting unit.
func start_next_turn() -> UnitState:
	if is_finished():
		return null
	active_unit = _turn_queue.advance(units)
	active_unit.begin_turn()
	turn_started.emit(active_unit)
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
	unit_moved.emit(unit, path)
	unit_stats_changed.emit(unit)
	return path


## Uses [param skill] on [param target_cell]. Returns null if illegal.
func use_skill(skill: SkillData, target_cell: Vector2i) -> SkillResult:
	var user := active_unit
	if not can_use_skill_at(user, skill, target_cell):
		return null
	user.pa -= skill.ap_cost
	user.mp -= skill.mp_cost
	if target_cell != user.cell:
		user.facing = GridDir.from_delta(target_cell - user.cell, user.facing)
		unit_facing_changed.emit(user)

	var result := SkillResult.new()
	result.user = user
	result.skill = skill
	result.target_cell = target_cell
	result.affected_cells = get_effect_cells(skill, user.cell, target_cell)
	for preview in preview_skill(user, skill, user.cell, target_cell):
		result.hits.append(_resolve_hit(preview))

	unit_stats_changed.emit(user)
	skill_resolved.emit(result)
	for hit in result.hits:
		if hit.landed:
			unit_stats_changed.emit(hit.target)
		if hit.defeated:
			unit_defeated.emit(hit.target)
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


func _resolve_hit(preview: AttackPreview) -> SkillResult.Hit:
	var hit := SkillResult.Hit.new()
	hit.target = preview.target
	hit.side = preview.side
	hit.landed = _rng.randi_range(1, 100) <= preview.hit_chance
	if not hit.landed:
		return hit
	hit.critical = _rng.randi_range(1, 100) <= preview.crit_chance
	hit.damage = preview.crit_damage if hit.critical else preview.damage
	preview.target.hp = maxi(preview.target.hp - hit.damage, 0)
	hit.defeated = not preview.target.is_alive()
	return hit


func _check_victory() -> void:
	if is_finished():
		return
	var players_alive := not get_living_units(UnitState.Team.PLAYER).is_empty()
	var enemies_alive := not get_living_units(UnitState.Team.ENEMY).is_empty()
	if players_alive and enemies_alive:
		return
	winner = UnitState.Team.PLAYER if players_alive else UnitState.Team.ENEMY
	combat_finished.emit(winner)
