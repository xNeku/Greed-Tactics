class_name GameSession
extends Node
## Autoload "Game": the application flow between screens.
##
## Holds the current RunState and hands battles to battle.tscn. It is the only
## place that changes scenes, so every screen stays independent:
##   main menu -> run map -> (battle -> reward | recruit | rest) -> run map ... -> run end
##   main menu -> quick battle -> main menu

const MAIN_MENU := "res://scenes/menu/main_menu.tscn"
const RUN_MAP := "res://scenes/run/run_map.tscn"
const REWARD := "res://scenes/run/reward_screen.tscn"
const RECRUIT := "res://scenes/run/recruit_screen.tscn"
const RUN_END := "res://scenes/run/run_end_screen.tscn"
const BATTLE := "res://scenes/battle/battle.tscn"
const CHARACTERS := "res://scenes/meta/characters_screen.tscn"

@export var run_config: RunConfig = preload("res://content/run/default_run.tres")
@export var rules: RulesConfig = preload("res://content/rules/default_rules.tres")
@export var progression: ProgressionConfig = preload("res://content/meta/progression.tres")
## Party level used by quick battles.
@export var quick_battle_level := 3
## Debug/balance: battles launched by the game play themselves (AI on both sides).
@export var autoplay_battles := false

var run: RunState
## The saved account (levels, unlocks, stats). Loaded at start.
var profile: PlayerProfile
## What the last finished run gave (end screen).
var last_report: RunReport

var _pending_battle: BattleSetup
var _battle_owned := false
var _quick_battle := false
var _run_booked := false


func _ready() -> void:
	profile = ProfileStore.load_profile() if _can_save() else PlayerProfile.new()


## Headless runs (tests, simulations) never touch the player's save.
func _can_save() -> bool:
	return DisplayServer.get_name() != "headless"


func save_profile() -> void:
	if _can_save():
		ProfileStore.save_profile(profile)


#region Run

## [param protagonist] = the hero the run starts with (null = default).
## The protagonist carries its account unlocks (stats, weapon, modifiers).
func new_run(run_seed: int = 0, protagonist: UnitData = null) -> void:
	if protagonist == null:
		protagonist = run_config.heroes[0]
	var party: Array[UnitData] = [profile.build_hero(progression, protagonist)]
	run = RunState.new(run_config, rules, run_seed, party)
	run.modifiers.append_array(profile.get_modifiers(progression, protagonist.id))
	_run_booked = false
	last_report = null
	_change_scene(RUN_MAP)


## Books the finished (or abandoned) run on the protagonist's account, once.
func _book_run() -> void:
	if run == null or _run_booked:
		return
	_run_booked = true
	last_report = profile.apply_run(progression, run.make_summary())
	save_profile()


func open_characters() -> void:
	_change_scene(CHARACTERS)


func is_in_run() -> bool:
	return run != null and run.status != RunState.Status.WON and run.status != RunState.Status.LOST


## Picks a node of the run map and opens what it leads to.
func choose_map_node(node: RunMap.MapNode) -> void:
	if run == null or not run.choose_node(node):
		return
	if node.is_battle():
		_launch(run.start_battle(), false)
	else:
		_go_to_run_screen()


func continue_after_reward() -> void:
	run.advance()
	_go_to_run_screen()


## Recruits come with their own account stats and weapon (not modifiers:
## those are the protagonist's).
func recruit(data: UnitData) -> void:
	if run.choose_recruit(data):
		var hero := run.heroes[-1]
		hero.data = profile.build_hero(progression, data)
		hero.hp = hero.get_max_hp(run.level)
		_go_to_run_screen()


func skip_recruit() -> void:
	run.skip_recruit()
	_go_to_run_screen()


func _go_to_run_screen() -> void:
	match run.status:
		RunState.Status.WON, RunState.Status.LOST:
			_book_run()
			_change_scene(RUN_END)
		RunState.Status.RECRUIT:
			_change_scene(RECRUIT)
		_:
			_change_scene(RUN_MAP)


## Leaves the run: XP earned so far still counts (booked as a defeat).
func abandon_run() -> void:
	if is_in_run():
		run.status = RunState.Status.LOST
	_book_run()
	run = null
	_change_scene(MAIN_MENU)

#endregion


#region Quick battle

## A single battle on a random map of [param zone] (random zone if null).
func start_quick_battle(zone: ZoneData = null, party: Array[UnitData] = []) -> void:
	var zones := run_config.zones
	if zone == null:
		zone = zones[randi_range(0, zones.size() - 1)]
	var setup := BattleSetup.new()
	setup.title = "Combate rápido: %s" % zone.display_name
	setup.zone = zone
	setup.player_units = party.duplicate() if not party.is_empty() else run_config.heroes.duplicate()
	setup.player_level = quick_battle_level
	setup.enemy_level = quick_battle_level
	for i in 5:
		setup.enemy_units.append(zone.enemy_pool[randi_range(0, zone.enemy_pool.size() - 1)])
	setup.rng_seed = randi()
	_launch(setup, true)

#endregion


#region Battle handshake (used by BattleController)

func has_pending_battle() -> bool:
	return _pending_battle != null


func take_pending_battle() -> BattleSetup:
	var setup := _pending_battle
	_pending_battle = null
	return setup


func owns_battle() -> bool:
	return _battle_owned


## Called when battle.tscn is opened directly (F6): the game does not own it.
func release_battle() -> void:
	_battle_owned = false


func get_result_button_text() -> String:
	return "Volver al menú" if _quick_battle else "Continuar"


func finish_battle(victory: bool, combat: CombatState) -> void:
	_battle_owned = false
	if _quick_battle:
		_change_scene(MAIN_MENU)
		return
	var hp: Array[int] = []
	var enemies: Array[UnitData] = []
	for unit in combat.units:
		if unit.team == UnitState.Team.PLAYER:
			if unit.summoner == null and unit != combat.objective_unit:
				hp.append(unit.hp)
		elif unit.summoner == null:
			enemies.append(unit.data)
	run.complete_battle(victory, hp, enemies, combat.turn_count, combat.is_objective_met())
	if run.status == RunState.Status.LOST:
		_book_run()
	_change_scene(REWARD if run.status == RunState.Status.REWARD else RUN_END)

#endregion


func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU)


func _launch(setup: BattleSetup, quick: bool) -> void:
	_pending_battle = setup
	_battle_owned = true
	_quick_battle = quick
	_change_scene(BATTLE)


func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file.call_deferred(path)
