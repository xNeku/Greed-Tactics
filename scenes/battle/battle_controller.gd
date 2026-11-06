class_name BattleController
extends Node3D
## Root of a combat scene.
##
## Builds CombatState (rules) from a BattleSetup (data), spawns the views and
## runs the turn loop. Player turns are delegated to PlayerTurnInput and enemy
## turns to BasicAI. Both go through the same execute_* methods, which apply
## the command to the rules and then await the matching animation.
##
## Where the setup comes from:
##   1. GameSession (autoload "Game") has a pending battle (runs, quick battles).
##   2. Otherwise the exported [member setup] (F6 on this scene).
## A setup without map but with a zone gets a procedural map.

const QUEUE_PREVIEW_SIZE := 6
const AI_THINK_TIME := 0.4
const AI_STEP_TIME := 0.25
const MAX_AI_STEPS := 8
const RESULT_DELAY := 1.2
## How long the AI shows its arrows before acting.
const AI_PREVIEW_TIME := 0.45
const STATUS_TICK_TIME := 0.5
const CRIT_SHAKE := 0.22
const HIT_SHAKE := 0.08

@export var setup: BattleSetup
@export var rules: RulesConfig
@export var unit_view_scene: PackedScene
## Debug/balance: the AI also plays the player's units.
@export var autoplay_player_units := false

@onready var _map_view: BattleMapView = %BattleMap
@onready var _highlighter: TileHighlighter = %TileHighlighter
@onready var _units_root: Node3D = %Units
@onready var _camera_rig: CameraRig = %CameraRig
@onready var _player_input: PlayerTurnInput = %PlayerTurnInput
@onready var _hud: BattleHud = %HUD
@onready var _environment: WorldEnvironment = %WorldEnvironment
@onready var _sun: DirectionalLight3D = %Sun
@onready var _arrows: FeedbackArrows = %FeedbackArrows
@onready var _vfx: VfxPlayer = %VfxPlayer
@onready var _screen_fx: ScreenFx = %ScreenFx

var combat: CombatState

var _views: Dictionary[UnitState, UnitView] = {}
var _ai := BasicAI.new()
var _game: GameSession


func _ready() -> void:
	_game = get_node_or_null(^"/root/Game") as GameSession
	if _game != null and _game.has_pending_battle():
		setup = _game.take_pending_battle()
		autoplay_player_units = autoplay_player_units or _game.autoplay_battles
	elif _game != null:
		_game.release_battle()
	if not _prepare_setup():
		return
	combat = CombatState.from_setup(setup, rules)
	_map_view.build(combat.grid)
	_apply_zone_look(setup.zone)
	_highlighter.setup(_map_view)
	_camera_rig.set_bounds(_map_view.get_bounds())
	_camera_rig.focus_on(_map_view.get_center(), true)
	_spawn_views()
	_connect_signals()
	_hud.set_title(setup.title)
	_show_objective()
	_hud.set_camera(_camera_rig.get_camera())
	_hud.set_result_button_text(_game.get_result_button_text() if _owned_by_game() else "Reintentar")
	_player_input.setup(self, _map_view, _highlighter, _arrows, _camera_rig.get_camera(), _hud)
	_run_next_turn.call_deferred()


func get_view(unit: UnitState) -> UnitView:
	return _views.get(unit)


#region Commands shared by player and AI

func execute_move(destination: Vector2i) -> void:
	var unit := combat.active_unit
	var from_cell := unit.cell
	var max_hp := unit.max_hp
	var attack := unit.attack
	var path := combat.move_active_unit(destination)
	if path.is_empty():
		return
	await _views[unit].play_move(from_cell, path)
	_camera_rig.home_position = _map_view.cell_to_world(unit.cell)
	if unit.max_hp != max_hp or unit.attack != attack:
		_views[unit].play_text("+%d PV · +%d ATQ" % [unit.max_hp - max_hp, unit.attack - attack], UnitView.HEAL_COLOR)
		_views[unit].refresh_info()


func execute_skill(skill: SkillData, target_cell: Vector2i) -> void:
	var result := combat.use_skill(skill, target_cell)
	if result == null:
		return
	await _play_skill_result(result)
	_refresh_turn_queue()


func execute_end_turn(facing: GridDir.Dir) -> void:
	combat.end_turn(facing)
	_run_next_turn.call_deferred()

#endregion


#region Turn loop

