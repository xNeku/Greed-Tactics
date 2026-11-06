class_name UnitData
extends Resource
## Static definition of a unit (playable class, companion or enemy).
## Runtime values (current HP, rage, position...) live in UnitState, never here.
## Stats are given at level 1 and grow linearly per level (see "Growth").

## What the unit spends on skills besides PA (GDD §3, v0.3).
enum ResourceKind {
	NONE,  ## Only PA and cooldowns (archer).
	MANA,  ## Regenerates every turn (mage).
	RAGE,  ## Starts at 0, earned by hitting and being hit, boosts damage (warrior, assassin).
}

## Where the second dual weapon peeks out in the side view, from the main hand
## (behind the body: a pixel back and two up).
const OFF_HAND_SIDE_OFFSET := Vector2i(-1, -2)
const NO_HAND := Vector2i(-1, -1)

@export var id: StringName = &""
@export var display_name: String = ""
## Abbreviation shown in the turn queue. Empty = first 3 letters of the name.
@export var short_name: String = ""
@export var race: String = ""
@export var unit_class: String = ""
## Default level when spawned outside a run (tests, quick battles).
@export_range(1, 99) var level: int = 1
## Front view (3/4 towards the camera). Feet must touch the bottom edge.
## Also used as portrait. Without [member sprite_side] it must face RIGHT.
@export var sprite: Texture2D
## Optional side view facing RIGHT, used while the unit walks away from the
## camera. Feet on the bottom edge, same pixel density as [member sprite].
@export var sprite_side: Texture2D
## Optional animations. Names: <state>_<view>, state = idle / walk / attack /
## hit, view = front / side (e.g. "walk_side"). Missing ones fall back to
## the idle of that view, then to the static sprites. Frames face RIGHT and
## share one canvas with the feet on its bottom row.
## Build them with tools/build_sprite_frames.gd from a sheet + JSON.
@export var sprite_frames: SpriteFrames
## Multiplier for the sprite size (bosses are bigger).
@export_range(0.5, 3.0) var sprite_scale: float = 1.0
@export_multiline var description: String = ""

@export_group("Stats (level 1)")
@export var resource_kind: ResourceKind = ResourceKind.NONE
@export_range(1, 9999) var max_hp: int = 100
## Max mana. Only used when resource_kind is MANA.
@export_range(0, 999) var max_mp: int = 0
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

@export_group("Growth per level")
@export_range(0, 200) var hp_per_level: int = 8
@export_range(0, 50) var mp_per_level: int = 0
@export_range(0, 50) var attack_per_level: int = 2
@export_range(0, 50) var defense_per_level: int = 1

@export_group("Skills")
## Equipped skills, in display order (template: basic, launch, area, movement).
## The first BASIC one is the default attack.
@export var skills: Array[SkillData] = []

@export_group("Weapon")
## Weapon carried from the start (drawn in the hand, see WeaponData).
@export var weapon: WeaponData
## Hand pixel in [member sprite] / [member sprite_side] (y down), marked in
## the armory. (-1, -1) = no hand marked: the weapon is not drawn in that view.
@export var hand_front: Vector2i = Vector2i(-1, -1)
@export var hand_side: Vector2i = Vector2i(-1, -1)
## Other hand, for dual weapons. (-1, -1) = automatic: mirrored across the
## sprite in the front view, [member OFF_HAND_SIDE_OFFSET] in the side view.
@export var off_hand_front: Vector2i = Vector2i(-1, -1)
@export var off_hand_side: Vector2i = Vector2i(-1, -1)

@export_group("Momentum")
## Max HP (and current HP) gained per cell walked in combat (sand elementals).
@export_range(0, 50) var hp_per_cell_moved: int = 0
## Attack gained per cell walked in combat.
@export_range(0, 20) var attack_per_cell_moved: int = 0

@export_group("Structure")
## Structures (totems, barricades...) never take turns, never move and do not
## count to win or lose a combat. Enemies can still attack and destroy them.
@export var is_structure: bool = false
## Passive area effect around this unit.
@export var aura: AuraData

@export_group("AI")
## Tactical weights when the AI controls this unit. Empty = default profile.
@export var ai_profile: AiProfile

@export_group("Rewards")
@export_range(0, 999) var xp_reward: int = 10
@export_range(0, 999) var gold_reward: int = 3


## Hand pixel for the view, or [constant NO_HAND].
func get_hand(side_view: bool) -> Vector2i:
	return hand_side if side_view else hand_front


## Hand holding the second copy of a dual weapon. [param sprite_width] is the
## width of the sprite of that view.
func get_off_hand(side_view: bool, sprite_width: int) -> Vector2i:
	var manual := off_hand_side if side_view else off_hand_front
	if manual != NO_HAND:
		return manual
	var hand := get_hand(side_view)
	if hand == NO_HAND:
		return NO_HAND
	if side_view:
		return hand + OFF_HAND_SIDE_OFFSET
	return Vector2i(sprite_width - 1 - hand.x, hand.y)


func get_short_name() -> String:
	if not short_name.is_empty():
		return short_name
	return display_name.left(3).to_upper()


## Template check (GDD §4): one skill of each type. Returns missing type names.
func get_missing_skill_types() -> PackedStringArray:
	var missing := PackedStringArray()
	for type in SkillData.SkillType.values():
		if not skills.any(func(s: SkillData) -> bool: return s != null and s.skill_type == type):
			missing.append(SkillData.SkillType.keys()[type])
	return missing
