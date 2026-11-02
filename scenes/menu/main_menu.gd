extends Control
## Title screen: new run, quick battle and the 4 playable classes.

@export var hero_card_scene: PackedScene

@onready var _classes: HBoxContainer = %Classes
@onready var _seed_edit: LineEdit = %SeedEdit
@onready var _new_run_button: Button = %NewRunButton
@onready var _quick_battle_button: Button = %QuickBattleButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	var game := _game()
	for data in game.run_config.heroes:
		var card: HeroCard = hero_card_scene.instantiate()
		card.show_description = true
		_classes.add_child(card)
		card.show_hero(data, game.run_config.start_level)
	_new_run_button.pressed.connect(_on_new_run)
	_quick_battle_button.pressed.connect(game.start_quick_battle.bind(null))
	_quit_button.pressed.connect(get_tree().quit)
	_new_run_button.grab_focus.call_deferred()


func _on_new_run() -> void:
	var text := _seed_edit.text.strip_edges()
	_game().new_run(text.hash() if not text.is_empty() else 0)


func _game() -> GameSession:
	return get_node(^"/root/Game") as GameSession
