class_name RunState
extends RefCounted
## State and rules of a roguelike run (GDD §2, v0.7). No nodes: the run screens
## read it and call its commands; CombatState runs each battle it builds.
##
## You start with ONE hero, the protagonist (if it falls the run is lost), and
## recruit companions on the way. Each stage is a branching RunMap:
##   MAP --choose_node(battle)--> start_battle() --> BATTLE --complete_battle()--> REWARD
##   REWARD --(choose_modifier() if offered)--> advance() --> (RECRUIT after a miniboss) --> MAP
##   MAP --choose_node(RECRUIT)--> RECRUIT --choose_recruit()/skip_recruit()--> MAP
##   MAP --choose_node(REST)--> MAP (healed)
## After the miniboss of the last stage: WON. Protagonist down: LOST.

signal changed

enum Status { MAP, BATTLE, REWARD, RECRUIT, WON, LOST }

## What the last battle gave (shown on the reward screen).
class Reward:
	var kind: RunMap.Kind = RunMap.Kind.COMBAT
	var gold: int = 0
	var xp: int = 0
	var levels_gained: int = 0
	var offers_modifier: bool = false
	## The battle had an optional objective / it was met.
	var objective: RunMap.Objective = RunMap.Objective.NONE
	var objective_met: bool = false

var config: RunConfig
var rules: RulesConfig
var seed_value: int
var status: Status = Status.MAP

var stage: int = 0
var zones: Array[ZoneData] = []
var maps: Array[RunMap] = []
## Last node picked on the current stage map (null = stage not started).
var current_node: RunMap.MapNode
## heroes[0] is the protagonist.
var heroes: Array[HeroState] = []
var level: int = 1
var xp: int = 0
var gold: int = 0
## Run modifiers. They only affect the protagonist.
var modifiers: Array[ModifierData] = []
var offer: Array[ModifierData] = []
var recruit_offer: Array[UnitData] = []
var rerolls_left: int = 0
var last_reward: Reward
## Text of what the last non-battle node did (rest, full party...).
var last_event: String = ""
var battles_won: int = 0
var total_turns: int = 0
## For the account (RunSummary): what the run achieved.
var enemies_defeated: int = 0
var bosses_defeated: Array[StringName] = []
var stages_cleared: int = 0
var xp_earned: int = 0

var _rng := RandomNumberGenerator.new()
var _recruit_after_reward := false


## [param party] = the heroes to start with; party[0] is the protagonist
## (empty = config.heroes[0] alone).
func _init(p_config: RunConfig, p_rules: RulesConfig, p_seed: int = 0, party: Array[UnitData] = []) -> void:
	config = p_config
	rules = p_rules
	seed_value = p_seed if p_seed != 0 else randi()
	_rng.seed = seed_value
	level = config.start_level
	var start := party if not party.is_empty() else ([config.heroes[0]] as Array[UnitData])
	for data in start:
		heroes.append(HeroState.new(data, level))
	var pool := config.zones.duplicate()
	for i in config.stage_count:
		# Zones not seen yet that may appear this early (ZoneData.min_stage).
		var allowed := pool.filter(func(z: ZoneData) -> bool: return z.min_stage <= i)
		if allowed.is_empty():
			pool = config.zones.duplicate()
			allowed = pool.filter(func(z: ZoneData) -> bool: return z.min_stage <= i)
		var zone: ZoneData = allowed[_rng.randi_range(0, allowed.size() - 1)]
		pool.erase(zone)
		zones.append(zone)
		maps.append(RunMap.generate(config.phases_per_stage, config, _rng, config.recruits_per_stage))


## What the run leaves for the account (call when it is WON or LOST).
func make_summary() -> RunSummary:
	var summary := RunSummary.new()
	summary.hero_id = get_protagonist().data.id
	summary.won = status == Status.WON
	summary.stage_reached = stage + 1
	summary.stages_cleared = stages_cleared
	summary.battles_won = battles_won
	summary.enemies_defeated = enemies_defeated
	summary.bosses_defeated = bosses_defeated.duplicate()
	summary.turns = total_turns
	summary.run_xp = xp_earned
	summary.gold = gold
	return summary


#region Queries

func get_protagonist() -> HeroState:
	return heroes[0]


func get_zone() -> ZoneData:
	return zones[stage]


func get_map() -> RunMap:
	return maps[stage]


func get_choices() -> Array[RunMap.MapNode]:
	if status != Status.MAP:
		return []
	return get_map().get_choices(current_node)


## 1-based step of the current stage (the node being played, or the next one).
func get_phase_number() -> int:
	return (current_node.layer + 1) if current_node != null else 1


