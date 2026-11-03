extends SceneTree
## Simulates whole runs in pure rules (no scenes): procedural maps, both teams
## driven by BasicAI, rewards picked at random. Fails on script errors or if a
## battle gets stuck. Prints balance stats.
## Usage: godot --headless --script res://tests/integration/autoplay_run.gd [-- runs [hero_id,hero_id,...]]

const MAX_TURNS_PER_BATTLE := 400


class ErrorCounter extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		count += 1


func _initialize() -> void:
	var errors := ErrorCounter.new()
	OS.add_logger(errors)
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0]) if not args.is_empty() else 2
	var config := load("res://content/run/default_run.tres") as RunConfig
	var rules := load("res://content/rules/default_rules.tres") as RulesConfig
	# Optional second argument: hero ids for the party, e.g. "nyx,paladin,gunner,kael".
	var party: Array[UnitData] = []
	if args.size() > 1:
		for id in args[1].split(","):
			for hero in config.roster:
				if hero.id == StringName(id):
					party.append(hero)
	var stuck := false
	var wins := 0
	for r in runs:
		var run := RunState.new(config, rules, 1000 + r, party)
		var started := Time.get_ticks_msec()
		while run.status == RunState.Status.MAP:
			run.heal_party()
			var setup := run.start_battle()
			var combat := CombatState.from_setup(setup, rules)
			if not _play(combat):
				stuck = true
				print("  STUCK in %s" % run.get_title())
				for unit in combat.get_living_units():
					print("    %s %s hp %d/%d at %s h%d" % ["P" if unit.team == UnitState.Team.PLAYER else "E",
						unit.display_name, unit.hp, unit.max_hp, unit.cell, combat.grid.get_height(unit.cell)])
				break
			var hp: Array[int] = []
			var enemies: Array[UnitData] = []
			for unit in combat.units:
				if unit.team == UnitState.Team.PLAYER:
					hp.append(unit.hp)
				else:
					enemies.append(unit.data)
			var victory := combat.winner == UnitState.Team.PLAYER
			print("  %s -> %s in %d turns (%s)" % [run.get_title(), "win" if victory else "LOSS", combat.turn_count,
				"x".join([setup.map.get_size().x, setup.map.get_size().y])])
			var reward := run.complete_battle(victory, hp, enemies, combat.turn_count)
			if reward == null:
				break
			if not run.offer.is_empty():
				run.choose_modifier(run.offer[randi_range(0, run.offer.size() - 1)])
			run.advance()
		if run.status == RunState.Status.WON:
			wins += 1
		print("Run %d: %s · level %d · %d battles · %d turns · %.1fs" % [r + 1, RunState.Status.keys()[run.status],
			run.level, run.battles_won, run.total_turns, (Time.get_ticks_msec() - started) / 1000.0])
	print("Runs won: %d/%d · script errors: %d" % [wins, runs, errors.count])
	OS.remove_logger(errors)
	quit(0 if not stuck and errors.count == 0 else 1)


func _play(combat: CombatState) -> bool:
	var ai := BasicAI.new()
	while not combat.is_finished():
		if combat.turn_count > MAX_TURNS_PER_BATTLE:
			return false
		var unit := combat.start_next_turn()
		for step in 8:
			if combat.is_finished():
				break
			var action := ai.decide(combat, unit)
			if action.kind == AiAction.Kind.MOVE:
				combat.move_active_unit(action.cell)
			elif action.kind == AiAction.Kind.SKILL:
				combat.use_skill(action.skill, action.cell)
			else:
				break
		if not combat.is_finished():
			combat.end_turn(unit.facing)
	return true