func _run_next_turn() -> void:
	if combat.is_finished():
		return
	var unit := combat.start_next_turn()
	_refresh_turn_queue()
	_hud.show_unit(unit)
	_views[unit].refresh_info()
	_camera_rig.home_position = _map_view.cell_to_world(unit.cell)
	_camera_rig.focus_on(_camera_rig.home_position)
	if not combat.last_status_events.is_empty():
		await _views[unit].play_status_events(combat.last_status_events)
		await get_tree().create_timer(STATUS_TICK_TIME).timeout
		if not unit.is_alive():
			await _views[unit].play_defeat()
			await _play_orphans(combat.last_orphaned)
	if combat.is_finished():
		return
	if unit.skip_turn:
		_hud.set_message("%s pierde el turno" % unit.display_name, unit.team == UnitState.Team.ENEMY)
		await get_tree().create_timer(STATUS_TICK_TIME).timeout
		execute_end_turn(unit.facing)
		return
	if unit.team == UnitState.Team.PLAYER and not autoplay_player_units:
		_hud.set_message("Tu turno: %s" % unit.display_name)
		_player_input.begin_turn(unit)
	else:
		await _run_ai_turn(unit)


func _run_ai_turn(unit: UnitState) -> void:
	var is_enemy := unit.team == UnitState.Team.ENEMY
	_hud.hide_commands()
	_hud.set_message("%s: %s está pensando..." % ["Turno enemigo" if is_enemy else "Autoplay", unit.display_name], is_enemy)
	await get_tree().create_timer(AI_THINK_TIME).timeout
	for step in MAX_AI_STEPS:
		if combat.is_finished():
			return
		var action := _ai.decide(combat, unit)
		match action.kind:
			AiAction.Kind.MOVE:
				_highlighter.show_cells(TileHighlighter.Layer.MOVE, combat.get_reach_map(unit).get_destinations())
				_highlighter.show_cell(TileHighlighter.Layer.LANDING, action.cell)
				_arrows.add(_chest(unit.cell, unit), _ground(action.cell), FeedbackArrows.Kind.MOVE)
				_arrows.commit()
				await get_tree().create_timer(AI_PREVIEW_TIME).timeout
				_clear_feedback()
				await execute_move(action.cell)
			AiAction.Kind.SKILL:
				_show_ai_skill_preview(unit, action)
				await get_tree().create_timer(AI_PREVIEW_TIME).timeout
				_clear_feedback()
				await execute_skill(action.skill, action.cell)
			AiAction.Kind.END_TURN:
				execute_end_turn(action.facing)
				return
	execute_end_turn(unit.facing)

#endregion


#region Animation of results

func _play_skill_result(result: SkillResult) -> void:
	var user_view := _views[result.user]
	var skill := result.skill
	var label := skill.display_name + (" (ira desatada)" if skill.empowered else "")
	_hud.set_message("%s usa %s" % [result.user.display_name, label], result.user.team == UnitState.Team.ENEMY)
	var choreo := _choreography_for(result)
	var ctx: ChoreoContext = null
	if choreo != null:
		ctx = ChoreoContext.new(result, self, _environment.environment, _sun, _camera_rig, _screen_fx, _map_view, user_view)
		if choreo.follow_camera:
			_camera_rig.focus_on(user_view.global_position)
		await choreo.play(VfxStep.Phase.CAST, ctx)
	if result.user_moved():
		await user_view.play_leap(result.user_to)
		_camera_rig.home_position = _map_view.cell_to_world(result.user.cell)
	if choreo != null:
		if choreo.follow_camera:
			_camera_rig.focus_on(ctx.anchor_position(VfxStep.Anchor.TARGET))
		await choreo.play(VfxStep.Phase.ARRIVE, ctx)
	if skill.deals_damage():
		user_view.play_attack(result.target_cell)
	if choreo == null or not choreo.replaces_default_cast:
		await _vfx.play_cast(result, _map_view, user_view)
	for hit in result.hits:
		var view := _views[hit.target]
		match hit.source:
			SkillResult.HitSource.BOUNCE:
				view.play_text("¡Rebote!", UnitView.CRIT_COLOR)
				await _vfx.play_bounce(_views[hit.target].get_cast_position(), hit, _views, skill.vfx_color)
			SkillResult.HitSource.EXPLOSION:
				view.play_text("¡Boom!", UnitView.CRIT_COLOR)
		if hit.landed:
			if choreo != null and choreo.has_phase(VfxStep.Phase.IMPACT):
				await choreo.play(VfxStep.Phase.IMPACT, ctx, view.global_position)
			else:
				_vfx.impact(view.get_cast_position(), skill.vfx_color, 1.4 if hit.critical else 0.8)
			_camera_rig.shake(CRIT_SHAKE if hit.critical or hit.source == SkillResult.HitSource.EXPLOSION else HIT_SHAKE)
		await view.play_hit(hit)
		if not hit.applied_statuses.is_empty():
			view.play_statuses_applied(hit.applied_statuses)
		if hit.push_blocked_at != CombatState.NO_CELL and hit.landed and not hit.defeated:
			view.play_text("¡Choca!", UnitView.CRIT_COLOR)
		if hit.pushed_to != hit.pushed_from and not hit.defeated:
			await view.play_push(hit.pushed_to)
		if hit.healed > 0:
			user_view.play_heal(hit.healed)
		if hit.defeated:
			await view.play_defeat()
	if result.has_recoil():
		user_view.play_text("¡Retroceso!", UnitView.CRIT_COLOR)
		await user_view.play_push(result.recoil_to)
		_camera_rig.home_position = _map_view.cell_to_world(result.user.cell)
	for ally in result.heals:
		if result.heals[ally] > 0 and _views.has(ally):
			_vfx.impact(_views[ally].get_cast_position(), UnitView.HEAL_COLOR, 0.7)
			_views[ally].play_heal(result.heals[ally])
	await _play_orphans(result.orphaned)
	if result.replaced != null and _views.has(result.replaced):
		_views[result.replaced].play_defeat()
	if result.summoned != null:
		var summoned_view := _spawn_view(result.summoned)
		await summoned_view.play_appear()
	if result.refunded_ap > 0:
		user_view.play_text("+%d PA" % result.refunded_ap, UnitView.HEAL_COLOR)
	if choreo != null:
		await choreo.play(VfxStep.Phase.END, ctx)
		await ctx.finish()
	user_view.refresh_info()

