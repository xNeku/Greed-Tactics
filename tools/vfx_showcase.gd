extends SceneTree
## Plays one skill's choreography in a staged battle so it can be recorded:
##   godot --write-movie out/frame.png --fixed-fps 30 --resolution 1280x720 \
##       --script res://tools/vfx_showcase.gd -- ember_rain
## Shows: ember_rain (Tohil), aimed_shot (Pablo), crushing_leap (Sigrid), shadow_step (Nyx),
## and every kind of projectile (arcane_bolt, ice_lance, fireball, ember,
## light_spear, shot, arrow_rain, point_blank, double_barrel, lead_fan,
## axe_hurl, rubble_throw, taunt_dart).

const SHOWS := {
	"ember_rain": ["shaman", "res://content/skills/shaman/ember_rain.tres", "forest", Vector2i(2, 4), [Vector2i(7, 3), Vector2i(7, 4), Vector2i(8, 5)], Vector2i(7, 4)],
	"aimed_shot": ["pablo", "res://content/skills/archer/aimed_shot.tres", "forest", Vector2i(2, 4), [Vector2i(8, 4), Vector2i(9, 2)], Vector2i(8, 4)],
	"crushing_leap": ["barbarian", "res://content/skills/barbarian/crushing_leap.tres", "desert", Vector2i(3, 4), [Vector2i(7, 3), Vector2i(7, 5), Vector2i(8, 4)], Vector2i(6, 4)],
	"shadow_step": ["nyx", "res://content/skills/assassin/shadow_step.tres", "cave", Vector2i(3, 4), [Vector2i(7, 4), Vector2i(8, 6)], Vector2i(7, 4)],
	"arcane_bolt": ["lyra", "res://content/skills/mage/arcane_bolt.tres", "cave", Vector2i(3, 4), [Vector2i(6, 4)], Vector2i(6, 4)],
	"ice_lance": ["lyra", "res://content/skills/mage/ice_lance.tres", "cave", Vector2i(2, 4), [Vector2i(6, 4)], Vector2i(6, 4)],
	"fireball": ["lyra", "res://content/skills/mage/fireball.tres", "cave", Vector2i(2, 4), [Vector2i(6, 4), Vector2i(6, 3), Vector2i(7, 4)], Vector2i(6, 4)],
	"ember": ["shaman", "res://content/skills/shaman/ember.tres", "forest", Vector2i(2, 4), [Vector2i(7, 4)], Vector2i(7, 4)],
	"light_spear": ["paladin", "res://content/skills/paladin/light_spear.tres", "cave", Vector2i(2, 4), [Vector2i(6, 4)], Vector2i(6, 4)],
	"shot": ["pablo", "res://content/skills/archer/shot.tres", "forest", Vector2i(2, 4), [Vector2i(6, 4)], Vector2i(6, 4)],
	"arrow_rain": ["pablo", "res://content/skills/archer/arrow_rain.tres", "forest", Vector2i(2, 4), [Vector2i(6, 4), Vector2i(7, 3), Vector2i(6, 5)], Vector2i(6, 4)],
	"point_blank": ["gunner", "res://content/skills/gunner/point_blank.tres", "desert", Vector2i(3, 4), [Vector2i(5, 4)], Vector2i(5, 4)],
	"double_barrel": ["gunner", "res://content/skills/gunner/double_barrel.tres", "desert", Vector2i(3, 4), [Vector2i(6, 4)], Vector2i(6, 4)],
	"lead_fan": ["gunner", "res://content/skills/gunner/lead_fan.tres", "desert", Vector2i(3, 4), [Vector2i(5, 4), Vector2i(5, 3), Vector2i(5, 5)], Vector2i(5, 4)],
	"axe_hurl": ["barbarian", "res://content/skills/barbarian/axe_hurl.tres", "desert", Vector2i(3, 4), [Vector2i(6, 4)], Vector2i(6, 4)],
	"rubble_throw": ["kael", "res://content/skills/warrior/rubble_throw.tres", "desert", Vector2i(3, 4), [Vector2i(6, 4)], Vector2i(6, 4)],
	# Combat feedback: multi-strike numbers, criticals, health bars (Alt).
	"carnage": ["barbarian", "res://content/skills/barbarian/savage_cleave.tres", "desert", Vector2i(3, 4), [Vector2i(4, 4), Vector2i(6, 2)], Vector2i(4, 4), {"rage": 100, "enemy_hp": 160}],
	"double_sting": ["nyx", "res://content/skills/assassin/sting.tres", "cave", Vector2i(3, 4), [Vector2i(4, 4), Vector2i(6, 6)], Vector2i(4, 4), {"rage": 100, "enemy_hp": 120}],
	"crit_shot": ["pablo", "res://content/skills/archer/shot.tres", "forest", Vector2i(2, 4), [Vector2i(6, 4), Vector2i(6, 6)], Vector2i(6, 4), {"crit": true, "enemy_hp": 130}],
	"taunt_dart": ["nyx", "res://content/skills/assassin/taunt_dart.tres", "forest", Vector2i(2, 4), [Vector2i(6, 4)], Vector2i(6, 4)],
}


