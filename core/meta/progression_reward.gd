class_name ProgressionReward
extends Resource
## One step of a hero's progression line (GDD §10, v0.10): reached at
## [member level], it is kept forever and applied at the start of every run
## with that hero as protagonist.

enum Kind {
	STATS,     ## Permanent stat bonus.
	MODIFIER,  ## A modifier the hero always starts runs with.
	WEAPON,    ## A weapon the hero can equip (Personajes screen).
}

@export_range(1, 10) var level: int = 2
@export var kind: Kind = Kind.STATS
@export_group("Stats")
@export_range(0, 200) var max_hp: int = 0
@export_range(0, 50) var attack: int = 0
@export_range(0, 50) var defense: int = 0
@export_range(0, 30) var crit_chance: int = 0
@export_range(0, 30) var evasion: int = 0
@export_group("Unlock")
@export var modifier: ModifierData
@export var weapon: WeaponData


## Short Spanish text for menus ("+10 PV · +2 ATQ", "Modificador: Vista de águila").
func describe() -> String:
	match kind:
		Kind.MODIFIER:
			return "Modificador: %s" % (modifier.display_name if modifier != null else "?")
		Kind.WEAPON:
			return "Arma: %s" % (weapon.display_name if weapon != null else "?")
	var parts: PackedStringArray = []
	if max_hp > 0:
		parts.append("+%d PV" % max_hp)
	if attack > 0:
		parts.append("+%d ATQ" % attack)
	if defense > 0:
		parts.append("+%d DEF" % defense)
	if crit_chance > 0:
		parts.append("+%d%% crít." % crit_chance)
	if evasion > 0:
		parts.append("+%d%% evasión" % evasion)
	return " · ".join(parts)
