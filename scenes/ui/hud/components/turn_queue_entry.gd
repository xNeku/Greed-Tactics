class_name TurnQueueEntry
extends PanelContainer
## One unit abbreviation in the turn queue, coloured by team.

const PLAYER_COLOR := Color(0.4, 0.68, 1.0)
const ENEMY_COLOR := Color(1.0, 0.4, 0.42)
const ACTIVE_COLOR := Color(1.0, 0.82, 0.3)

@onready var _label: Label = $Label


func set_unit(unit: UnitState, is_active: bool) -> void:
	_label.text = unit.get_short_name()
	tooltip_text = unit.display_name
	theme_type_variation = &"QueueEntryActive" if is_active else &"QueueEntry"
	if is_active:
		_label.modulate = ACTIVE_COLOR
	else:
		_label.modulate = PLAYER_COLOR if unit.team == UnitState.Team.PLAYER else ENEMY_COLOR
