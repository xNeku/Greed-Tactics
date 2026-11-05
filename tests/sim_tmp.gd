extends SceneTree
func _initialize() -> void:
	await process_frame
	var rules := load("res://content/rules/default_rules.tres") as RulesConfig
	var cfg := load("res://content/run/default_run.tres") as RunConfig
	var run := RunState.new(cfg, rules, 1001, [cfg.roster[1]] as Array[UnitData])
	var node: RunMap.MapNode = run.get_choices()[0]
	run.choose_node(node)
	var setup := run.start_battle()
	print("zone ", setup.zone.display_name, " objective ", setup.objective, " enemies ", setup.enemy_units.map(func(u): return u.display_name), " lvl ", setup.enemy_level, " player lvl ", setup.player_level, " hp ", setup.player_hp, " map ", setup.map.get_size())
	var combat := CombatState.from_setup(setup, rules)
	for u in combat.units: print("  ", u.display_name, " team ", u.team, " hp ", u.hp, "/", u.max_hp, " atk ", u.attack, " cell ", u.cell, " prot ", u.is_protagonist)
	var ai := BasicAI.new()
	while not combat.is_finished() and combat.turn_count < 60:
		var u := combat.start_next_turn()
		if u.skip_turn or u.is_structure():
			combat.end_turn(u.facing); continue
		for s in 12:
			var a := ai.decide(combat, u)
			if a.kind == AiAction.Kind.MOVE: combat.move_active_unit(a.cell)
			elif a.kind == AiAction.Kind.SKILL:
				var r := combat.use_skill(a.skill, a.cell)
				print("  T%d %s uses %s -> %s" % [combat.turn_count, u.display_name, a.skill.display_name, r.hits.map(func(h): return "%s -%d" % [h.target.display_name, h.damage])])
			else:
				combat.end_turn(a.facing); break
			if combat.is_finished(): break
	print("winner ", combat.winner, " turns ", combat.turn_count)
	quit()