## The skill's choreography: the variant used (rage mutation) or its base skill.
func _choreography_for(result: SkillResult) -> SkillChoreography:
	var used := result.skill.source.choreography as SkillChoreography
	if used == null and result.skill.base != null:
		used = result.skill.base.choreography as SkillChoreography
	return used


## Summons that crumble because their summoner died.
func _play_orphans(units: Array[UnitState]) -> void:
	for unit in units:
		if _views.has(unit):
			_views[unit].play_text("Se deshace", UnitView.CRIT_COLOR)
			_views[unit].play_defeat()
	if not units.is_empty():
		await get_tree().create_timer(0.5).timeout


#endregion


#region Setup

func _prepare_setup() -> bool:
	if setup == null or rules == null or unit_view_scene == null:
		push_error("BattleController: setup, rules and unit_view_scene must be assigned.")
		return false
	if setup.map == null:
		if setup.zone == null:
			push_error("BattleController: the setup needs a map or a zone to generate one.")
			return false
		setup = setup.duplicate()
		var map_seed := setup.rng_seed if setup.rng_seed != 0 else randi()
		setup.map = MapGenerator.generate(setup.zone, rules, map_seed,
			setup.player_units.size(), setup.enemy_units.size())
	var errors := setup.map.validate()
	for error in errors:
		push_error("Map '%s': %s" % [setup.map.display_name, error])
	return errors.is_empty()


func _show_ai_skill_preview(unit: UnitState, action: AiAction) -> void:
	var effective := combat.get_effective(unit, action.skill)
	var landing := combat.get_landing_cell(unit, effective, unit.cell, action.cell)
	var from := _chest(unit.cell, unit)
	if landing != unit.cell:
		_highlighter.show_cell(TileHighlighter.Layer.LANDING, landing)
		_arrows.add(from, _ground(landing), FeedbackArrows.Kind.MOTION)
		from = _chest(landing, unit)
	if effective.summon != null:
		_highlighter.show_cells(TileHighlighter.Layer.LANDING, get_aura_cells(effective.summon, action.cell))
		_arrows.add(from, _ground(action.cell), FeedbackArrows.Kind.MOTION)
	if effective.deals_damage():
		_highlighter.show_cells(TileHighlighter.Layer.AREA, combat.get_skill_area(unit, effective, unit.cell, action.cell))
		if effective.target_rule != SkillData.TargetRule.SELF:
			var target := combat.get_unit_at(action.cell)
			_arrows.add(from, _chest(action.cell, target) if target != null else _ground(action.cell), FeedbackArrows.Kind.ATTACK)
	_arrows.commit()


## Cells a summon's aura would cover if placed on [param cell].
func get_aura_cells(summon: UnitData, cell: Vector2i) -> Array[Vector2i]:
	var radius := summon.aura.radius if summon.aura != null else 0
	return AreaShape.get_cells(AreaShape.Shape.DIAMOND, cell, radius).filter(
		func(c: Vector2i) -> bool: return combat.grid.is_inside(c))


func _clear_feedback() -> void:
	_highlighter.clear_all()
	_arrows.clear()


func _chest(cell: Vector2i, unit: UnitState) -> Vector3:
	var scale_factor := unit.data.sprite_scale if unit != null else 1.0
	return _map_view.cell_to_world(cell) + Vector3.UP * 0.55 * scale_factor


func _ground(cell: Vector2i) -> Vector3:
	return _map_view.cell_to_world(cell) + Vector3.UP * 0.12


