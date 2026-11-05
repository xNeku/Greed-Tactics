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
## Active statuses and the turns they have left.
var statuses: Dictionary[StatusData, int] = {}
## Charges of stacking statuses (see StatusData.max_stacks). Missing = 1.
var status_stacks: Dictionary[StatusData, int] = {}
## Who taunted this unit (a status with [member StatusData.taunts]), or null.
var taunted_by: UnitState
## Set at the start of a turn the unit cannot play (stunned, or killed by a status).
var skip_turn: bool = false
## Uses of each skill (base SkillData) this turn, for max_uses_per_turn.
var uses_this_turn: Dictionary[SkillData, int] = {}
## Run protagonist: if it falls, the battle is lost.
var is_protagonist := false
## Who summoned this unit (totems), or null.
var summoner: UnitState


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


func is_structure() -> bool:
	return data.is_structure


## Defense after statuses.
func get_defense() -> int:
	var percent := 0
	for status in statuses:
		percent += status.defense_percent_bonus
	return maxi(roundi(defense * (1.0 + percent / 100.0)), 0)


## Extra damage taken % from active statuses (vulnerable states).
func get_damage_taken_percent() -> int:
	var total := 0
	for status in statuses:
		total += status.damage_taken_percent_bonus
	return total


## True if any active status is of [param kind] (StatusData.Kind).
func has_status_kind(kind: int) -> bool:
	return statuses.keys().any(func(s: StatusData) -> bool: return s.kind == kind)


## Extra damage % from active statuses (auras, buffs, debuffs).
func get_damage_bonus_percent() -> int:
	var total := 0
	for status in statuses:
		total += status.damage_percent_bonus
	return total


func is_enemy_of(other: UnitState) -> bool:
	return team != other.team


func uses_rage() -> bool:
	return data.resource_kind == UnitData.ResourceKind.RAGE


func uses_mana() -> bool:
	return data.resource_kind == UnitData.ResourceKind.MANA


func begin_turn(rules: RulesConfig) -> void:
	var penalty := 0
	for status in statuses:
		penalty += status.move_penalty - status.move_bonus
	pm = maxi(move_points - penalty, 0)
	uses_this_turn.clear()
	pa = action_points
	skip_turn = false
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
		and get_cooldown(skill.base) == 0 \
		and (skill.max_uses_per_turn == 0 or uses_this_turn.get(skill.base, 0) < skill.max_uses_per_turn) \
		and (skill.requires_status == null or get_stacks(skill.requires_status) >= skill.requires_stacks) \
		and (not is_silenced() or skill.skill_type == SkillData.SkillType.BASIC)


func pay_for(skill: EffectiveSkill) -> void:
	pa -= skill.ap_cost
	mp -= skill.mp_cost
	rage -= skill.rage_cost
	if skill.cooldown > 0:
		# +1 because the countdown ticks at the start of the user's next turn.
		cooldowns[skill.base] = skill.cooldown + 1
	uses_this_turn[skill.base] = uses_this_turn.get(skill.base, 0) + 1
	if skill.requires_status != null and skill.requires_stacks > 0:
		var left := get_stacks(skill.requires_status) - skill.requires_stacks
		if left <= 0:
			remove_status(skill.requires_status)
		else:
			status_stacks[skill.requires_status] = left


func add_rage(amount: int, rules: RulesConfig) -> void:
	if uses_rage():
		rage = clampi(rage + amount, 0, rules.rage_max)


func heal(amount: int) -> int:
	var before := hp
	hp = mini(hp + amount, max_hp)
	return hp - before


## Momentum (UnitData.hp_per_cell_moved / attack_per_cell_moved): walking
## [param cells] makes the unit bigger. Returns true if it grew.
func gain_momentum(cells: int) -> bool:
	var hp_gain := data.hp_per_cell_moved * cells
	var attack_gain := data.attack_per_cell_moved * cells
	if hp_gain <= 0 and attack_gain <= 0:
		return false
	max_hp += hp_gain
	hp += hp_gain
	attack += attack_gain
	return true


#region Statuses

## Refreshes the status to at least [param duration] turns. Stacking
## statuses also gain a charge; taunts remember [param source].
func add_status(status: StatusData, duration: int, source: UnitState = null) -> void:
	if status.max_stacks > 1 and statuses.has(status):
		status_stacks[status] = mini(get_stacks(status) + 1, status.max_stacks)
	statuses[status] = maxi(statuses.get(status, 0), duration)
	if status.taunts and source != null:
		taunted_by = source


func remove_status(status: StatusData) -> void:
	statuses.erase(status)
	status_stacks.erase(status)
	if status.taunts and not statuses.keys().any(func(s: StatusData) -> bool: return s.taunts):
		taunted_by = null


## Charges of [param status] (0 if not active).
func get_stacks(status: StatusData) -> int:
	if not statuses.has(status):
		return 0
	return status_stacks.get(status, 1)


## The living unit this one is forced to go for, or null.
func get_taunter() -> UnitState:
	if taunted_by != null and taunted_by.is_alive():
		return taunted_by
	return null


func has_status(status: StatusData) -> bool:
	return statuses.has(status)


func is_silenced() -> bool:
	return statuses.keys().any(func(s: StatusData) -> bool: return s.blocks_skills)


func is_stunned() -> bool:
	return statuses.keys().any(func(s: StatusData) -> bool: return s.skips_turn)


## Speed after statuses (turn order).
func get_current_speed() -> int:
	var penalty := 0
	for status in statuses:
		penalty = maxi(penalty, status.speed_percent_penalty)
	return maxi(1, roundi(speed * (1.0 - penalty / 100.0)))

#endregion


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
