class_name UnitState
extends RefCounted
## Runtime state of a unit inside one combat. Created by CombatState.
## Stats are computed once from UnitData + level (+ a scale for enemies).

enum Team { PLAYER, ENEMY }

var id: int
var data: UnitData
var team: Team
var display_name: String
var cell: Vector2i
var facing: GridDir.Dir = GridDir.Dir.SOUTH
var level: int = 1

# Computed stats
var max_hp: int
var max_mp: int
var attack: int
var defense: int
var speed: int
var move_points: int
var action_points: int
var evasion: int
var crit_chance: int

# Current values
var hp: int
var mp: int
var rage: int = 0
## PM left this turn.
var pm: int = 0
## PA left this turn.
var pa: int = 0
## Charge time accumulated towards the next turn (see TurnQueue).
var ct: int = 0
## Turns left before each skill (base SkillData) can be used again.
var cooldowns: Dictionary[SkillData, int] = {}
## Run modifiers that affect this unit's skills.
var modifiers: Array[ModifierData] = []
## How many REFUND_AP triggers happened this turn.
var refunds_this_turn: int = 0


func _init(p_id: int, p_data: UnitData, p_team: Team, p_cell: Vector2i, p_facing: GridDir.Dir,
		p_level: int = -1, stat_scale: float = 1.0) -> void:
	id = p_id
	data = p_data
	team = p_team
	display_name = p_data.display_name
	cell = p_cell
	facing = p_facing
	level = p_data.level if p_level < 1 else p_level
	_compute_stats(stat_scale)
	hp = max_hp
	mp = max_mp


func is_alive() -> bool:
	return hp > 0


func is_enemy_of(other: UnitState) -> bool:
	return team != other.team


func uses_rage() -> bool:
	return data.resource_kind == UnitData.ResourceKind.RAGE


func uses_mana() -> bool:
	return data.resource_kind == UnitData.ResourceKind.MANA


func begin_turn(rules: RulesConfig) -> void:
	pm = move_points
	pa = action_points
	refunds_this_turn = 0
	for skill in cooldowns.keys():
		cooldowns[skill] = maxi(cooldowns[skill] - 1, 0)
	if uses_mana():
		mp = mini(mp + rules.mana_regen_per_turn, max_mp)


func get_basic_skill() -> SkillData:
	for skill in data.skills:
		if skill.skill_type == SkillData.SkillType.BASIC:
			return skill
	return data.skills[0] if not data.skills.is_empty() else null


## The skill as it would be used right now (rage mutation + modifiers).
func get_effective(skill: SkillData) -> EffectiveSkill:
	return ResolutionPipeline.build(skill, rage, modifiers)


func get_cooldown(skill: SkillData) -> int:
	return cooldowns.get(skill, 0)


func can_afford(skill: EffectiveSkill) -> bool:
	return skill != null \
		and pa >= skill.ap_cost \
		and mp >= skill.mp_cost \
		and rage >= skill.rage_cost \
		and get_cooldown(skill.base) == 0


func pay_for(skill: EffectiveSkill) -> void:
	pa -= skill.ap_cost
	mp -= skill.mp_cost
	rage -= skill.rage_cost
	if skill.cooldown > 0:
		# +1 because the countdown ticks at the start of the user's next turn.
		cooldowns[skill.base] = skill.cooldown + 1


func add_rage(amount: int, rules: RulesConfig) -> void:
	if uses_rage():
		rage = clampi(rage + amount, 0, rules.rage_max)


func heal(amount: int) -> int:
	var before := hp
	hp = mini(hp + amount, max_hp)
	return hp - before


func get_short_name() -> String:
	return data.get_short_name()


func _compute_stats(stat_scale: float) -> void:
	var lv := level - 1
	max_hp = roundi((data.max_hp + data.hp_per_level * lv) * stat_scale)
	max_mp = data.max_mp + data.mp_per_level * lv
	attack = roundi((data.attack + data.attack_per_level * lv) * stat_scale)
	defense = roundi((data.defense + data.defense_per_level * lv) * stat_scale)
	speed = data.speed
	move_points = data.move_points
	action_points = data.action_points
	evasion = data.evasion
	crit_chance = data.crit_chance
