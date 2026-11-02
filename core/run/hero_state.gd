class_name HeroState
extends RefCounted
## A party member across the whole run: who it is and how much HP it keeps
## between battles. Level is shared by the party (RunState.level).

var data: UnitData
var hp: int


func _init(p_data: UnitData, level: int) -> void:
	data = p_data
	hp = get_max_hp(level)


func get_max_hp(level: int) -> int:
	return UnitState.new(0, data, UnitState.Team.PLAYER, Vector2i.ZERO, GridDir.Dir.SOUTH, level).max_hp


func is_alive() -> bool:
	return hp > 0


func heal_percent(percent: int, level: int) -> void:
	var max_hp := get_max_hp(level)
	hp = mini(hp + roundi(max_hp * percent / 100.0), max_hp)
