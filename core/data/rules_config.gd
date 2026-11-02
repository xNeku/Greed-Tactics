class_name RulesConfig
extends Resource
## Global tunable rules. One instance lives in content/rules/default_rules.tres.

@export_group("Movement")
## Max height difference (levels) a unit can climb or drop in a single step.
@export_range(0, 10) var max_climb: int = 1
## Extra PM per level climbed.
@export_range(0, 5) var climb_up_cost: int = 1
## Extra PM per level dropped.
@export_range(0, 5) var climb_down_cost: int = 0

@export_group("Turns")
## Charge time a unit needs to act. Every tick adds its speed.
@export_range(10, 1000) var ct_threshold: int = 100

@export_group("Orientation")
@export var side_damage_multiplier: float = 1.1
@export var back_damage_multiplier: float = 1.25
## Fraction of the target's evasion that applies when hit from each side.
@export_range(0.0, 1.0) var side_evasion_factor: float = 0.5
@export_range(0.0, 1.0) var back_evasion_factor: float = 0.0
## Flat crit chance (percentage points) added to back attacks.
@export_range(0, 100) var back_crit_bonus: int = 15

@export_group("Damage")
@export var crit_multiplier: float = 1.5
@export_range(0, 100) var min_hit_chance: int = 5
@export_range(0, 100) var max_hit_chance: int = 100
@export_range(0, 100) var min_damage: int = 1
