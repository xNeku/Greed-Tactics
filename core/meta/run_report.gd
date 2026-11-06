class_name RunReport
extends RefCounted
## What a run gave the protagonist's account (shown at the end of the run).

var hero_id: StringName = &""
var xp_gained := 0
var xp_before := 0
var xp_after := 0
var level_before := 1
var level_after := 1
## Rewards reached by the new levels.
var unlocks: Array[ProgressionReward] = []
## Level the hero is stuck at (5 or 10) until a gate boss falls, 0 = none.
var wall := 0
## The hero beat a gate boss this run and broke a wall.
var wall_broken := false
var became_master := false
## Lines explaining the XP (for the summary screen).
var breakdown: PackedStringArray = []
