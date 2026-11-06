extends SceneTree
## Integration smoke test of the menus (v0.10): main menu, characters screen
## (every hero, equipping a weapon) and the run end screen with its XP
## animation, on a sample profile. Fails on any script error.
## Usage: godot --headless --script res://tests/integration/menus_smoke.gd

class ErrorCounter extends Logger:
	var count := 0
	var first := ""

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		count += 1
		if first.is_empty():
			first = "%s %s (%s:%d)" % [code, rationale, file, line]


func _initialize() -> void:
	var errors := ErrorCounter.new()
	OS.add_logger(errors)
	await process_frame
	var game := root.get_node(^"Game") as GameSession
	# A sample profile: Sigrid levelled up past V, Pablo walled at V.
	var summary := RunSummary.new()
	summary.hero_id = &"barbarian"
	summary.run_xp = 2400
	summary.bosses_defeated = [&"treant"]
	game.profile.apply_run(game.progression, summary)
	var walled := RunSummary.new()
	walled.hero_id = &"pablo"
	walled.run_xp = 5000
	game.profile.apply_run(game.progression, walled)
	await _show("res://scenes/menu/main_menu.tscn", 20)
	var characters := await _show("res://scenes/meta/characters_screen.tscn", 5)
	for hero in game.run_config.roster:
		characters.call("_select", hero)
		await process_frame
	characters.call("_equip", game.run_config.roster[4], "hacha_pequena")
	await process_frame
	# Run end with a report.
	game.run = RunState.new(game.run_config, game.rules, 3, [game.profile.build_hero(game.progression, game.run_config.roster[0])])
	game.run.status = RunState.Status.LOST
	game.run.xp_earned = 400
	game.last_report = game.profile.apply_run(game.progression, game.run.make_summary())
	await _show("res://scenes/run/run_end_screen.tscn", 240)
	print("Menus: ok · script errors: %d %s" % [errors.count, errors.first])
	quit(0 if errors.count == 0 else 1)


func _show(path: String, frames: int) -> Node:
	for child in root.get_children():
		if child.name != "Game":
			child.queue_free()
	var scene: Node = load(path).instantiate()
	root.add_child(scene)
	for i in frames:
		await process_frame
	return scene