func is_miniboss_phase() -> bool:
	return current_node != null and current_node.kind == RunMap.Kind.MINIBOSS


func is_party_full() -> bool:
	return heroes.size() >= config.party_size


func get_enemy_level() -> int:
	var layer := current_node.layer if current_node != null else 0
	var extra := config.elite_extra_levels if current_node != null and current_node.kind == RunMap.Kind.ELITE else 0
	return config.enemy_base_level + stage * config.enemy_levels_per_stage + layer * config.enemy_levels_per_phase + extra


func get_xp_to_next_level() -> int:
	return config.xp_to_level_base + config.xp_to_level_growth * (level - 1)


func get_living_heroes() -> Array[HeroState]:
	return heroes.filter(func(h: HeroState) -> bool: return h.is_alive())


func get_title() -> String:
	var step := "Paso %d/%d" % [get_phase_number(), config.phases_per_stage]
	if is_miniboss_phase():
		step += " (Miniboss)"
	return "Etapa %d/%d · %s · %s" % [stage + 1, config.stage_count, get_zone().display_name, step]

#endregion


#region Map

## Picks the next node. Battles then need start_battle(); recruits open the
## RECRUIT state; rests heal right away.
func choose_node(node: RunMap.MapNode) -> bool:
	if not get_choices().has(node):
		return false
	current_node = node
	node.visited = true
	last_event = ""
	match node.kind:
		RunMap.Kind.RECRUIT:
			if is_party_full():
				gold += config.recruit_gold_when_full
				last_event = "Tu grupo está completo: te dan %d de oro." % config.recruit_gold_when_full
				_after_node()
			else:
				_roll_recruits()
				status = Status.RECRUIT
		RunMap.Kind.REST:
			for hero in heroes:
				if hero.is_alive():
					hero.heal_percent(config.rest_heal_percent, level)
			last_event = "Descansáis: el grupo recupera un %d%% de vida." % config.rest_heal_percent
			_after_node()
	changed.emit()
	return true


func choose_recruit(data: UnitData) -> bool:
	if status != Status.RECRUIT or not recruit_offer.has(data) or is_party_full():
		return false
	heroes.append(HeroState.new(data, level))
	recruit_offer.clear()
	last_event = "%s se une al grupo." % data.display_name
	_after_node()
	changed.emit()
	return true


func skip_recruit() -> void:
	if status != Status.RECRUIT:
		return
	recruit_offer.clear()
	_after_node()
	changed.emit()


func _roll_recruits() -> void:
	recruit_offer.clear()
	# By id: the protagonist may be a copy with its account bonuses.
	var taken := heroes.map(func(h: HeroState) -> StringName: return h.data.id)
	var pool := config.roster.filter(func(d: UnitData) -> bool: return not taken.has(d.id))
	while recruit_offer.size() < config.recruit_offer_size and not pool.is_empty():
		recruit_offer.append(pool.pop_at(_rng.randi_range(0, pool.size() - 1)))


## The node is done: back to the map, or on to the next stage after a miniboss.
func _after_node() -> void:
	if current_node != null and current_node.kind == RunMap.Kind.MINIBOSS:
		stages_cleared += 1
		stage += 1
		current_node = null
		if stage >= config.stage_count:
			stage = config.stage_count - 1
			status = Status.WON
			return
	status = Status.MAP

#endregion


#region Battles

## Builds the battle of the current node (procedural map + enemies) and enters BATTLE.
func start_battle() -> BattleSetup:
	var zone := get_zone()
	var node := current_node
	var setup := BattleSetup.new()
	setup.zone = zone
	setup.title = get_title()
	setup.phase_label = get_title()
	setup.rng_seed = _rng.randi()
	for hero in get_living_heroes():
		setup.player_units.append(hero.data)
		setup.player_hp.append(hero.hp)
	setup.has_protagonist = true
	setup.protagonist_move_bonus = config.protagonist_move_bonus
	setup.protagonist_action_bonus = config.protagonist_action_bonus
	setup.player_level = level
	setup.player_modifiers = modifiers.duplicate()
	setup.objective = node.objective if node != null else RunMap.Objective.NONE
	setup.enemy_units = _roll_enemies(zone)
	setup.enemy_level = get_enemy_level()
	setup.enemy_stat_scale = 1.0 + stage * config.enemy_scale_per_stage
	var extra_spawn := 1 if setup.objective == RunMap.Objective.PROTECT else 0
	setup.is_boss_battle = node != null and node.kind == RunMap.Kind.MINIBOSS and not zone.miniboss_pool.is_empty()
	if node != null and node.kind == RunMap.Kind.ELITE:
		setup.elite_count = config.elite_units
	elif setup.is_boss_battle:
		setup.elite_count = config.miniboss_elite_adds
	setup.map = MapGenerator.generate(zone, rules, _rng.randi(), setup.player_units.size() + extra_spawn, setup.enemy_units.size(),
		_party_value(config.map_scale_by_party, 1.0), setup.is_boss_battle)
	status = Status.BATTLE
	changed.emit()
	return setup


