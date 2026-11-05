class_name RunConfig
extends Resource
## Structure and tuning of a run (GDD §2 and §9, v0.7):
## you start with ONE hero (the protagonist) and recruit companions on the way.
## Each of the [member stage_count] stages is a branching map of
## [member phases_per_stage] layers (RunMap) whose last layer is the miniboss.
## Enemy count and map size grow with the party.

## Default party for quick battles; heroes[0] is the default protagonist.
@export var heroes: Array[UnitData] = []
## Every hero the player can pick as protagonist or recruit.
@export var roster: Array[UnitData] = []
## Max heroes in the party (protagonist + companions).
@export_range(1, 6) var party_size: int = 4
## Zones a stage can be themed with. Each stage gets a different one when possible.
@export var zones: Array[ZoneData] = []
@export var modifier_pool: Array[ModifierData] = []

@export_group("Structure")
@export_range(1, 10) var stage_count: int = 2
@export_range(1, 10) var phases_per_stage: int = 4
@export_group("Run map")
## Nodes per layer of the stage map (the miniboss layer always has one).
@export_range(1, 4) var map_min_width: int = 2
@export_range(1, 4) var map_max_width: int = 3
@export_range(0.0, 1.0) var elite_chance: float = 0.2
## Chance of a rest node (only on the layer right before the miniboss).
@export_range(0.0, 1.0) var rest_chance: float = 0.35
## Chance that a combat node carries an optional objective (protect / escape).
@export_range(0.0, 1.0) var objective_chance: float = 0.35
## RECRUIT nodes guaranteed per stage map (on different layers).
@export_range(0, 4) var recruits_per_stage: int = 2

@export_group("Party scaling")
## Regular enemies per battle by party size (index 0 = alone); +1 per stage.
@export var enemies_by_party: PackedInt32Array = [2, 3, 4, 5]
## Regular enemies that come with the miniboss, by party size.
@export var miniboss_adds_by_party: PackedInt32Array = [0, 1, 2, 3]
## Battle map size (fraction of the zone size) by party size.
@export var map_scale_by_party: PackedFloat32Array = [0.6, 0.72, 0.86, 1.0]
@export_range(0, 4) var elite_extra_enemies: int = 1
@export_range(0, 10) var elite_extra_levels: int = 2

@export_group("Protagonist")
## The protagonist always moves and acts more than everyone else.
@export_range(0, 5) var protagonist_move_bonus: int = 1
@export_range(0, 3) var protagonist_action_bonus: int = 1

@export_group("Enemy scaling")
@export_range(1, 50) var enemy_base_level: int = 1
@export_range(0, 10) var enemy_levels_per_phase: int = 1
@export_range(0, 10) var enemy_levels_per_stage: int = 3
## Extra HP/attack/defense multiplier per stage (0.15 = +15%).
@export_range(0.0, 2.0) var enemy_scale_per_stage: float = 0.15

@export_group("Rewards")
@export_range(0, 999) var gold_per_phase: int = 8
## Extra gold for meeting a battle objective (it also gives a modifier choice).
@export_range(0, 999) var objective_gold: int = 10
## Gold given by a recruit node when the party is already full.
@export_range(0, 999) var recruit_gold_when_full: int = 20
@export_range(1, 6) var recruit_offer_size: int = 3
## HP healed (percentage of max) by a rest node.
@export_range(0, 100) var rest_heal_percent: int = 40
@export_range(0, 999) var xp_per_phase: int = 10
@export_range(1, 6) var offer_size: int = 3
@export_range(0, 99) var reroll_cost: int = 5
@export_range(0, 9) var rerolls_per_offer: int = 1

@export_group("Party")
@export_range(1, 50) var start_level: int = 1
@export_range(1, 9999) var xp_to_level_base: int = 40
@export_range(0, 9999) var xp_to_level_growth: int = 25
## HP healed (percentage of max) on level up.
@export_range(0, 100) var level_up_heal_percent: int = 25
@export_range(0, 999) var heal_cost: int = 15
@export_range(0, 100) var heal_percent: int = 50
## Fallen heroes come back with this percentage of HP after a won battle.
@export_range(1, 100) var revive_hp_percent: int = 25
