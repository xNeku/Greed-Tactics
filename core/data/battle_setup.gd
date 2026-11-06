class_name BattleSetup
extends Resource
## Everything needed to start one combat: map and both rosters.
## Units are placed on MapData spawns in order. Authored as .tres for fixed
## battles, or built at runtime by RunState for procedural ones.

@export var title: String = "Combate"
@export var map: MapData
## Visual theme (background, light). Optional.
@export var zone: ZoneData
@export var player_units: Array[UnitData] = []
@export var enemy_units: Array[UnitData] = []
## 0 = random seed each time.
@export var rng_seed: int = 0
## Miniboss fight: the map gets a raised dais with stairs for the boss.
@export var is_boss_battle: bool = false
## Lighting mood id of the zone to use (empty = picked from the seed).
@export var lighting_mood: String = ""

@export_group("Scaling")
## -1 = use each UnitData.level.
@export var player_level: int = -1
@export var enemy_level: int = -1
## Multiplier on enemy HP / attack / defense.
@export var enemy_stat_scale: float = 1.0

## Runtime only (runs): current HP of each player unit, in roster order. <= 0 = full.
var player_hp: Array[int] = []
## Runtime only (runs): modifiers picked during the run.
var player_modifiers: Array[ModifierData] = []
## Runtime only: short label of the run phase shown in the HUD (empty outside runs).
var phase_label: String = ""
## Runtime only (runs): player_units[0] is the protagonist (its fall loses the
## battle; run modifiers only apply to it).
var has_protagonist := false
## Runtime only (runs): extra PM / PA the protagonist gets every turn.
var protagonist_move_bonus: int = 0
var protagonist_action_bonus: int = 0
## Runtime only: optional battle objective (RunMap.Objective).
var objective: int = 0
