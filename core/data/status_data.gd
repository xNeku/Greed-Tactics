class_name StatusData
extends Resource
## A status effect (burn, poison, slow, stun, silence...). Behaviour is data:
## any combination of damage over time, movement/speed penalties, skipping
## turns or blocking skills. Applied by skills and modifiers (GDD §5 stage 3).
## Re-applying a status refreshes its duration (it does not stack).

## Visual family, used by the presentation to pick tint and icon.
enum Kind { BURN, POISON, SLOW, STUN, SILENCE, OTHER, KNOCKUP }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var kind: Kind = Kind.OTHER
## Turns it lasts when the skill does not say otherwise.
@export_range(1, 9) var default_duration: int = 2

@export_group("Effect per turn")
## Damage at the start of each of the unit's turns, as % of its max HP.
@export_range(0, 100) var damage_percent_per_turn: int = 0
@export_range(0, 999) var damage_flat_per_turn: int = 0

@export_group("Bonuses")
## Extra damage dealt while active (percentage).
@export_range(-90, 300) var damage_percent_bonus: int = 0
## Defense change while active (percentage, negative = more exposed).
@export_range(-100, 300) var defense_percent_bonus: int = 0
## HP recovered at the start of each turn, as % of max HP.
@export_range(0, 100) var heal_percent_per_turn: int = 0

@export_group("Restrictions")
## PM lost every turn while it lasts.
@export_range(0, 20) var move_penalty: int = 0
## % of speed lost (slower turn order).
@export_range(0, 90) var speed_percent_penalty: int = 0
## The unit loses its turns while it lasts.
@export var skips_turn: bool = false
## The unit can only use BASIC skills while it lasts.
@export var blocks_skills: bool = false

@export_group("Visual")
## Do not announce when it ends (auras refresh it every turn).
@export var silent: bool = false
@export var color: Color = Color.WHITE
@export var icon: Texture2D
