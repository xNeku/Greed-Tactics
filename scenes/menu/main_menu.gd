extends Control
## Title screen: pick the party (click the cards), new run, quick battle.

@export var hero_card_scene: PackedScene

@onready var _classes: GridContainer = %Classes
@onready var _seed_edit: LineEdit = %SeedEdit
@onready var _new_run_button: Button = %NewRunButton
@onready var _quick_battle_button: Button = %QuickBattleButton
@onready var _quit_button: Button = %QuitButton

var _cards: Dictionary[UnitData, HeroCard] = {}
var _party: Array[UnitData] = []


func _ready() -> void:
	var game := _game()
	var config := game.run_config
	var roster := config.roster if not config.roster.is_empty() else config.heroes
	_party = config.heroes.duplicate()
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
	_quick_battle_button.pressed.connect(func() -> void: _game().start_quick_battle(null, _party))
	_quit_button.pressed.connect(get_tree().quit)
	_new_run_button.grab_focus.call_deferred()


func _on_card_pressed(data: UnitData) -> void:
	if _party.has(data):
		_party.erase(data)
	elif _party.size() < _game().run_config.party_size:
		_party.append(data)
	_refresh_party()


func _refresh_party() -> void:
	var size := _game().run_config.party_size
	for data in _cards:
		_cards[data].set_selected(_party.has(data))
	_new_run_button.disabled = _party.size() != size
	_quick_battle_button.disabled = _party.is_empty()
	_new_run_button.text = "Nueva run (grupo %d/%d)" % [_party.size(), size]


func _on_new_run() -> void:
	var text := _seed_edit.text.strip_edges()
	_game().new_run(text.hash() if not text.is_empty() else 0, _party)


func _game() -> GameSession:
	return get_node(^"/root/Game") as GameSession