func _apply_zone_look(zone: ZoneData) -> void:
	if zone == null:
		return
	var environment := _environment.environment
	environment.background_color = zone.background_color
	environment.ambient_light_color = zone.ambient_color
	environment.ambient_light_energy = zone.ambient_energy
	_sun.light_color = zone.sun_color
	_sun.light_energy = zone.sun_energy
	_sun.rotation_degrees = Vector3(zone.sun_rotation_degrees.x, zone.sun_rotation_degrees.y, 0.0)
	environment.fog_enabled = zone.fog_density > 0.0
	environment.fog_light_color = zone.fog_color
	environment.fog_density = zone.fog_density
	environment.glow_enabled = zone.glow_intensity > 0.0
	environment.glow_intensity = zone.glow_intensity
	if zone.ambient_particles != null:
		var particles: AmbientParticles = zone.ambient_particles.instantiate()
		add_child(particles)
		particles.cover(_map_view.get_bounds())


func _spawn_views() -> void:
	for unit in combat.units:
		_spawn_view(unit)


func _spawn_view(unit: UnitState) -> UnitView:
	var view: UnitView = unit_view_scene.instantiate()
	_units_root.add_child(view)
	view.setup(unit, _map_view, _camera_rig.get_camera())
	_views[unit] = view
	return view


func _connect_signals() -> void:
	combat.turn_started.connect(_on_turn_started)
	combat.turn_ended.connect(_on_turn_ended)
	combat.unit_facing_changed.connect(_on_unit_facing_changed)
	combat.unit_stats_changed.connect(_on_unit_stats_changed)
	combat.combat_finished.connect(_on_combat_finished)
	_hud.restart_requested.connect(_on_result_confirmed)


func _refresh_turn_queue() -> void:
	_hud.show_turn_queue(combat.get_turn_preview(QUEUE_PREVIEW_SIZE))

#endregion


func _on_turn_started(unit: UnitState) -> void:
	_views[unit].set_active(true)


func _on_turn_ended(unit: UnitState) -> void:
	_views[unit].set_active(false)


func _on_unit_facing_changed(unit: UnitState) -> void:
	if _views.has(unit):
		_views[unit].face(unit.facing)


## Objective panel and the escape zone on the ground.
func _show_objective() -> void:
	var hero := combat.units.filter(func(u: UnitState) -> bool: return u.is_protagonist)
	var name := (hero[0] as UnitState).display_name if not hero.is_empty() else "tu protagonista"
	match combat.objective:
		CombatState.OBJECTIVE_ESCAPE:
			_highlighter.show_cells(TileHighlighter.Layer.OBJECTIVE, combat.exit_cells)
			_hud.set_objective("Objetivo opcional: lleva a %s a la zona turquesa del borde. Escapar gana el combate y da premio extra (modificador + oro)." % name)
		CombatState.OBJECTIVE_PROTECT:
			_update_protect_objective()
		_:
			_hud.set_objective("")


func _update_protect_objective() -> void:
	var cart := combat.objective_unit
	if cart.is_alive():
		_hud.set_objective("Objetivo opcional: que la carreta siga en pie al ganar (%d/%d PV). Premio extra: modificador + oro." % [cart.hp, cart.max_hp])
	else:
		_hud.set_objective("La carreta ha caído: ganarás sin premio extra.", true)


func _on_unit_stats_changed(unit: UnitState) -> void:
	if combat.objective == CombatState.OBJECTIVE_PROTECT and unit == combat.objective_unit:
		_update_protect_objective()
	if not _views.has(unit):
		return
	_views[unit].refresh_info()
	if unit == combat.active_unit:
		_hud.show_unit(unit)


func _on_combat_finished(winner: UnitState.Team) -> void:
	_player_input.end_turn_input()
	_clear_feedback()
	var victory := winner == UnitState.Team.PLAYER
	_hud.set_message("¡Victoria!" if victory else "Derrota")
	if combat.escaped:
		_hud.set_message("¡Escapada! Objetivo cumplido")
	elif victory and combat.objective != 0:
		_hud.set_objective("Objetivo cumplido: premio extra." if combat.is_objective_met() else "Objetivo fallido: sin premio extra.",
			not combat.is_objective_met())
	elif not victory and combat.units.any(func(u: UnitState) -> bool: return u.is_protagonist and not u.is_alive()):
		_hud.set_message("Derrota: ha caído tu protagonista")
	# Let the last hit animation play before covering the screen.
	await get_tree().create_timer(RESULT_DELAY).timeout
	_hud.show_result(victory)


func _on_result_confirmed() -> void:
	if _owned_by_game():
		_game.finish_battle(combat.winner == UnitState.Team.PLAYER, combat)
	else:
		get_tree().reload_current_scene()


## True when this battle was launched by GameSession (run or quick battle).
func _owned_by_game() -> bool:
	return _game != null and _game.owns_battle()
