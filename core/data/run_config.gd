class_name RunConfig
extends Resource
## Structure and tuning of a run (GDD §2 and §9, prototype v0.3):
## [member stage_count] stages, each with [member phases_per_stage] phases.
## The last phase of every stage is a miniboss. Every
## [member modifier_phase_interval]-th phase rewards a modifier (1 of 3) + XP,
## the others reward gold + XP.

@export var heroes: Array[UnitData] = []
## Zones a stage can be themed with. Each stage gets a different one when possible.
@export var zones: Array[ZoneData] = []
@export var modifier_pool: Array[ModifierData] = []

@export_group("Structure")
@export_range(1, 10) var stage_count: int = 2
@export_range(1, 10) var phases_per_stage: int = 4
@export_range(1, 10) var modifier_phase_interval: int = 2
## Enemies per normal phase, by phase index inside the stage (last value repeats).
@export var enemies_per_phase: PackedInt32Array = [3, 4, 4]
## Regular enemies that come with each miniboss.
@export_range(0, 6) var miniboss_adds: int = 2

@export_group("Enemy scaling")
@export_range(1, 50) var enemy_base_level: int = 1
@export_range(0, 10) var enemy_levels_per_phase: int = 1
@export_range(0, 10) var enemy_levels_per_stage: int = 3
## Extra HP/attack/defense multiplier per stage (0.15 = +15%).
@export_range(0.0, 2.0) var enemy_scale_per_stage: float = 0.15

@export_group("Rewards")
@export_range(0, 999) var gold_per_phase: int = 8
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
