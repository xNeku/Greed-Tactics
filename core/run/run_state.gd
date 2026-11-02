class_name RunState
extends RefCounted
## State and rules of a roguelike run. No nodes: the run screens read it and
## call its commands; CombatState runs each battle it builds.
##
## Flow:  MAP --start_battle()--> BATTLE --complete_battle()--> REWARD
##        REWARD --(choose_modifier() if offered)--> advance() --> MAP
##        ... after the last phase of the last stage: WON. All heroes down: LOST.

signal changed

enum Status { MAP, BATTLE, REWARD, WON, LOST }

## What the last battle gave (shown on the reward screen).
class Reward:
	var gold: int = 0
	var xp: int = 0
	var levels_gained: int = 0
	var offers_modifier: bool = false

var config: RunConfig
var rules: RulesConfig
var seed_value: int
var status: Status = Status.MAP

var stage: int = 0
var phase: int = 0
var zones: Array[ZoneData] = []
var heroes: Array[HeroState] = []
var level: int = 1
var xp: int = 0
var gold: int = 0
var modifiers: Array[ModifierData] = []
var offer: Array[ModifierData] = []
var rerolls_left: int = 0
var last_reward: Reward
var battles_won: int = 0
var total_turns: int = 0

var _rng := RandomNumberGenerator.new()


func _init(p_config: RunConfig, p_rules: RulesConfig, p_seed: int = 0) -> void:
	config = p_config
	rules = p_rules
	seed_value = p_seed if p_seed != 0 else randi()
	_rng.seed = seed_value
	level = config.start_level
	for data in config.heroes:
		heroes.append(HeroState.new(data, level))
	var pool := config.zones.duplicate()
	for i in config.stage_count:
		if pool.is_empty():
			pool = config.zones.duplicate()
		zones.append(pool.pop_at(_rng.randi_range(0, pool.size() - 1)))


#region Queries

func get_zone() -> ZoneData:
	return zones[stage]


## 1-based phase number inside the current stage.
func get_phase_number() -> int:
	return phase + 1


func is_miniboss_phase(phase_index: int = phase) -> bool:
	return phase_index == config.phases_per_stage - 1


func gives_modifier(phase_index: int = phase) -> bool:
	return (phase_index + 1) % config.modifier_phase_interval == 0


func get_enemy_level() -> int:
	return config.enemy_base_level + stage * config.enemy_levels_per_stage + phase * config.enemy_levels_per_phase


func get_xp_to_next_level() -> int:
	return config.xp_to_level_base + config.xp_to_level_growth * (level - 1)


func get_living_heroes() -> Array[HeroState]:
	return heroes.filter(func(h: HeroState) -> bool: return h.is_alive())


func get_title() -> String:
	return "Etapa %d/%d · %s · Fase %d/%d%s" % [
		stage + 1, config.stage_count, get_zone().display_name,
		get_phase_number(), config.phases_per_stage, " (Miniboss)" if is_miniboss_phase() else ""]

#endregion


#region Commands

## Builds the next battle (procedural map + enemies) and enters BATTLE.
func start_battle() -> BattleSetup:
	var zone := get_zone()
	var setup := BattleSetup.new()
	setup.zone = zone
	setup.title = get_title()
	setup.phase_label = get_title()
	setup.rng_seed = _rng.randi()
	var living := get_living_heroes()
	for hero in living:
		setup.player_units.append(hero.data)
		setup.player_hp.append(hero.hp)
	setup.player_level = level
	setup.player_modifiers = modifiers.duplicate()
	setup.enemy_units = _roll_enemies(zone)
	setup.enemy_level = get_enemy_level()
	setup.enemy_stat_scale = 1.0 + stage * config.enemy_scale_per_stage
	setup.map = MapGenerator.generate(zone, rules, _rng.randi(), setup.player_units.size(), setup.enemy_units.size())
	status = Status.BATTLE
	changed.emit()
	return setup


