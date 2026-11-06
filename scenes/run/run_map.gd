extends Control
## Run overview between nodes (v0.10): top bar (stage, zone, step, gold, run
## level), the branching map of the stage with drawn medallions, an info panel
## for the node under the mouse, the party and the protagonist's modifiers.

@export var hero_card_scene: PackedScene

@onready var _stage_label: Label = %StageLabel
@onready var _title_label: Label = %TitleLabel
@onready var _step_label: Label = %StepLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _level_label: Label = %LevelLabel
@onready var _run_xp_bar: ProgressBar = %RunXpBar
@onready var _stage_map: StageMapView = %StageMap
@onready var _hint_label: Label = %HintLabel
@onready var _node_title: Label = %NodeTitle
@onready var _node_text: Label = %NodeText
@onready var _party: GridContainer = %Party
@onready var _party_caption: Label = %PartyCaption
@onready var _modifiers_caption: Label = %ModifiersCaption
@onready var _modifiers: HFlowContainer = %Modifiers
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
	_stage_map.node_hovered.connect(_on_node_hovered)
	_heal_button.pressed.connect(_on_heal)
	_abandon_button.pressed.connect(_game.abandon_run)
	_abandon_button.tooltip_text = "La XP ganada hasta ahora cuenta para tu protagonista."
	_refresh()


func _refresh() -> void:
	var run := _game.run
	_stage_label.text = "Etapa %d/%d" % [run.stage + 1, run.config.stage_count]
	_title_label.text = run.get_zone().display_name
	_step_label.text = "Paso %d/%d" % [run.get_phase_number(), run.config.phases_per_stage]
	_gold_label.text = "Oro %d" % run.gold
	_level_label.text = "Nivel de run %d" % run.level
	_run_xp_bar.value = 100.0 * run.xp / maxf(run.get_xp_to_next_level(), 1)
	_run_xp_bar.tooltip_text = "%d / %d XP" % [run.xp, run.get_xp_to_next_level()]
	_stage_map.show_map(run)
	_hint_label.text = "Elige tu camino" if not run.get_choices().is_empty() else ""
	_build_party(run)
	_modifiers_caption.text = "Modificadores de %s" % run.get_protagonist().data.display_name
	UiKit.clear(_modifiers)
	for modifier in run.modifiers:
		_modifiers.add_child(UiKit.chip(modifier.display_name, false, modifier.description))
	if run.modifiers.is_empty():
		_modifiers.add_child(UiKit.caption("Ninguno todavía. Se ganan en combates élite, objetivos, minibosses y subiendo de nivel a tu protagonista."))
	_event_label.visible = not run.last_event.is_empty()
	_event_label.text = run.last_event
	_heal_button.text = "Curar +%d%% (%d oro)" % [run.config.heal_percent, run.config.heal_cost]
	_heal_button.disabled = not run.can_heal()


func _build_party(run: RunState) -> void:
	UiKit.clear(_party)
	_party_caption.text = "Grupo %d/%d" % [run.heroes.size(), run.config.party_size]
	for i in run.heroes.size():
		var hero := run.heroes[i]
		var card: HeroCard = hero_card_scene.instantiate()
		card.custom_minimum_size = Vector2(170, 0)
		_party.add_child(card)
		card.show_hero(hero.data, run.level, hero.hp, hero.get_max_hp(run.level))
		if i == 0:
			card.mark_protagonist()


func _on_node_hovered(node: RunMap.MapNode) -> void:
	if node == null:
		_node_title.text = "Camino"
		_node_text.text = "Pasa el ratón por una casilla del mapa."
		return
	_node_title.text = StageMapView.KIND_NAMES[node.kind]
	_node_title.add_theme_color_override(&"font_color", StageMapView.KIND_COLORS[node.kind])
	_node_text.text = StageMapView.describe(node)


func _on_heal() -> void:
	if _game.run.heal_party():
		_refresh()
