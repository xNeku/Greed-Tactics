extends Control
## Run overview between nodes (v0.7): the branching map of the current stage,
## the party (protagonist first), the protagonist's modifiers, gold, level and
## what the last node did. Clicking a highlighted node plays it.

@export var hero_card_scene: PackedScene

@onready var _title_label: Label = %TitleLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _level_label: Label = %LevelLabel
@onready var _stage_map: StageMapView = %StageMap
@onready var _hint_label: Label = %HintLabel
@onready var _party: GridContainer = %Party
@onready var _party_caption: Label = %PartyCaption
@onready var _modifiers_caption: Label = %ModifiersCaption
@onready var _modifiers_label: Label = %ModifiersLabel
@onready var _event_label: Label = %EventLabel
@onready var _heal_button: Button = %HealButton
@onready var _abandon_button: Button = %AbandonButton

var _game: GameSession


func _ready() -> void:
	_game = get_node(^"/root/Game") as GameSession
	if _game.run == null:
		_game.go_to_main_menu()
		return
	_stage_map.node_chosen.connect(_game.choose_map_node)
	_heal_button.pressed.connect(_on_heal)
	_abandon_button.pressed.connect(_game.abandon_run)
	_refresh()


func _refresh() -> void:
	var run := _game.run
	_title_label.text = "Etapa %d/%d · %s" % [run.stage + 1, run.config.stage_count, run.get_zone().display_name]
	_gold_label.text = "Oro %d" % run.gold
	_level_label.text = "Nivel %d · %d/%d XP" % [run.level, run.xp, run.get_xp_to_next_level()]
	_stage_map.show_map(run)
	_hint_label.text = "Elige tu camino: haz clic en una de las casillas iluminadas." if not run.get_choices().is_empty() else ""
	_build_party(run)
	var protagonist := run.get_protagonist().data.display_name
	_modifiers_caption.text = "Modificadores de %s" % protagonist
	var names := run.modifiers.map(func(m: ModifierData) -> String: return "◆ " + m.display_name)
	_modifiers_label.text = "\n".join(names) if not names.is_empty() else "Ninguno todavía. Se ganan en combates élite, objetivos y minibosses."
	_event_label.visible = not run.last_event.is_empty()
	_event_label.text = run.last_event
	_heal_button.text = "Curar grupo +%d%% (%d oro)" % [run.config.heal_percent, run.config.heal_cost]
	_heal_button.disabled = not run.can_heal()


func _build_party(run: RunState) -> void:
	for child in _party.get_children():
		child.queue_free()
	_party_caption.text = "Grupo %d/%d" % [run.heroes.size(), run.config.party_size]
	for i in run.heroes.size():
		var hero := run.heroes[i]
		var card: HeroCard = hero_card_scene.instantiate()
		_party.add_child(card)
		card.show_hero(hero.data, run.level, hero.hp, hero.get_max_hp(run.level))
		if i == 0:
			card.mark_protagonist()


func _on_heal() -> void:
	if _game.run.heal_party():
		_refresh()