## Applies the battle outcome. [param survivors_hp] = HP of each hero that
## took part, in the same order as BattleSetup.player_units.
func complete_battle(victory: bool, survivors_hp: Array[int], enemies: Array[UnitData] = [], turns: int = 0) -> Reward:
	total_turns += turns
	var living := get_living_heroes()
	for i in mini(living.size(), survivors_hp.size()):
		living[i].hp = survivors_hp[i]
	if not victory:
		status = Status.LOST
		changed.emit()
		return null

	battles_won += 1
	for hero in heroes:
		if not hero.is_alive():
			hero.hp = maxi(1, roundi(hero.get_max_hp(level) * config.revive_hp_percent / 100.0))

	var reward := Reward.new()
	reward.offers_modifier = gives_modifier()
	reward.xp = config.xp_per_phase
	for enemy in enemies:
		reward.xp += enemy.xp_reward
		if not reward.offers_modifier:
			reward.gold += enemy.gold_reward
	if not reward.offers_modifier:
		reward.gold += config.gold_per_phase
	gold += reward.gold
	reward.levels_gained = add_xp(reward.xp)
	last_reward = reward
	if reward.offers_modifier:
		rerolls_left = config.rerolls_per_offer
		roll_offer()
	else:
		offer.clear()
	status = Status.REWARD
	changed.emit()
	return reward


## Returns levels gained.
func add_xp(amount: int) -> int:
	xp += amount
	var gained := 0
	while xp >= get_xp_to_next_level():
		xp -= get_xp_to_next_level()
		level += 1
		gained += 1
		for hero in heroes:
			if hero.is_alive():
				hero.heal_percent(config.level_up_heal_percent, level)
	return gained


func roll_offer() -> void:
	offer = ModifierOffer.roll(config.modifier_pool, modifiers, _party_tags(), config.offer_size, _rng)


func can_reroll() -> bool:
	return status == Status.REWARD and not offer.is_empty() and rerolls_left > 0 and gold >= config.reroll_cost


func reroll() -> bool:
	if not can_reroll():
		return false
	gold -= config.reroll_cost
	rerolls_left -= 1
	roll_offer()
	changed.emit()
	return true


func choose_modifier(modifier: ModifierData) -> bool:
	if not offer.has(modifier):
		return false
	modifiers.append(modifier)
	offer.clear()
	changed.emit()
	return true


func can_heal() -> bool:
	return status == Status.MAP and gold >= config.heal_cost \
		and heroes.any(func(h: HeroState) -> bool: return h.hp < h.get_max_hp(level))


func heal_party() -> bool:
	if not can_heal():
		return false
	gold -= config.heal_cost
	for hero in heroes:
		hero.heal_percent(config.heal_percent, level)
	changed.emit()
	return true


## Leaves the reward screen and moves to the next phase (or ends the run).
func advance() -> void:
	if status != Status.REWARD:
		return
	offer.clear()
	phase += 1
	if phase >= config.phases_per_stage:
		phase = 0
		stage += 1
	status = Status.WON if stage >= config.stage_count else Status.MAP
	if status == Status.WON:
		stage = config.stage_count - 1
		phase = config.phases_per_stage - 1
	changed.emit()

#endregion


func _roll_enemies(zone: ZoneData) -> Array[UnitData]:
	var enemies: Array[UnitData] = []
	var count: int
	if is_miniboss_phase() and not zone.miniboss_pool.is_empty():
		enemies.append(zone.miniboss_pool[_rng.randi_range(0, zone.miniboss_pool.size() - 1)])
		count = config.miniboss_adds
	else:
		var table := config.enemies_per_phase
		count = table[mini(phase, table.size() - 1)] + stage
	for i in count:
		enemies.append(zone.enemy_pool[_rng.randi_range(0, zone.enemy_pool.size() - 1)])
	return enemies


func _party_tags() -> Array[StringName]:
	var tags: Array[StringName] = []
	for hero in heroes:
		for skill in hero.data.skills:
			for variant in [skill, skill.empowered_variant]:
				if variant == null:
					continue
				for tag in variant.tags:
					if not tags.has(tag):
						tags.append(tag)
	return tags
