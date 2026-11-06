class_name RunSummary
extends RefCounted
## What a finished run leaves for the account (RunState.make_summary()).

var hero_id: StringName = &""
var won := false
## Stage reached (1 = first) and stages fully cleared (miniboss beaten).
var stage_reached := 1
var stages_cleared := 0
var battles_won := 0
var enemies_defeated := 0
var bosses_defeated: Array[StringName] = []
var turns := 0
## XP the run earned (phases and enemies), before the account bonuses.
var run_xp := 0
var gold := 0
