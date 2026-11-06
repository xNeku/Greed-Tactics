extends Control
## Title screen (v0.10): pick the protagonist from the roster (each card shows
## its account level in Roman numerals and XP), see its progression at a
## glance on the right and start a run. Footer: characters screen, quick
## battle, global stats, quit.

@export var hero_card_scene: PackedScene

@onready var _classes: GridContainer = %Classes
@onready var _seed_edit: LineEdit = %SeedEdit
@onready var _new_run_button: Button = %NewRunButton
@onready var _characters_button: Button = %CharactersButton
@onready var _quick_battle_button: Button = %QuickBattleButton
@onready var _quit_button: Button = %QuitButton
@onready var _stats_label: Label = %StatsLabel
@onready var _big_portrait: TextureRect = %BigPortrait
@onready var _hero_name: Label = %HeroName
@onready var _hero_class: Label = %HeroClass
@onready var _roman: Label = %Roman
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _xp_label: Label = %XpLabel
@onready var _next_label: Label = %NextLabel
@onready var _wall_label: Label = %WallLabel
@onready var _unlocked: HFlowContainer = %Unlocked
@onready var _description: Label = %Description

var _cards: Dictionary[UnitData, HeroCard] = {}
var _protagonist: UnitData


func _ready() -> void:
	var game := _game()
	var config := game.run_config
	var roster := config.roster if not config.roster.is_empty() else config.heroes
	_protagonist = roster[0]
	for data in roster:
		var card: HeroCard = hero_card_scene.instantiate()
		card.selectable = true
		card.tooltip_text = data.description
		card.custom_minimum_size = Vector2(150, 0)
		_classes.add_child(card)
		card.show_hero(data, 0)
		card.show_progress(game.profile, game.progression, data.id)
		card.pressed.connect(_on_card_pressed.bind(data))
		_cards[data] = card
	_refresh()
	_new_run_button.pressed.connect(_on_new_run)
	_characters_button.pressed.connect(game.open_characters)
	_quick_battle_button.pressed.connect(func() -> void: _game().start_quick_battle())
	_quit_button.pressed.connect(get_tree().quit)
	var profile := game.profile
	_stats_label.text = "Runs %d · Victorias %d · Enemigos vencidos %d · Jefes %d" % [
		profile.total_runs, profile.total_wins, profile.total_enemies, profile.total_bosses]
	_new_run_button.grab_focus.call_deferred()


func _on_card_pressed(data: UnitData) -> void:
	_protagonist = data
	_refresh()


func _refresh() -> void:
	for data in _cards:
		_cards[data].set_selected(data == _protagonist)
	var game := _game()
	var config := game.progression
	var profile := game.profile
	var hero := _protagonist
	var level := profile.get_level(config, hero.id)
	var xp := profile.get_record(hero.id).xp
	_big_portrait.texture = hero.sprite
	_hero_name.text = hero.display_name
	_hero_class.text = "%s %s" % [hero.unit_class, hero.race]
	_roman.text = ProgressionConfig.roman(level)
	_description.text = hero.description
	var track := config.get_track(hero.id)
	if level >= ProgressionConfig.MAX_LEVEL:
		_xp_bar.value = 100.0
		_xp_label.text = "Nivel máximo"
		_next_label.text = "Maestría ★" if profile.is_master(config, hero.id) else "Para la maestría: vence a %s." % config.gate_boss_names(10)
	else:
		var from := config.level_xp[level - 1]
		var to := config.level_xp[level]
		_xp_bar.value = 100.0 * (xp - from) / maxf(to - from, 1)
		_xp_label.text = "%d / %d XP para el nivel %s" % [xp - from, to - from, ProgressionConfig.roman(level + 1)]
		var next := track.get_rewards_at(level + 1) if track != null else []
		_next_label.text = "Nivel %s: %s" % [ProgressionConfig.roman(level + 1),
			", ".join(next.map(func(r: ProgressionReward) -> String: return r.describe()))] if not next.is_empty() else ""
	var wall := profile.get_wall(config, hero.id)
	_wall_label.visible = wall > 0
	_wall_label.text = "Bloqueado en el nivel V: para seguir subiendo, vence a %s con %s." % [config.gate_boss_names(5), hero.display_name]
	UiKit.clear(_unlocked)
	var unlocked := profile.get_unlocked(config, hero.id)
	if unlocked.is_empty():
		_unlocked.add_child(UiKit.caption("Nada aún: juega una run con %s para subirlo de nivel." % hero.display_name))
	for reward in unlocked:
		_unlocked.add_child(UiKit.chip("%s · %s" % [ProgressionConfig.roman(reward.level), reward.describe()],
			reward.kind != ProgressionReward.Kind.STATS))
	_new_run_button.text = "Comenzar run con %s" % hero.display_name


func _on_new_run() -> void:
	var text := _seed_edit.text.strip_edges()
	_game().new_run(text.hash() if not text.is_empty() else 0, _protagonist)


func _game() -> GameSession:
	return get_node(^"/root/Game") as GameSession
