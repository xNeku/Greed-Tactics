extends Control
## A hero offers to join the party (v0.7): pick one of the offered heroes
## (they come at the party level, full HP) or keep going without them.

@export var hero_card_scene: PackedScene

@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _offer: HBoxContainer = %Offer
@onready var _skip_button: Button = %SkipButton

var _game: GameSession


func _ready() -> void:
	_game = get_node(^"/root/Game") as GameSession
	var run := _game.run
	if run == null or run.status != RunState.Status.RECRUIT:
		_game.go_to_main_menu()
		return
	_title_label.text = "Alguien quiere unirse a %s" % run.get_protagonist().data.display_name
	_subtitle_label.text = "Elige un compañero (grupo %d/%d). Llega a nivel %d con la vida llena y sus mejoras de cuenta; lo controlas tú." % [
		run.heroes.size(), run.config.party_size, run.level]
	for data in run.recruit_offer:
		var card: HeroCard = hero_card_scene.instantiate()
		card.show_description = true
		card.selectable = true
		card.custom_minimum_size = Vector2(300, 0)
		_offer.add_child(card)
		card.show_hero(data, run.level)
		card.show_progress(_game.profile, _game.progression, data.id)
		card.pressed.connect(_game.recruit.bind(data))
	_skip_button.pressed.connect(_game.skip_recruit)
