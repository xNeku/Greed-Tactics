extends SceneTree
## Integration smoke test: plays the default battle with AI on both sides,
## sped up, and fails if it does not finish or if any script error happens.
## Usage: godot --headless --script res://tests/integration/autoplay_battle.gd [-- zone enemy_id,enemy_id...]
##   e.g. -- desert sand_troll,trasgo_dagger   (default party, level 5)

const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const TIME_SCALE := 8.0
const TIMEOUT_SECONDS := 60.0


class ErrorCounter extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		count += 1


func _initialize() -> void:
	var errors := ErrorCounter.new()
	OS.add_logger(errors)
	Engine.time_scale = TIME_SCALE
	var battle: BattleController = load(BATTLE_SCENE).instantiate()
	battle.autoplay_player_units = true
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		battle.setup = _custom_setup(args[0], args[1])
	root.add_child(battle)

	var started := Time.get_ticks_msec()
	while not (battle.combat != null and battle.combat.is_finished()):
		await process_frame
		if (Time.get_ticks_msec() - started) / 1000.0 > TIMEOUT_SECONDS:
			break

	var finished := battle.combat != null and battle.combat.is_finished()
	if finished:
		var winner := "player" if battle.combat.winner == UnitState.Team.PLAYER else "enemy"
		var summoned := battle.combat.units.filter(func(u: UnitState) -> bool: return u.summoner != null).size()
		print("Battle finished. Winner: %s · turns %d · summoned units %d" % [winner, battle.combat.turn_count, summoned])
	else:
		print("FAIL: battle did not finish in %d s" % TIMEOUT_SECONDS)
	print("Script errors: %d" % errors.count)
	OS.remove_logger(errors)
	quit(0 if finished and errors.count == 0 else 1)


func _custom_setup(zone_id: String, enemy_ids: String) -> BattleSetup:
	var run := load("res://content/run/default_run.tres") as RunConfig
	var setup := BattleSetup.new()
	setup.zone = load("res://content/zones/%s.tres" % zone_id)
	setup.title = "Prueba: %s" % enemy_ids
	setup.player_units = run.heroes.duplicate()
	setup.player_level = 5
	setup.enemy_level = 5
	for id in enemy_ids.split(","):
		setup.enemy_units.append(load("res://content/units/enemies/%s.tres" % id))
	setup.rng_seed = 7
	return setup
