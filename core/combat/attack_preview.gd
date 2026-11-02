class_name AttackPreview
extends RefCounted
## Predicted outcome of a skill on one target. What the HUD shows is exactly
## what the resolution uses (GDD §3: "lo que ves es lo que pasa").

var target: UnitState
var side: GridRules.AttackSide = GridRules.AttackSide.FRONT
## Damage on a normal (non-critical) hit.
var damage: int = 0
var crit_damage: int = 0
## 0-100
var hit_chance: int = 100
## 0-100
var crit_chance: int = 0


func get_side_name() -> String:
	match side:
		GridRules.AttackSide.BACK:
			return "Espalda"
		GridRules.AttackSide.SIDE:
			return "Flanco"
		_:
			return "Frente"
