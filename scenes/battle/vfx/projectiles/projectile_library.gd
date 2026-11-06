class_name ProjectileLibrary
extends Resource
## Picks the ProjectileLook of a skill that does not set its own: the first
## tag of the skill found in [member by_tag] (in the skill's tag order, but
## [member priority] tags first), else [member fallback].

@export var by_tag: Dictionary[StringName, ProjectileLook] = {}
## Tags checked before the rest (element beats "proyectil").
@export var priority: Array[StringName] = []
@export var fallback: ProjectileLook


func pick(skill: EffectiveSkill) -> ProjectileLook:
	for own in [skill.source, skill.base]:
		if own != null and own.projectile_look is ProjectileLook:
			return own.projectile_look
	for tag in priority:
		if skill.tags.has(tag) and by_tag.has(tag):
			return by_tag[tag]
	for tag in skill.tags:
		if by_tag.has(tag):
			return by_tag[tag]
	return fallback
