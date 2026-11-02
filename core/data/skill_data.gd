class_name SkillData
extends Resource
## Definition of a skill. Every skill belongs to one of the 4 template types
## (GDD §4) and carries tags that modifiers target (GDD §5).

enum SkillType { BASIC, LAUNCH, AREA, MOVEMENT }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var skill_type: SkillType = SkillType.BASIC
## Free-form tags: basico, lanzamiento, area, movimiento, proyectil, melee, fuego...
@export var tags: Array[StringName] = []

@export_group("Cost")
@export_range(0, 9) var ap_cost: int = 1
@export_range(0, 999) var mp_cost: int = 0

@export_group("Range")
## Manhattan distance range from the user to the target cell.
@export_range(0, 20) var range_min: int = 1
@export_range(0, 20) var range_max: int = 1
## Max height difference (in levels) between the user and the target cell.
@export_range(0, 35) var vertical_reach: int = 1

@export_group("Area")
## Shape of the affected cells, centered on the target cell.
@export var area_shape: AreaShape.Shape = AreaShape.Shape.SINGLE
@export_range(0, 10) var area_size: int = 0

@export_group("Effect")
@export_range(0, 999) var power: int = 10
@export var affects_allies: bool = false


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)
