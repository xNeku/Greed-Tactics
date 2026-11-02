extends Control
## Run overview between battles: stages and phases, party, gold, level,
## modifiers owned, heal and fight buttons.

@export var hero_card_scene: PackedScene
@export var phase_node_scene: PackedScene

@onready var _title_label: Label = %TitleLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _level_label: Label = %LevelLabel
@onready var _stages: VBoxContainer = %Stages
@onready var _party: HBoxContainer = %Party
@onready var _modifiers_label: Label = %ModifiersLabel
@onready var _fight_button: Button = %FightButton
@onready var _heal_button: Button = %HealButton
@onready var _abandon_button: Button = %AbandonButton

var _game: GameSession


func _ready() -> void:
	_game = get_node(^"/root/Game") as GameSession
	if _game.run == null:
		_game.go_to_main_menu()
		return
	_fight_button.pressed.connect(_game.start_run_battle)
	_heal_button.pressed.connect(_on_heal)
	_abandon_button.pressed.connect(_game.abandon_run)
	_refresh()


func _refresh() -> void:
	var run := _game.run
	_title_label.text = run.get_title()
	_gold_label.text = "Oro: %d" % run.gold
	_level_label.text = "Nivel %d  (%d/%d XP)" % [run.level, run.xp, run.get_xp_to_next_level()]
	_build_stages(run)
	_build_party(run)
	var names := run.modifiers.map(func(m: ModifierData) -> String: return m.display_name)
	_modifiers_label.text = "Modificadores: " + (", ".join(names) if not names.is_empty() else "ninguno todavía")
	_fight_button.text = "Combatir · Fase %d%s" % [run.get_phase_number(), " (Miniboss)" if run.is_miniboss_phase() else ""]
	_heal_button.text = "Curar grupo +%d%% (%d oro)" % [run.config.heal_percent, run.config.heal_cost]
	_heal_button.disabled = not run.can_heal()


func _build_stages(run: RunState) -> void:
	for child in _stages.get_children():
		child.queue_free()
	for stage in run.config.stage_count:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 10)
		_stages.add_child(row)
		var caption := Label.new()
		caption.custom_minimum_size.x = 220
		caption.theme_type_variation = &"HeaderLabel"
		caption.text = "Etapa %d · %s" % [stage + 1, run.zones[stage].display_name]
		row.add_child(caption)
		for phase in run.config.phases_per_stage:
			var node: PhaseNode = phase_node_scene.instantiate()
			row.add_child(node)
			var state := PhaseNode.State.LOCKED
			if stage < run.stage or (stage == run.stage and phase < run.phase):
				state = PhaseNode.State.DONE
			elif stage == run.stage and phase == run.phase:
				state = PhaseNode.State.CURRENT
			node.show_phase(phase + 1, run.is_miniboss_phase(phase), run.gives_modifier(phase), state)


func _build_party(run: RunState) -> void:
	for child in _party.get_children():
		child.queue_free()
	for hero in run.heroes:
		var card: HeroCard = hero_card_scene.instantiate()
		_party.add_child(card)
		card.show_hero(hero.data, run.level, hero.hp, hero.get_max_hp(run.level))


func _on_heal() -> void:
	if _game.run.heal_party():
		_refresh()
