class_name PlayerTurnInput
extends Node
## Human player's turn: hover/click on cells and the command menu.
##
## Modes:
##   MOVE    blue cells = reachable, hover = path preview, click = move.
##   TARGET  orange cells = skill range, hover = area + forecast, click = use.
##   FACING  hover around the unit to pick a facing, click/Enter = end turn.
## Right click / Esc goes back to the default mode.
## Commands go to BattleController.execute_*; this node never touches the rules.

enum Mode { DISABLED, MOVE, TARGET, FACING }

var _controller: BattleController
var _map: BattleMapView
var _highlighter: TileHighlighter
var _camera: Camera3D
var _hud: BattleHud

var _unit: UnitState
var _mode := Mode.DISABLED
var _reach: ReachMap
var _skill: SkillData
var _targetable: Array[Vector2i] = []
var _hover := BattleMapView.INVALID_CELL
var _facing := GridDir.Dir.SOUTH


func setup(controller: BattleController, map_view: BattleMapView, highlighter: TileHighlighter,
		camera: Camera3D, hud: BattleHud) -> void:
	_controller = controller
	_map = map_view
	_highlighter = highlighter
	_camera = camera
	_hud = hud
	_hud.move_selected.connect(_on_move_selected)
	_hud.skill_selected.connect(_on_skill_selected)
	_hud.wait_selected.connect(_on_wait_selected)


func begin_turn(unit: UnitState) -> void:
	_unit = unit
	_enter_default_mode()


## Stops reacting to input (enemy turn, animations, end of combat).
func end_turn_input() -> void:
	_set_mode(Mode.DISABLED)
	_hud.hide_commands()


func _process(_delta: float) -> void:
	# Polled every frame so hover stays correct while the camera moves.
	var cell := _pick_cell_under_mouse()
	if cell != _hover:
		_hover = cell
		_on_hover_changed()


func _unhandled_input(event: InputEvent) -> void:
	if _mode == Mode.DISABLED:
		return
	if event.is_action_pressed("select"):
		_on_cell_clicked(_hover)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		_enter_default_mode()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm") and _mode == Mode.FACING:
		_end_turn()
		get_viewport().set_input_as_handled()


#region Modes

func _enter_default_mode() -> void:
	if _controller.combat.is_finished():
		end_turn_input()
		return
	_reach = _controller.combat.get_reach_map(_unit)
	_refresh_commands()
	if not _reach.get_destinations().is_empty():
		_enter_move_mode()
	elif _first_usable_skill() != null:
		_enter_target_mode(_first_usable_skill())
	else:
		_enter_facing_mode()


func _enter_move_mode() -> void:
	_set_mode(Mode.MOVE)
	_hud.get_command_menu().highlight_move()
	_highlighter.show_cells(TileHighlighter.Layer.MOVE, _reach.get_destinations())
	_on_hover_changed()


func _enter_target_mode(skill: SkillData) -> void:
	_set_mode(Mode.TARGET)
	_skill = skill
	_hud.get_command_menu().highlight_skill(skill)
	_targetable = _controller.combat.get_targetable_cells(_unit, skill, _unit.cell)
	_highlighter.show_cells(TileHighlighter.Layer.TARGET, _targetable)
	var effective := _unit.get_effective(skill)
	_hud.set_message("%s: elige un objetivo%s" % [effective.display_name, "  (ira desatada)" if effective.empowered else ""])
	_on_hover_changed()


func _enter_facing_mode() -> void:
	_set_mode(Mode.FACING)
	_facing = _unit.facing
	_hud.get_command_menu().highlight_wait()
	var around: Array[Vector2i] = []
	for dir in GridDir.ALL:
		var cell := _unit.cell + GridDir.to_vector(dir)
		if _map.get_grid().is_inside(cell):
			around.append(cell)
	_highlighter.show_cells(TileHighlighter.Layer.TARGET, around)
	_hud.set_message("Elige orientación y haz clic (o Enter) para terminar el turno")
	_on_hover_changed()


func _set_mode(mode: Mode) -> void:
	if _mode == Mode.FACING and mode != Mode.FACING and _unit != null:
		_controller.get_view(_unit).face(_unit.facing)
	_mode = mode
	_skill = null
	_targetable.clear()
	_highlighter.clear_all()
	_hud.clear_previews()
	if mode == Mode.MOVE:
		_hud.set_message("Tu turno: %s" % _unit.display_name)

#endregion


#region Hover and click

