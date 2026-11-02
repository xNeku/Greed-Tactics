extends Control
## After a won battle: gold/XP summary and, on modifier phases, the 1-of-3
## modifier choice with a limited reroll (GDD §5).

@export var modifier_card_scene: PackedScene

@onready var _title_label: Label = %TitleLabel
@onready var _summary_label: Label = %SummaryLabel
@onready var _offer_caption: Label = %OfferCaption
@onready var _offer: HBoxContainer = %Offer
@onready var _reroll_button: Button = %RerollButton
@onready var _continue_button: Button = %ContinueButton

var _game: GameSession


func _ready() -> void:
	_game = get_node(^"/root/Game") as GameSession
	if _game.run == null or _game.run.last_reward == null:
		_game.go_to_main_menu()
		return
	_reroll_button.pressed.connect(_on_reroll)
	_continue_button.pressed.connect(_game.continue_after_reward)
	var run := _game.run
	var reward := run.last_reward
	_title_label.text = "¡Miniboss derrotado!" if run.is_miniboss_phase() else "¡Fase superada!"
	var parts := PackedStringArray()
	if reward.gold > 0:
		parts.append("+%d oro" % reward.gold)
	parts.append("+%d XP" % reward.xp)
	if reward.levels_gained > 0:
		parts.append("¡Nivel %d!" % run.level)
	_summary_label.text = " · ".join(parts)
	_refresh_offer()


func _refresh_offer() -> void:
	var run := _game.run
	for child in _offer.get_children():
		child.queue_free()
	var pending := not run.offer.is_empty()
	_offer_caption.visible = pending
	_offer.visible = pending
	_reroll_button.visible = pending
	_reroll_button.disabled = not run.can_reroll()
	_reroll_button.text = "Cambiar opciones (%d oro · quedan %d)" % [run.config.reroll_cost, run.rerolls_left]
	_continue_button.disabled = pending
	_continue_button.text = "Continuar" if not pending else "Elige un modificador"
	for modifier in run.offer:
		var card: ModifierCard = modifier_card_scene.instantiate()
		_offer.add_child(card)
		card.show_modifier(modifier)
		card.chosen.connect(_on_chosen)


func _on_chosen(modifier: ModifierData) -> void:
	if _game.run.choose_modifier(modifier):
		_summary_label.text += " · %s obtenido" % modifier.display_name
		_refresh_offer()


func _on_reroll() -> void:
	if _game.run.reroll():
		_refresh_offer()
