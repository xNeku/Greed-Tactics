class_name SkillResult
extends RefCounted
## Outcome of a resolved skill, consumed by the presentation to animate it
## step by step (motion, then hits in order).

enum HitSource { PRIMARY, BOUNCE, EXPLOSION }

class Hit:
	var target: UnitState
	var source: HitSource = HitSource.PRIMARY
	## Cell the damage came from (user, previous bounce target, explosion center).
	var origin_cell: Vector2i
	var side: GridRules.AttackSide
	var landed: bool = false
	var critical: bool = false
	var damage: int = 0
	var defeated: bool = false
	## Cell the target was pushed to (== its cell before the hit if not pushed).
	var pushed_from: Vector2i
	var pushed_to: Vector2i
	## HP the user recovered from this hit (lifesteal).
	var healed: int = 0

var user: UnitState
var skill: EffectiveSkill
var target_cell: Vector2i
var affected_cells: Array[Vector2i] = []
var hits: Array[Hit] = []
## Where the user was before the skill moved it (== landing if no motion).
var user_from: Vector2i
var user_to: Vector2i
var refunded_ap: int = 0


func user_moved() -> bool:
	return user_from != user_to
