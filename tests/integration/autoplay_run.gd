extends SceneTree
## Simulates whole runs in pure rules (no scenes): procedural maps, both teams
## driven by BasicAI, rewards picked at random. Fails on script errors or if a
## battle gets stuck. Prints balance stats.
## Usage: godot --headless --script res://tests/integration/autoplay_run.gd [-- runs [protagonist_id]]

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
	# Optional second argument: protagonist id (default: each run cycles the roster).
	var forced: UnitData = null
	if args.size() > 1:
		for hero in config.roster:
			if hero.id == StringName(args[1]):
				forced = hero
	var stuck := false
	var wins := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for r in runs:
		var protagonist := forced if forced != null else config.roster[r % config.roster.size()]
		var run := RunState.new(config, rules, 1000 + r, [protagonist] as Array[UnitData])
		var started := Time.get_ticks_msec()
		while run.status == RunState.Status.MAP or run.status == RunState.Status.RECRUIT:
			if run.status == RunState.Status.RECRUIT:
				run.choose_recruit(run.recruit_offer[rng.randi_range(0, run.recruit_offer.size() - 1)])
				continue
			run.heal_party()
			var node := _pick_node(run, rng)
			run.choose_node(node)
			if not node.is_battle():
				continue
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
					if unit.summoner == null and unit != combat.objective_unit:
						hp.append(unit.hp)
				elif unit.summoner == null:
					enemies.append(unit.data)
			var victory := combat.winner == UnitState.Team.PLAYER
			print("  %s · %s · grupo %d -> %s in %d turns (%s)" % [run.get_title(), RunMap.Kind.keys()[node.kind],
				run.heroes.size(), "win" if victory else "LOSS", combat.turn_count,
				"x".join([setup.map.get_size().x, setup.map.get_size().y])])
			var reward := run.complete_battle(victory, hp, enemies, combat.turn_count, combat.is_objective_met())
			if reward == null:
				break
			if not run.offer.is_empty():
				run.choose_modifier(run.offer[rng.randi_range(0, run.offer.size() - 1)])
			run.advance()
		if run.status == RunState.Status.WON:
			wins += 1
		print("Run %d (%s): %s · level %d · party %d · %d battles · %d turns · %.1fs" % [r + 1, protagonist.display_name,
			RunState.Status.keys()[run.status], run.level, run.heroes.size(), run.battles_won, run.total_turns,
			(Time.get_ticks_msec() - started) / 1000.0])
	print("Runs won: %d/%d · script errors: %d" % [wins, runs, errors.count])
	OS.remove_logger(errors)
	quit(0 if not stuck and errors.count == 0 else 1)


## A sensible player: recruit while the party is small, rest when hurt,
## elites only when healthy, otherwise any battle.
func _pick_node(run: RunState, rng: RandomNumberGenerator) -> RunMap.MapNode:
	var choices := run.get_choices()
	var hurt := run.get_protagonist().hp < run.get_protagonist().get_max_hp(run.level) * 0.5
	var best: RunMap.MapNode = null
	var best_score := -INF
	for node in choices:
		var score := rng.randf()
		match node.kind:
			RunMap.Kind.RECRUIT:
				score += 5.0 if not run.is_party_full() else -1.0
			RunMap.Kind.REST:
				score += 4.0 if hurt else 0.5
			RunMap.Kind.ELITE:
				score += -3.0 if hurt else 0.8
		if score > best_score:
			best_score = score
			best = node
	return best


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