func _initialize() -> void:
	await process_frame
	var key := OS.get_cmdline_user_args()[0]
	var show: Array = SHOWS[key]
	var options: Dictionary = show[6] if show.size() > 6 else {}
	var hero := (load("res://content/units/heroes/%s.tres" % show[0]) as UnitData).duplicate()
	hero.speed = 60  # Acts first.
	if options.get("crit", false):
		hero.crit_chance = 100
	var skill := load(show[1]) as SkillData
	var zone := load("res://content/zones/%s.tres" % show[2]) as ZoneData
	var setup := BattleSetup.new()
	setup.zone = zone
	setup.title = "Muestra de efectos"
	setup.map = _stage_map(zone, show[3], show[4])
	setup.player_units = [hero]
	setup.player_level = 6
	setup.enemy_level = 1
	var dummy := (zone.enemy_pool[0] as UnitData).duplicate()
	dummy.max_hp = options.get("enemy_hp", 400)
	dummy.hp_per_level = 0
	for i in show[4].size():
		setup.enemy_units.append(dummy)
	setup.rng_seed = 11
	var battle: BattleController = load("res://scenes/battle/battle.tscn").instantiate()
	battle.setup = setup
	root.add_child(battle)
	var input := battle.get_node("%PlayerTurnInput") as PlayerTurnInput
	while battle.combat == null or input.get("_mode") == PlayerTurnInput.Mode.DISABLED:
		await process_frame
	input.end_turn_input()
	var unit := battle.combat.active_unit
	if options.has("rage"):
		unit.rage = options["rage"]  # Rage mutation (more strikes).
	elif unit.uses_rage():
		unit.rage = skill.rage_cost  # Enough to cast it, below the mutation threshold.
	var camera := battle.get_node("%CameraRig") as CameraRig
	camera.focus_on(battle.get_node("%BattleMap").cell_to_world(show[3]).lerp(battle.get_node("%BattleMap").cell_to_world(show[5]), 0.5), true)
	if skill.choreography == null:
		camera.set_cinematic_zoom(0.42)
	_caption(battle, "%s · %s" % [hero.display_name, skill.display_name])
	for i in 20:
		await process_frame
	if options.has("enemy_hp"):
		await _show_bars()
	await battle.execute_skill(skill, show[5])
	for i in 30:
		await process_frame
	quit()


## Holds Alt for a moment: every health bar shows.
func _show_bars() -> void:
	var alt := InputEventKey.new()
	alt.keycode = KEY_ALT
	alt.physical_keycode = KEY_ALT
	alt.pressed = true
	Input.parse_input_event(alt)
	for i in 30:
		await process_frame
	var release := alt.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)


## Name of the hero and skill in the corner of the recording.
func _caption(battle: Node, text: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	var label := Label.new()
	label.text = text
	label.position = Vector2(28, 64)
	label.add_theme_font_size_override(&"font_size", 34)
	label.add_theme_constant_override(&"outline_size", 10)
	label.add_theme_color_override(&"font_outline_color", Color(0.05, 0.05, 0.08))
	layer.add_child(label)
	battle.add_child(layer)


## Small flat stage with a couple of raised blocks, using the zone's terrains.
func _stage_map(zone: ZoneData, hero_cell: Vector2i, enemy_cells: Array) -> MapData:
	var floor_symbol := zone.floor_terrain.symbol
	var rows := PackedStringArray()
	var heights := PackedStringArray()
	for y in 9:
		rows.append(floor_symbol.repeat(12))
		var h := ""
		for x in 12:
			h += "1" if (x == 5 and y <= 1) or (x >= 10 and y >= 7) else "0"
		heights.append(h)
	var terrains: Array[TerrainData] = [zone.floor_terrain]
	var map := MapData.create(terrains, rows, heights)
	map.player_spawns = [hero_cell]
	for cell in enemy_cells:
		map.enemy_spawns.append(cell)
	return map
