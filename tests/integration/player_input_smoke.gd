extends SceneTree
## Exercises the human input path in a real battle scene: for several player
## turns, selects every skill, hovers every targetable cell (forecast, area,
## landing) and then uses a skill by "clicking". Enemies play with the AI.
## Fails on script errors. Usage:
##   godot --headless --script res://tests/integration/player_input_smoke.gd

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const PLAYER_TURNS := 12
const TIMEOUT_SECONDS := 120.0


class ErrorCounter extends Logger:
	var count := 0
	var first := ""

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		if count == 0:
			first = "%s %s (%s:%d)" % [code, rationale, file, line]
		count += 1


func _initialize() -> void:
	var errors := ErrorCounter.new()
	OS.add_logger(errors)
	Engine.time_scale = 6.0
	await process_frame
	var battle: BattleController = load(BATTLE_SCENE).instantiate()
	root.add_child(battle)
	var input := battle.get_node("%PlayerTurnInput") as PlayerTurnInput
	var hud := battle.get_node("%HUD") as BattleHud
	var started := Time.get_ticks_msec()
	var turns := 0
	var skills_used := 0
	var menu_checks := ""
	while turns < PLAYER_TURNS and (Time.get_ticks_msec() - started) / 1000.0 < TIMEOUT_SECONDS:
		await process_frame
		var combat := battle.combat
		if combat == null or combat.is_finished():
			break
		if input.get("_mode") == PlayerTurnInput.Mode.DISABLED:
			continue
		var unit := combat.active_unit
		turns += 1
		if turns == 1:
			menu_checks = await _check_command_menu(hud, input)
		var used := false
		for skill in unit.data.skills:
			if not combat.can_use_skill(unit, skill):
				continue
			hud.skill_selected.emit(skill)
			var cells: Array[Vector2i] = combat.get_targetable_cells(unit, skill, unit.cell)
			for cell in cells:
				input.set("_hover", cell)
				input.call("_on_hover_changed")
			if not used and not cells.is_empty():
				used = true
				skills_used += 1
				input.call("_on_cell_clicked", cells[0])
				while input.get("_mode") == PlayerTurnInput.Mode.DISABLED and not combat.is_finished() \
						and combat.active_unit == unit:
					await process_frame
				break
		if combat.is_finished() or combat.active_unit != unit:
			continue
		hud.wait_selected.emit()
		hud.wait_selected.emit()
		while combat.active_unit == unit and not combat.is_finished():
			await process_frame
	print("Player turns: %d · skills used: %d · menu: %s · script errors: %d %s" % [turns, skills_used,
		"ok" if menu_checks.is_empty() else menu_checks, errors.count, errors.first])
	OS.remove_logger(errors)
	quit(0 if errors.count == 0 and turns > 0 and menu_checks.is_empty() else 1)


## Main page -> Atacar -> skill 1 -> Esc -> Esc, through the real buttons and
## the cancel action. Returns "" or what went wrong.
func _check_command_menu(hud: BattleHud, input: PlayerTurnInput) -> String:
	var menu := hud.get_command_menu()
	var numbered: Array = menu.get("_numbered")
	if menu.get_page() != CommandMenu.Page.ROOT or numbered.size() != 3:
		return "the turn does not start on Mover/Atacar/Esperar"
	if numbered[1].disabled:
		return ""  # nothing usable this turn: nothing else to check
	numbered[1].pressed.emit()
	await process_frame
	await process_frame
	if menu.get_page() != CommandMenu.Page.SKILLS:
		return "Atacar does not open the skills page"
	var first: Button = menu.get("_numbered")[0]
	if first.disabled:
		return ""
	first.pressed.emit()
	await process_frame
	if input.get("_mode") != PlayerTurnInput.Mode.TARGET:
		return "picking a skill does not start aiming"
	if (input.get("_highlighter") as TileHighlighter) == null:
		return "no highlighter"
	var cancel := InputEventAction.new()
	cancel.action = &"cancel"
	cancel.pressed = true
	input.call("_unhandled_input", cancel)
	await process_frame
	if menu.get_page() != CommandMenu.Page.SKILLS or input.get("_mode") == PlayerTurnInput.Mode.TARGET:
		return "Esc while aiming does not go back to the skills page"
	input.call("_unhandled_input", cancel)
	await process_frame
	await process_frame
	if menu.get_page() != CommandMenu.Page.ROOT:
		return "Esc on the skills page does not go back to the main actions"
	return ""
