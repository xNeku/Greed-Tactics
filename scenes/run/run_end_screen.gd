extends Control
## End of a run (victory or defeat) with a short summary.

@export var hero_card_scene: PackedScene

@onready var _title_label: Label = %TitleLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _party: HBoxContainer = %Party
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	var game := get_node(^"/root/Game") as GameSession
	_menu_button.pressed.connect(game.abandon_run)
	var run := game.run
	if run == null:
		game.go_to_main_menu()
		return
	var won := run.status == RunState.Status.WON
	_title_label.text = "¡Run completada!" if won else "Derrota"
	var names := run.modifiers.map(func(m: ModifierData) -> String: return m.display_name)
	_stats_label.text = "Combates ganados: %d · Nivel %d · Oro %d · Turnos jugados %d\nModificadores: %s\nSemilla: %d" % [
		run.battles_won, run.level, run.gold, run.total_turns,
		", ".join(names) if not names.is_empty() else "ninguno", run.seed_value]
	for hero in run.heroes:
		var card: HeroCard = hero_card_scene.instantiate()
		_party.add_child(card)
		card.show_hero(hero.data, run.level, hero.hp, hero.get_max_hp(run.level))
