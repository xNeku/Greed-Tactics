extends SceneTree
## Stages a battle on a generated map of a zone to look at the scenery:
##   godot --resolution 1280x720 --script res://tools/scene_showcase.gd -- <zone> <seed> [out.png] [mood] [boss] [zoom] [dais]
## With an output path it saves a screenshot and quits; with --write-movie it
## slowly orbits the camera for a few seconds (a scenery video).

const HEROES := ["kael", "pablo", "shaman", "barbarian"]


func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var zone := load("res://content/zones/%s.tres" % args[0]) as ZoneData
	var map_seed := int(args[1]) if args.size() > 1 else 1
	var out := args[2] if args.size() > 2 and args[2] != "-" else ""
	var mood := args[3] if args.size() > 3 else ""
	var boss := args.size() > 4 and args[4] == "boss"
	var setup := BattleSetup.new()
	setup.zone = zone
	setup.title = zone.display_name
	for id in HEROES:
		setup.player_units.append(load("res://content/units/heroes/%s.tres" % id))
	if boss and not zone.miniboss_pool.is_empty():
		setup.enemy_units.append(zone.miniboss_pool[0])
	for i in 4:
		setup.enemy_units.append(zone.enemy_pool[i % zone.enemy_pool.size()])
	setup.rng_seed = map_seed
	setup.is_boss_battle = boss
	setup.lighting_mood = mood
	var battle: BattleController = load("res://scenes/battle/battle.tscn").instantiate()
	battle.setup = setup
	root.add_child(battle)
	while battle.combat == null:
		await process_frame
	var input := battle.get_node("%PlayerTurnInput") as PlayerTurnInput
	for i in 10:
		await process_frame
	input.end_turn_input()
	(battle.get_node("%TileHighlighter") as Node3D).visible = false
	var hud := battle.get_node("%HUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var camera := battle.get_node("%CameraRig") as CameraRig
	var map := battle.get_node("%BattleMap") as BattleMapView
	var focus := map.get_center()
	if boss and args.size() > 6 and args[6] == "dais":
		focus = map.cell_to_world(battle.combat.get_living_units(UnitState.Team.ENEMY)[0].cell)
	camera.focus_on(focus, true)
	camera.set_cinematic_zoom(float(args[5]) if args.size() > 5 else 1.15)
	for i in 40:
		await process_frame
		camera.focus_on(focus, i < 2)
	if not out.is_empty():
		root.get_texture().get_image().save_png(out)
		quit()
		return
	# Movie: a slow orbit (frames from the 8th argument, default 150).
	var frames := int(args[7]) if args.size() > 7 else 150
	for i in frames:
		camera.rotate_view(0.006)
		await process_frame
	quit()