## Applies the battle outcome. [param survivors_hp] = HP of each hero that
## took part, in the same order as BattleSetup.player_units.
func complete_battle(victory: bool, survivors_hp: Array[int], enemies: Array[UnitData] = [], turns: int = 0,
		objective_met := false) -> Reward:
	total_turns += turns
	var living := get_living_heroes()
	for i in mini(living.size(), survivors_hp.size()):
		# HP never goes above the hero's max between battles.
		living[i].hp = mini(survivors_hp[i], living[i].get_max_hp(level))
	if not victory or not get_protagonist().is_alive():
		status = Status.LOST
		changed.emit()
		return null

	battles_won += 1
	enemies_defeated += enemies.size()
	for enemy in enemies:
		if enemy.is_boss():
			bosses_defeated.append(enemy.id)
	for hero in heroes:
		if not hero.is_alive():
			hero.hp = maxi(1, roundi(hero.get_max_hp(level) * config.revive_hp_percent / 100.0))

	var reward := Reward.new()
	reward.kind = current_node.kind if current_node != null else RunMap.Kind.COMBAT
	reward.objective = current_node.objective if current_node != null else RunMap.Objective.NONE
	reward.objective_met = objective_met and reward.objective != RunMap.Objective.NONE
	reward.xp = config.xp_per_phase
	for enemy in enemies:
		reward.xp += enemy.xp_reward
		reward.gold += enemy.gold_reward
	reward.gold += config.gold_per_phase
	match reward.kind:
		RunMap.Kind.ELITE:
			reward.offers_modifier = true
			reward.xp = roundi(reward.xp * 1.5)
		RunMap.Kind.MINIBOSS:
			reward.offers_modifier = true
	if reward.objective_met:
		reward.offers_modifier = true
		reward.gold += config.objective_gold
	gold += reward.gold
	xp_earned += reward.xp
	reward.levels_gained = add_xp(reward.xp)
	last_reward = reward
	_recruit_after_reward = reward.kind == RunMap.Kind.MINIBOSS and not is_party_full() and stage + 1 < config.stage_count
	if reward.offers_modifier:
		rerolls_left = config.rerolls_per_offer
		roll_offer()
	else:
		offer.clear()
	status = Status.REWARD
	changed.emit()
	return reward


## Leaves the reward screen: to a recruit choice after a miniboss, else the map.
func advance() -> void:
	if status != Status.REWARD:
		return
	offer.clear()
	if _recruit_after_reward:
		_recruit_after_reward = false
		_roll_recruits()
		if not recruit_offer.is_empty():
			status = Status.RECRUIT
			changed.emit()
			return
	_after_node()
	changed.emit()


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

#endregion


#region Modifiers and gold

## Offers only modifiers that affect the protagonist's skills.
func roll_offer() -> void:
	offer = ModifierOffer.roll(config.modifier_pool, modifiers, _protagonist_tags(), config.offer_size, _rng)


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

#endregion


func _roll_enemies(zone: ZoneData) -> Array[UnitData]:
	var enemies: Array[UnitData] = []
	var count: int
	var kind := current_node.kind if current_node != null else RunMap.Kind.COMBAT
	if kind == RunMap.Kind.MINIBOSS and not zone.miniboss_pool.is_empty():
		enemies.append(zone.miniboss_pool[_rng.randi_range(0, zone.miniboss_pool.size() - 1)])
		count = int(_party_value(config.miniboss_adds_by_party, 0)) + stage
	else:
		count = int(_party_value(config.enemies_by_party, 3)) + stage
		if kind == RunMap.Kind.ELITE:
			count += config.elite_extra_enemies
	for i in count:
		enemies.append(zone.enemy_pool[_rng.randi_range(0, zone.enemy_pool.size() - 1)])
	return enemies


## Value of a per-party-size table for the current party (last value repeats).
func _party_value(table: Variant, fallback: float) -> float:
	if table.is_empty():
		return fallback
	return table[clampi(heroes.size() - 1, 0, table.size() - 1)]


func _protagonist_tags() -> Array[StringName]:
	var tags: Array[StringName] = []
	for skill in get_protagonist().data.skills:
		for variant in [skill, skill.empowered_variant]:
			if variant == null:
				continue
			for tag in variant.tags:
				if not tags.has(tag):
					tags.append(tag)
	return tags
