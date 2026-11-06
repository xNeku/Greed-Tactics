class_name ProgressionConfig
extends Resource
## Account progression (GDD §10, v0.10): each hero levels from I to X with
## the XP of the runs it plays as protagonist (won or lost). Levels V and X
## are walls: the hero cannot go past them until it has beaten one of the
## gate bosses. Each hero has a ProgressionTrack of unlocks.

const MAX_LEVEL := 10
const ROMAN: PackedStringArray = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

## Total XP needed to reach each level (index 0 = level I = 0 XP).
@export var level_xp: PackedInt32Array = [0, 150, 350, 650, 1000, 1450, 2000, 2650, 3400, 4300]
## Beating one of these (as protagonist) lets the hero go past level V.
@export var gate_v_bosses: Array[UnitData] = []
## ... and past level X (mastery).
@export var gate_x_bosses: Array[UnitData] = []
@export var tracks: Array[ProgressionTrack] = []

@export_group("Run XP")
## Account XP = run XP (enemies, phases) x this percent, plus the bonuses.
@export_range(0, 500) var run_xp_percent: int = 100
@export_range(0, 999) var xp_per_stage_cleared: int = 50
@export_range(0, 999) var xp_per_boss: int = 75
@export_range(0, 999) var xp_victory_bonus: int = 150


static func roman(level: int) -> String:
	return ROMAN[clampi(level, 1, MAX_LEVEL) - 1]


func get_track(hero_id: StringName) -> ProgressionTrack:
	for track in tracks:
		if track.hero != null and track.hero.id == hero_id:
			return track
	return null


## Level for [param xp] before walls (1..10).
func level_for_xp(xp: int) -> int:
	var level := 1
	for i in level_xp.size():
		if xp >= level_xp[i]:
			level = i + 1
	return mini(level, MAX_LEVEL)


## The wall (5) a hero with [param xp] stands at, unless [param bosses]
## (beaten) open it; 0 = none. At the wall the bar is full up to VI.
func get_wall(xp: int, bosses: Array) -> int:
	if xp >= get_wall_cap() and not _beaten_any(gate_v_bosses, bosses):
		return 5
	return 0


## Most XP a hero can hold while stuck at the level V wall.
func get_wall_cap() -> int:
	return level_xp[5] - 1


func is_master(xp: int, bosses: Array) -> bool:
	return level_for_xp(xp) >= MAX_LEVEL and _beaten_any(gate_x_bosses, bosses)


func gate_boss_names(gate: int) -> String:
	var list := gate_v_bosses if gate == 5 else gate_x_bosses
	return " o ".join(list.map(func(b: UnitData) -> String: return b.display_name))


func _beaten_any(gate: Array[UnitData], bosses: Array) -> bool:
	if gate.is_empty():
		return true
	return gate.any(func(b: UnitData) -> bool: return bosses.has(String(b.id)))
