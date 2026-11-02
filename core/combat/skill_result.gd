class_name SkillResult
extends RefCounted
## Outcome of a resolved skill, consumed by the presentation to animate it.

class Hit:
	var target: UnitState
	var side: GridRules.AttackSide
	var landed: bool = false
	var critical: bool = false
	var damage: int = 0
	var defeated: bool = false

var user: UnitState
var skill: SkillData
var target_cell: Vector2i
var affected_cells: Array[Vector2i] = []
var hits: Array[Hit] = []
