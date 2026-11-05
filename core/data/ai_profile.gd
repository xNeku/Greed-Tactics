class_name AiProfile
extends Resource
## Weights of the tactical AI (BasicAI). One profile per enemy archetype:
## berserkers ignore danger, archers keep their distance, bosses focus fire.

@export_group("Choosing targets")
## Extra value for a hit that kills.
@export var kill_bonus: float = 60.0
## Extra value for hitting wounded targets (scaled by missing HP %).
@export var focus_weight: float = 30.0
## Extra value per point of the target's attack (kill the dangerous ones first).
@export var dangerous_target_weight: float = 0.5
## Value of applying a status (scaled by its chance).
@export var status_value: float = 12.0
## Extra value for hitting the opponent the unit's team hit last (swarms focus).
## Units with it also walk towards that opponent first.
@export var shared_focus_weight: float = 0.0
## Value of applying a status that allies can exploit (crit-on-poison, vulnerability...), per ally.
@export var combo_weight: float = 14.0
## Extra value for hitting opponents that heal or buff (kill the healer first).
@export var support_target_weight: float = 25.0
## Extra value for hitting the run protagonist (its fall wins the battle).
@export var protagonist_target_weight: float = 12.0
## Value per HP healed on an ally.
@export var heal_weight: float = 1.2
## How much spending mana/rage/cooldowns hurts.
@export var resource_cost_weight: float = 1.0

@export_group("Positioning")
## Penalty per point of damage the unit could take where it ends its move.
@export var threat_weight: float = 0.5
## Distance it wants to keep from opponents (1 = melee).
@export_range(1, 10) var preferred_distance: int = 1
## Penalty per cell closer than preferred_distance.
@export var too_close_weight: float = 6.0
## Penalty per cell of walking distance to the nearest opponent beyond preferred_distance.
@export var approach_weight: float = 3.0
## Value per non-structure ally next to the cell (summoners hide among their summons).
@export var ally_cover_weight: float = 0.0
## Minimum gain to bother moving without attacking.
@export var reposition_margin: float = 2.0
## Anti-stalemate: after this many unit turns in a row without anyone taking
## damage, the unit stops fearing threatened cells (fades linearly to zero).
@export_range(1, 50) var patience_turns: int = 8
