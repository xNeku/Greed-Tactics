extends SceneTree
## Prints the game's progression lines as JSON (for the hero workshop):
##   godot --headless --script res://tools/export_progression.gd -- out.json
## Per hero: [{level, kind: "skill"|"passive"|"stats", name, description, stats}].
## Modifiers and weapons become passives; stat rewards become stats.


func _initialize() -> void:
	var config := load("res://content/meta/progression.tres") as ProgressionConfig
	var result := {}
	for track in config.tracks:
		var entries: Array = []
		for reward in track.rewards:
			match reward.kind:
				ProgressionReward.Kind.STATS:
					var stats := {}
					for pair in [["hp", reward.max_hp], ["attack", reward.attack], ["defense", reward.defense],
							["crit", reward.crit_chance], ["evasion", reward.evasion]]:
						if pair[1] != 0:
							stats[pair[0]] = pair[1]
					entries.append({"level": reward.level, "kind": "stats", "name": "", "description": "", "stats": stats})
				ProgressionReward.Kind.MODIFIER:
					entries.append({"level": reward.level, "kind": "passive", "name": reward.modifier.display_name,
						"description": reward.modifier.description})
				ProgressionReward.Kind.WEAPON:
					entries.append({"level": reward.level, "kind": "passive", "name": "Arma: " + reward.weapon.display_name,
						"description": reward.weapon.description})
		result[String(track.hero.id)] = entries
	var file := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("exported ", result.size(), " heroes")
	quit()
