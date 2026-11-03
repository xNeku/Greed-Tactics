class_name StatusEvent
extends RefCounted
## Something a status did at the start of a turn (damage, expiry, lost turn).

var unit: UnitState
var status: StatusData
var damage: int = 0
## Charges the status had when it ticked.
var stacks: int = 1
var healed: int = 0
var expired: bool = false
var skipped_turn: bool = false