func _on_hover_changed() -> void:
	if _mode == Mode.DISABLED:
		return
	_highlighter.show_cell(TileHighlighter.Layer.CURSOR, _hover)
	_highlighter.clear(TileHighlighter.Layer.PATH)
	_highlighter.clear(TileHighlighter.Layer.AREA)
	_hud.clear_previews()
	_update_info_panels()
	if _hover == BattleMapView.INVALID_CELL:
		return
	match _mode:
		Mode.MOVE:
			if _reach.can_stop_at(_hover):
				_highlighter.show_cells(TileHighlighter.Layer.PATH, _reach.get_path_to(_hover))
		Mode.TARGET:
			if _targetable.has(_hover):
				_show_skill_forecast(_hover)
		Mode.FACING:
			if _hover != _unit.cell:
				_facing = GridDir.from_delta(_hover - _unit.cell, _facing)
				_controller.get_view(_unit).face(_facing)


func _on_cell_clicked(cell: Vector2i) -> void:
	match _mode:
		Mode.MOVE:
			if _reach.can_stop_at(cell):
				_run_move(cell)
		Mode.TARGET:
			if _targetable.has(cell):
				_run_skill(_skill, cell)
		Mode.FACING:
			_end_turn()


func _show_skill_forecast(target_cell: Vector2i) -> void:
	var combat := _controller.combat
	var effective := combat.get_effective(_unit, _skill)
	var landing := combat.get_landing_cell(_unit, effective, _unit.cell, target_cell)
	if landing != _unit.cell:
		_highlighter.show_cell(TileHighlighter.Layer.PATH, landing)
	if effective.deals_damage():
		_highlighter.show_cells(TileHighlighter.Layer.AREA, combat.get_effect_cells(effective, landing, target_cell))
	var previews := combat.preview_skill(_unit, _skill, _unit.cell, target_cell)
	var anchors: Array[Vector3] = []
	for preview in previews:
		anchors.append(_controller.get_view(preview.target).get_head_position())
	_hud.show_previews(previews, anchors)


func _update_info_panels() -> void:
	var grid := _map.get_grid()
	if _hover == BattleMapView.INVALID_CELL:
		_hud.show_tile(null, 0)
	else:
		_hud.show_tile(grid.get_terrain(_hover), grid.get_height(_hover))
	var active := _controller.combat.active_unit
	var hovered_unit := _controller.combat.get_unit_at(_hover)
	if hovered_unit == null:
		hovered_unit = active
	_hud.show_unit(hovered_unit, hovered_unit == active)

#endregion


#region Actions

func _run_move(cell: Vector2i) -> void:
	_set_mode(Mode.DISABLED)
	_hud.hide_commands()
	await _controller.execute_move(cell)
	_enter_default_mode()


func _run_skill(skill: SkillData, cell: Vector2i) -> void:
	_set_mode(Mode.DISABLED)
	_hud.hide_commands()
	await _controller.execute_skill(skill, cell)
	_enter_default_mode()


func _end_turn() -> void:
	var facing := _facing
	end_turn_input()
	_controller.execute_end_turn(facing)

#endregion


#region Command menu

func _refresh_commands() -> void:
	var usable: Dictionary[SkillData, bool] = {}
	for skill in _unit.data.skills:
		usable[skill] = _can_use(skill)
	_hud.show_commands(_unit, not _reach.get_destinations().is_empty(), usable)


func _on_move_selected() -> void:
	if _mode != Mode.DISABLED and not _reach.get_destinations().is_empty():
		_enter_move_mode()


func _on_skill_selected(skill: SkillData) -> void:
	if _mode != Mode.DISABLED and _can_use(skill):
		_enter_target_mode(skill)


func _on_wait_selected() -> void:
	if _mode == Mode.FACING:
		_end_turn()
	elif _mode != Mode.DISABLED:
		_enter_facing_mode()


func _can_use(skill: SkillData) -> bool:
	return _controller.combat.can_use_skill(_unit, skill)


func _first_usable_skill() -> SkillData:
	var basic := _unit.get_basic_skill()
	if basic != null and _can_use(basic) and _has_target_in_range(basic):
		return basic
	return null


func _has_target_in_range(skill: SkillData) -> bool:
	var combat := _controller.combat
	var effective := combat.get_effective(_unit, skill)
	for cell in combat.get_targetable_cells(_unit, skill, _unit.cell):
		if not combat.get_skill_targets(_unit, effective, _unit.cell, cell).is_empty():
			return true
	return false

#endregion


func _pick_cell_under_mouse() -> Vector2i:
	if _map == null or _camera == null:
		return BattleMapView.INVALID_CELL
	var mouse := _camera.get_viewport().get_mouse_position()
	return _map.pick_cell(_camera.project_ray_origin(mouse), _camera.project_ray_normal(mouse))
