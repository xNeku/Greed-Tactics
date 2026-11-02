class_name UnitState
extends RefCounted
## Runtime state of a unit inside one combat. Created by CombatState.

enum Team { PLAYER, ENEMY }

var id: int
var data: UnitData
var team: Team
var display_name: String
var cell: Vector2i
var facing: GridDir.Dir = GridDir.Dir.SOUTH

var hp: int
var mp: int
## PM left this turn.
var pm: int = 0
## PA left this turn.
var pa: int = 0
## Charge time accumulated towards the next turn (see TurnQueue).
var ct: int = 0


func _init(p_id: int, p_data: UnitData, p_team: Team, p_cell: Vector2i, p_facing: GridDir.Dir) -> void:
	id = p_id
	data = p_data
	team = p_team
	display_name = p_data.display_name
	cell = p_cell
	facing = p_facing
	hp = p_data.max_hp
	mp = p_data.max_mp


func is_alive() -> bool:
	return hp > 0


func is_enemy_of(other: UnitState) -> bool:
	return team != other.team


func begin_turn() -> void:
	pm = data.move_points
	pa = data.action_points


func get_basic_skill() -> SkillData:
	for skill in data.skills:
		if skill.skill_type == SkillData.SkillType.BASIC:
			return skill
	return data.skills[0] if not data.skills.is_empty() else null


func can_afford(skill: SkillData) -> bool:
	return skill != null and pa >= skill.ap_cost and mp >= skill.mp_cost


func get_short_name() -> String:
	return data.get_short_name()
