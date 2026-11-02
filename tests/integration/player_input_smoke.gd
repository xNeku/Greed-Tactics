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
	while turns < PLAYER_TURNS and (Time.get_ticks_msec() - started) / 1000.0 < TIMEOUT_SECONDS:
		await process_frame
		var combat := battle.combat
		if combat == null or combat.is_finished():
			break
		if input.get("_mode") == PlayerTurnInput.Mode.DISABLED:
			continue
		var unit := combat.active_unit
		turns += 1
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
	print("Player turns: %d · skills used: %d · script errors: %d %s" % [turns, skills_used, errors.count, errors.first])
	OS.remove_logger(errors)
	quit(0 if errors.count == 0 and turns > 0 else 1)
