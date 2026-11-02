class_name BattleController
extends Node3D
## Root of a combat scene.
##
## Builds CombatState (rules) from a BattleSetup (data), spawns the views and
## runs the turn loop. Player turns are delegated to PlayerTurnInput and enemy
## turns to BasicAI. Both go through the same execute_* methods, which apply
## the command to the rules and then await the matching animation.

const QUEUE_PREVIEW_SIZE := 6
const AI_THINK_TIME := 0.45
const AI_STEP_TIME := 0.25
const MAX_AI_STEPS := 8

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

var combat: CombatState

var _views: Dictionary[UnitState, UnitView] = {}
var _ai := BasicAI.new()


func _ready() -> void:
	if not _validate_setup():
		return
	combat = CombatState.from_setup(setup, rules)
	_map_view.build(combat.grid)
	_highlighter.setup(_map_view)
	_camera_rig.set_bounds(_map_view.get_bounds())
	_camera_rig.focus_on(_map_view.get_center(), true)
	_spawn_views()
	_connect_signals()
	_hud.set_title(setup.title)
	_hud.set_camera(_camera_rig.get_camera())
	_player_input.setup(self, _map_view, _highlighter, _camera_rig.get_camera(), _hud)
	_run_next_turn.call_deferred()


func get_view(unit: UnitState) -> UnitView:
	return _views.get(unit)


#region Commands shared by player and AI

func execute_move(destination: Vector2i) -> void:
	var unit := combat.active_unit
	var from_cell := unit.cell
	var path := combat.move_active_unit(destination)
	if path.is_empty():
		return
	await _views[unit].play_move(from_cell, path)
	_camera_rig.home_position = _map_view.cell_to_world(unit.cell)


func execute_skill(skill: SkillData, target_cell: Vector2i) -> void:
	var result := combat.use_skill(skill, target_cell)
	if result == null:
		return
	_hud.set_message("%s usa %s" % [result.user.display_name, skill.display_name],
		result.user.team == UnitState.Team.ENEMY)
	await _views[result.user].play_attack(target_cell)
	for hit in result.hits:
		await _views[hit.target].play_hit(hit)
		if hit.defeated:
			await _views[hit.target].play_defeat()
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
	_camera_rig.home_position = _map_view.cell_to_world(unit.cell)
	_camera_rig.focus_on(_camera_rig.home_position)
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
				_highlighter.show_cell(TileHighlighter.Layer.CURSOR, action.cell)
				await get_tree().create_timer(AI_STEP_TIME).timeout
				_highlighter.clear_all()
				await execute_move(action.cell)
			AiAction.Kind.SKILL:
				_highlighter.show_cells(TileHighlighter.Layer.AREA, combat.get_effect_cells(action.skill, unit.cell, action.cell))
				await get_tree().create_timer(AI_STEP_TIME).timeout
				_highlighter.clear_all()
				await execute_skill(action.skill, action.cell)
			AiAction.Kind.END_TURN:
				execute_end_turn(action.facing)
				return
	execute_end_turn(unit.facing)

#endregion


func _spawn_views() -> void:
	for unit in combat.units:
		var view: UnitView = unit_view_scene.instantiate()
		_units_root.add_child(view)
		view.setup(unit, _map_view, _camera_rig.get_camera())
		_views[unit] = view


func _connect_signals() -> void:
	combat.turn_started.connect(_on_turn_started)
	combat.turn_ended.connect(_on_turn_ended)
	combat.unit_facing_changed.connect(_on_unit_facing_changed)
	combat.unit_stats_changed.connect(_on_unit_stats_changed)
	combat.combat_finished.connect(_on_combat_finished)
	_hud.restart_requested.connect(_on_restart_requested)


func _refresh_turn_queue() -> void:
	_hud.show_turn_queue(combat.get_turn_preview(QUEUE_PREVIEW_SIZE))


func _validate_setup() -> bool:
	if setup == null or setup.map == null or rules == null or unit_view_scene == null:
		push_error("BattleController: setup, setup.map, rules and unit_view_scene must be assigned.")
		return false
	var errors := setup.map.validate()
	for error in errors:
		push_error("Map '%s': %s" % [setup.map.resource_path, error])
	return errors.is_empty()


func _on_turn_started(unit: UnitState) -> void:
	_views[unit].set_active(true)


func _on_turn_ended(unit: UnitState) -> void:
	_views[unit].set_active(false)


func _on_unit_facing_changed(unit: UnitState) -> void:
	_views[unit].face(unit.facing)


func _on_unit_stats_changed(unit: UnitState) -> void:
	_views[unit].refresh_info()
	if unit == combat.active_unit:
		_hud.show_unit(unit)


func _on_combat_finished(winner: UnitState.Team) -> void:
	_player_input.end_turn_input()
	_highlighter.clear_all()
	var victory := winner == UnitState.Team.PLAYER
	_hud.set_message("¡Victoria!" if victory else "Derrota")
	# Let the last hit animation play before covering the screen.
	await get_tree().create_timer(1.2).timeout
	_hud.show_result(victory)


func _on_restart_requested() -> void:
	get_tree().reload_current_scene()
