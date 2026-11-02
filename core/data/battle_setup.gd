class_name BattleSetup
extends Resource
## Everything needed to start one combat: map and both rosters.
## Units are placed on MapData spawns in order.

@export var title: String = "Combate"
@export var map: MapData
@export var player_units: Array[UnitData] = []
@export var enemy_units: Array[UnitData] = []
## 0 = random seed each time.
@export var rng_seed: int = 0
