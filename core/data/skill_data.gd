class_name SkillData
extends Resource
## Definition of a skill. Every skill belongs to one of the 4 template types
## (GDD §4) and carries tags that modifiers target (GDD §5).
##
## Rage users can have an [member empowered_variant]: a whole different skill
## used instead of this one while the unit's rage is at or above
## [member empowered_rage_threshold] ("las skills mutan con mucha ira").

enum SkillType { BASIC, LAUNCH, AREA, MOVEMENT }

## Which cells are valid targets (besides range).
enum TargetRule {
	ANY,         ## Any cell in range.
	ENEMY_UNIT,  ## A cell with an opponent on it.
	EMPTY_CELL,  ## A walkable cell with nobody on it.
	SELF,        ## Only the user's own cell (range is ignored).
}

## How the presentation shows the skill (placeholder VFX).
enum VfxStyle {
	AUTO,        ## Derived from tags/shape: melee = SLASH, projectile = PROJECTILE, ranged area = LOB, self = NOVA.
	NONE,
	SLASH,       ## Melee swing on the target.
	PROJECTILE,  ## Fast, low arc projectile.
	LOB,         ## High arc projectile that explodes on the area (fireball, arrow rain).
	NOVA,        ## Burst around the user.
}

## How the user moves as part of the skill (movement skills, GDD §4).
enum Motion {
	NONE,           ## The user stays where it is.
	TELEPORT,       ## Jumps to the target cell (must be empty), ignoring height and obstacles.
	CHARGE,         ## Rushes in a straight line and stops next to the target.
	BEHIND_TARGET,  ## Appears on the cell behind the target (must be free) and strikes its back.
}

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var skill_type: SkillType = SkillType.BASIC
## Free-form tags: basico, lanzamiento, area, movimiento, proyectil, melee, fuego...
@export var tags: Array[StringName] = []

@export_group("Cost")
@export_range(0, 9) var ap_cost: int = 1
@export_range(0, 999) var mp_cost: int = 0
@export_range(0, 100) var rage_cost: int = 0
## Turns to wait before using it again (0 = none).
@export_range(0, 9) var cooldown: int = 0

@export_group("Targeting")
@export var target_rule: TargetRule = TargetRule.ANY
## Manhattan distance range from the user to the target cell.
@export_range(0, 20) var range_min: int = 1
@export_range(0, 20) var range_max: int = 1
## Max height difference (in levels) between the user and the target cell.
@export_range(0, 35) var vertical_reach: int = 1
## Target must be on the same row or column as the user (charges, lines).
@export var requires_straight_line: bool = false

@export_group("Area")
## Shape of the affected cells, centered on the target cell.
@export var area_shape: AreaShape.Shape = AreaShape.Shape.SINGLE
@export_range(0, 10) var area_size: int = 0

@export_group("Effect")
## 0 = the skill deals no damage (pure movement/utility).
@export_range(0, 999) var power: int = 10
@export var affects_allies: bool = false
@export var motion: Motion = Motion.NONE
## Cells the hit targets are pushed away from the user.
@export_range(0, 5) var knockback: int = 0
## Extra crit chance (percentage points) for this skill.
@export_range(0, 100) var crit_bonus: int = 0

@export_group("Summon")
## UnitData placed on the target cell (must be an EMPTY_CELL skill). Using it
## again removes the previous one summoned by the same user.
## Typed as Resource to avoid a SkillData <-> UnitData script cycle.
@export var summon: Resource

@export_group("Status")
## Status applied to every target hit (optional).
@export var status: StatusData
@export_range(0, 100) var status_chance: int = 100
## 0 = the status default duration.
@export_range(0, 9) var status_duration: int = 0

@export_group("Visual")
@export var vfx_style: VfxStyle = VfxStyle.AUTO
@export var vfx_color: Color = Color(1.0, 0.9, 0.6)

@export_group("Rage mutation")
@export var empowered_variant: SkillData
@export_range(0, 100) var empowered_rage_threshold: int = 50


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


func deals_damage() -> bool:
	return power > 0
