class_name UnitData
extends Resource
## Static definition of a unit (playable character, companion or enemy).
## Runtime values (current HP, position...) live in UnitState, never here.

@export var id: StringName = &""
@export var display_name: String = ""
## Abbreviation shown in the turn queue. Empty = first 3 letters of the name.
@export var short_name: String = ""
@export var race: String = ""
@export var unit_class: String = ""
@export_range(1, 99) var level: int = 1
## Pixel art facing RIGHT. Feet must touch the bottom edge of the texture.
@export var sprite: Texture2D

@export_group("Stats")
@export_range(1, 9999) var max_hp: int = 100
@export_range(0, 999) var max_mp: int = 20
## Higher speed = acts sooner and more often (see TurnQueue).
@export_range(1, 50) var speed: int = 10
## PM per turn: cells the unit can walk.
@export_range(0, 20) var move_points: int = 4
## PA per turn: spent on skills.
@export_range(0, 10) var action_points: int = 2
@export_range(0, 999) var attack: int = 10
@export_range(0, 999) var defense: int = 0
## Percentage of attacks dodged from the front.
@export_range(0, 95) var evasion: int = 5
@export_range(0, 100) var crit_chance: int = 5

@export_group("Skills")
## Equipped skills, in display order. The first BASIC one is the default attack.
@export var skills: Array[SkillData] = []


func get_short_name() -> String:
	if not short_name.is_empty():
		return short_name
	return display_name.left(3).to_upper()
