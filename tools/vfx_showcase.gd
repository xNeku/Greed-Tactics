extends SceneTree
## Plays one skill's choreography in a staged battle so it can be recorded:
##   godot --write-movie out/frame.png --fixed-fps 30 --resolution 1280x720 \
##       --script res://tools/vfx_showcase.gd -- ember_rain
## Shows: ember_rain (Tohil), aimed_shot (Pablo), crushing_leap (Sigrid), shadow_step (Nyx).

const SHOWS := {
	"ember_rain": ["shaman", "res://content/skills/shaman/ember_rain.tres", "forest", Vector2i(2, 4), [Vector2i(7, 3), Vector2i(7, 4), Vector2i(8, 5)], Vector2i(7, 4)],
	"aimed_shot": ["pablo", "res://content/skills/archer/aimed_shot.tres", "forest", Vector2i(2, 4), [Vector2i(8, 4), Vector2i(9, 2)], Vector2i(8, 4)],
	"crushing_leap": ["barbarian", "res://content/skills/barbarian/crushing_leap.tres", "desert", Vector2i(3, 4), [Vector2i(7, 3), Vector2i(7, 5), Vector2i(8, 4)], Vector2i(6, 4)],
	"shadow_step": ["nyx", "res://content/skills/assassin/shadow_step.tres", "cave", Vector2i(3, 4), [Vector2i(7, 4), Vector2i(8, 6)], Vector2i(7, 4)],
}


func _initialize() -> void:
	await process_frame
	var key := OS.get_cmdline_user_args()[0]
	var show: Array = SHOWS[key]
	var hero := (load("res://content/units/heroes/%s.tres" % show[0]) as UnitData).duplicate()
	hero.speed = 60  # Acts first.
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
	dummy.max_hp = 400
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
	if unit.uses_rage():
		unit.rage = skill.rage_cost  # Enough to cast it, below the mutation threshold.
	var camera := battle.get_node("%CameraRig") as CameraRig
	camera.focus_on(battle.get_node("%BattleMap").cell_to_world(show[3]).lerp(battle.get_node("%BattleMap").cell_to_world(show[5]), 0.5), true)
	for i in 20:
		await process_frame
	await battle.execute_skill(skill, show[5])
	for i in 30:
		await process_frame
	quit()


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
