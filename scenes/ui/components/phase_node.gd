class_name PhaseNode
extends PanelContainer
## One phase of a stage in the run map: icon, reward and state.

enum State { DONE, CURRENT, LOCKED }

const STATE_COLORS := {
	State.DONE: Color(0.5, 0.9, 0.6),
	State.CURRENT: Color(1.0, 0.82, 0.3),
	State.LOCKED: Color(0.55, 0.6, 0.72),
}

@onready var _title_label: Label = %TitleLabel
@onready var _reward_label: Label = %RewardLabel


func show_phase(number: int, is_boss: bool, gives_modifier: bool, state: State) -> void:
	_title_label.text = "%s Fase %d%s" % ["✔" if state == State.DONE else ("☠" if is_boss else "⚔"), number, " · Miniboss" if is_boss else ""]
	_reward_label.text = "Modificador + XP" if gives_modifier else "Oro + XP"
	_title_label.modulate = STATE_COLORS[state]
	theme_type_variation = &"QueueEntryActive" if state == State.CURRENT else &""
	modulate.a = 0.55 if state == State.LOCKED else 1.0
