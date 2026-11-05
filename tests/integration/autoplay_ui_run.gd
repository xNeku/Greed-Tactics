extends SceneTree
## End-to-end smoke test of the real screens: main menu -> run map -> battle
## (autoplay) / recruit -> reward -> ... -> run end. Fails on script errors or timeout.
## With a display (or xvfb) and a folder argument it also saves one screenshot
## per screen: godot --script res://tests/integration/autoplay_ui_run.gd -- /tmp/shots

const GAME_SCENE := "res://scenes/app/game.tscn"
const TIMEOUT_SECONDS := 240.0
const TIME_SCALE := 6.0


class ErrorCounter extends Logger:
	var count := 0
	var first := ""

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		if count == 0:
			first = "%s %s (%s:%d)" % [code, rationale, file, line]
		count += 1


var _shots_dir := ""
var _shot_index := 0


func _initialize() -> void:
	var errors := ErrorCounter.new()
	OS.add_logger(errors)
	var args := OS.get_cmdline_user_args()
	_shots_dir = args[0] if not args.is_empty() else ""
	# The "Game" autoload is also loaded in --script mode; create it only if missing.
	var game := root.get_node_or_null(^"Game") as GameSession
	if game == null:
		game = load(GAME_SCENE).instantiate()
		game.name = "Game"
		root.add_child(game)
	game.autoplay_battles = true
	change_scene_to_file(GameSession.MAIN_MENU)
	await _frames(20)
	await _shot("menu")
	Engine.time_scale = TIME_SCALE
	game.new_run(4242)

	var started := Time.get_ticks_msec()
	var battles := 0
	var seen_reward := false
	while (Time.get_ticks_msec() - started) / 1000.0 < TIMEOUT_SECONDS:
		await _frames(5)
		var scene := current_scene
		if scene == null:
			continue
		match scene.scene_file_path:
			GameSession.RUN_MAP:
				await _frames(10)
				if battles < 2:
					await _shot("run_map")
				var choices := game.run.get_choices()
				var pick: RunMap.MapNode = choices[0]
				for node in choices:
					if node.kind == RunMap.Kind.RECRUIT and not game.run.is_party_full():
						pick = node
				game.choose_map_node(pick)
				await _frames(10)
			GameSession.RECRUIT:
				await _frames(10)
				await _shot("recruit")
				game.recruit(game.run.recruit_offer[0])
				await _frames(10)
			GameSession.BATTLE:
				var battle := scene as BattleController
				while battle.combat == null or not battle.combat.is_finished():
					await _frames(10)
					if battles == 0 and battle.combat != null and battle.combat.turn_count == 4:
						await _shot("battle")
				battles += 1
				await create_timer(BattleController.RESULT_DELAY + 0.5).timeout
				if battles == 1:
					await _shot("battle_result")
				game.finish_battle(battle.combat.winner == UnitState.Team.PLAYER, battle.combat)
				await _frames(10)
			GameSession.REWARD:
				await _frames(10)
				if not game.run.offer.is_empty() and not seen_reward:
					seen_reward = true
					await _shot("reward")
				if not game.run.offer.is_empty():
					game.run.choose_modifier(game.run.offer[0])
				game.continue_after_reward()
				await _frames(10)
			GameSession.RUN_END:
				await _frames(10)
				await _shot("run_end")
				print("Run ended: %s after %d battles. Script errors: %d" % [
					RunState.Status.keys()[game.run.status], battles, errors.count])
				if errors.count > 0:
					print("First error: " + errors.first)
				OS.remove_logger(errors)
				quit(0 if errors.count == 0 else 1)
				return
	print("FAIL: timeout after %d battles. Script errors: %d %s" % [battles, errors.count, errors.first])
	OS.remove_logger(errors)
	quit(1)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _shot(label: String) -> void:
	if _shots_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	_shot_index += 1
	root.get_texture().get_image().save_png(_shots_dir.path_join("%02d_%s.png" % [_shot_index, label]))
