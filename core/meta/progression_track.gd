class_name ProgressionTrack
extends Resource
## The progression line of one hero: what each level from II to X unlocks.

@export var hero: UnitData
@export var rewards: Array[ProgressionReward] = []


func get_rewards_at(level: int) -> Array[ProgressionReward]:
	return rewards.filter(func(r: ProgressionReward) -> bool: return r.level == level)


## Everything unlocked up to [param level] (included).
func get_unlocked(level: int) -> Array[ProgressionReward]:
	return rewards.filter(func(r: ProgressionReward) -> bool: return r.level <= level)
