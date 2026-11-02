class_name TurnQueueBar
extends HBoxContainer
## Upcoming turns (GDD §11). The first entry is the active unit.

@export var entry_scene: PackedScene


func show_queue(units: Array[UnitState]) -> void:
	for child in get_children():
		child.queue_free()
	for i in units.size():
		var entry: TurnQueueEntry = entry_scene.instantiate()
		add_child(entry)
		entry.set_unit(units[i], i == 0)
