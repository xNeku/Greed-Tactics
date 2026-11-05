extends Control
## Title screen: pick the protagonist (click a card), new run, quick battle.
## A run starts with that hero alone; companions are recruited on the way.

@export var hero_card_scene: PackedScene

@onready var _classes: GridContainer = %Classes
@onready var _seed_edit: LineEdit = %SeedEdit
@onready var _new_run_button: Button = %NewRunButton
@onready var _quick_battle_button: Button = %QuickBattleButton
@onready var _quit_button: Button = %QuitButton

var _cards: Dictionary[UnitData, HeroCard] = {}
var _protagonist: UnitData


func _ready() -> void:
	var game := _game()
	var config := game.run_config
	var roster := config.roster if not config.roster.is_empty() else config.heroes
	_protagonist = config.heroes[0]
	for data in roster:
		var card: HeroCard = hero_card_scene.instantiate()
		card.selectable = true
		card.tooltip_text = data.description
		_classes.add_child(card)
		card.show_hero(data, config.start_level)
		card.pressed.connect(_on_card_pressed.bind(data))
		_cards[data] = card
	_refresh_party()
	_new_run_button.pressed.connect(_on_new_run)
	_quick_battle_button.pressed.connect(func() -> void: _game().start_quick_battle())
	_quit_button.pressed.connect(get_tree().quit)
	_new_run_button.grab_focus.call_deferred()


func _on_card_pressed(data: UnitData) -> void:
	_protagonist = data
	_refresh_party()


func _refresh_party() -> void:
	for data in _cards:
		_cards[data].set_selected(data == _protagonist)
	_new_run_button.disabled = _protagonist == null
	_new_run_button.text = "Nueva run con %s" % _protagonist.display_name if _protagonist != null else "Elige un protagonista"


func _on_new_run() -> void:
	var text := _seed_edit.text.strip_edges()
	_game().new_run(text.hash() if not text.is_empty() else 0, _protagonist)


func _game() -> GameSession:
	return get_node(^"/root/Game") as GameSession
