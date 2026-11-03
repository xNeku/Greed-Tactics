class_name AuraData
extends Resource
## A passive area around a unit (e.g. the shaman's totem). At the start of
## each unit's turn, if it is within [member radius] cells of the source it
## receives [member ally_status] (same team) or [member enemy_status].
## The status lasts until that unit's next turn, when the aura is re-checked.

@export_range(1, 8) var radius: int = 2
@export var ally_status: StatusData
@export var enemy_status: StatusData
## Colour of the area shown on the ground.
@export var color: Color = Color(1.0, 0.55, 0.2, 0.25)
