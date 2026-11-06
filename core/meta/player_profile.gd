class_name PlayerProfile
extends RefCounted
## Saved account (GDD §10, v0.10): per-hero progression (XP, bosses beaten,
## equipped weapon, run stats) and global stats. Plain data: to_dict() /
## from_dict() for ProfileStore.

const VERSION := 1

class HeroRecord:
	var xp := 0
	var bosses: Array[String] = []
	var weapon: String = ""
	var runs := 0
	var wins := 0
	var best_stage := 0
	var enemies := 0
	var battles := 0
	var turns := 0

	func to_dict() -> Dictionary:
		return {"xp": xp, "bosses": bosses, "weapon": weapon, "runs": runs, "wins": wins,
			"best_stage": best_stage, "enemies": enemies, "battles": battles, "turns": turns}

	static func from_dict(d: Dictionary) -> HeroRecord:
		var r := HeroRecord.new()
		r.xp = int(d.get("xp", 0))
		for b in d.get("bosses", []):
			r.bosses.append(String(b))
		r.weapon = String(d.get("weapon", ""))
		r.runs = int(d.get("runs", 0))
		r.wins = int(d.get("wins", 0))
		r.best_stage = int(d.get("best_stage", 0))
		r.enemies = int(d.get("enemies", 0))
		r.battles = int(d.get("battles", 0))
		r.turns = int(d.get("turns", 0))
		return r

var heroes: Dictionary[String, HeroRecord] = {}
var total_runs := 0
var total_wins := 0
var total_enemies := 0
var total_bosses := 0
var total_turns := 0


func get_record(hero_id: StringName) -> HeroRecord:
	var key := String(hero_id)
	if not heroes.has(key):
		heroes[key] = HeroRecord.new()
	return heroes[key]


## Shown level (I..X), walls included.
func get_level(config: ProgressionConfig, hero_id: StringName) -> int:
	var record := get_record(hero_id)
	var level := config.level_for_xp(record.xp)
	return mini(level, 5) if config.get_wall(record.xp, record.bosses) > 0 else level


## The wall the hero is stuck at right now (5), 0 if none.
func get_wall(config: ProgressionConfig, hero_id: StringName) -> int:
	var record := get_record(hero_id)
	return config.get_wall(record.xp, record.bosses)


func is_master(config: ProgressionConfig, hero_id: StringName) -> bool:
	var record := get_record(hero_id)
	return config.is_master(record.xp, record.bosses)


## Rewards the hero has unlocked (by its shown level).
func get_unlocked(config: ProgressionConfig, hero_id: StringName) -> Array[ProgressionReward]:
	var track := config.get_track(hero_id)
	if track == null:
		return []
	return track.get_unlocked(get_level(config, hero_id))


## Equipped weapon among the unlocked ones (null = the hero's own).
func get_weapon(config: ProgressionConfig, hero_id: StringName) -> WeaponData:
	var wanted := get_record(hero_id).weapon
	for reward in get_unlocked(config, hero_id):
		if reward.kind == ProgressionReward.Kind.WEAPON and reward.weapon != null and String(reward.weapon.id) == wanted:
			return reward.weapon
	return null


## The data a run starts with: the hero with its unlocked stats and weapon.
func build_hero(config: ProgressionConfig, data: UnitData) -> UnitData:
	var hero := data.duplicate() as UnitData
	for reward in get_unlocked(config, data.id):
		if reward.kind == ProgressionReward.Kind.STATS:
			hero.max_hp += reward.max_hp
			hero.attack += reward.attack
			hero.defense += reward.defense
			hero.crit_chance += reward.crit_chance
			hero.evasion += reward.evasion
	var weapon := get_weapon(config, data.id)
	if weapon != null:
		hero.weapon = weapon
	return hero


## Modifiers the hero always starts runs with.
func get_modifiers(config: ProgressionConfig, hero_id: StringName) -> Array[ModifierData]:
	var result: Array[ModifierData] = []
	for reward in get_unlocked(config, hero_id):
		if reward.kind == ProgressionReward.Kind.MODIFIER and reward.modifier != null:
			result.append(reward.modifier)
	return result


## Books a finished run: XP for the protagonist (won or lost), bosses,
## stats. Returns what changed for the end screen.
func apply_run(config: ProgressionConfig, summary: RunSummary) -> RunReport:
	var report := RunReport.new()
	report.hero_id = summary.hero_id
	var record := get_record(summary.hero_id)
	var walls_before := get_wall(config, summary.hero_id)
	report.level_before = get_level(config, summary.hero_id)
	report.xp_before = record.xp
	var master_before := is_master(config, summary.hero_id)
	# XP.
	var from_run := roundi(summary.run_xp * config.run_xp_percent / 100.0)
	report.breakdown.append("Combates y enemigos: +%d" % from_run)
	var gained := from_run
	if summary.stages_cleared > 0:
		gained += summary.stages_cleared * config.xp_per_stage_cleared
		report.breakdown.append("Etapas superadas ×%d: +%d" % [summary.stages_cleared, summary.stages_cleared * config.xp_per_stage_cleared])
	if not summary.bosses_defeated.is_empty():
		gained += summary.bosses_defeated.size() * config.xp_per_boss
		report.breakdown.append("Jefes vencidos ×%d: +%d" % [summary.bosses_defeated.size(), summary.bosses_defeated.size() * config.xp_per_boss])
	if summary.won:
		gained += config.xp_victory_bonus
		report.breakdown.append("Run completada: +%d" % config.xp_victory_bonus)
	for boss in summary.bosses_defeated:
		if not record.bosses.has(String(boss)):
			record.bosses.append(String(boss))
	# While walled, XP fills the bar up to the next level but no further.
	var cap := config.level_xp[config.level_xp.size() - 1]
	if config.get_wall(record.xp + gained, record.bosses) > 0:
		cap = config.get_wall_cap()
	record.xp = mini(record.xp + gained, maxi(cap, record.xp))
	report.xp_gained = record.xp - report.xp_before
	report.xp_after = record.xp
	report.level_after = get_level(config, summary.hero_id)
	report.wall = get_wall(config, summary.hero_id)
	report.wall_broken = walls_before > 0 and report.wall == 0
	report.became_master = not master_before and is_master(config, summary.hero_id)
	var track := config.get_track(summary.hero_id)
	if track != null:
		for level in range(report.level_before + 1, report.level_after + 1):
			report.unlocks.append_array(track.get_rewards_at(level))
	# Stats.
	record.runs += 1
	record.wins += 1 if summary.won else 0
	record.best_stage = maxi(record.best_stage, summary.stage_reached)
	record.enemies += summary.enemies_defeated
	record.battles += summary.battles_won
	record.turns += summary.turns
	total_runs += 1
	total_wins += 1 if summary.won else 0
	total_enemies += summary.enemies_defeated
	total_bosses += summary.bosses_defeated.size()
	total_turns += summary.turns
	return report


func to_dict() -> Dictionary:
	var hero_dicts := {}
	for key in heroes:
		hero_dicts[key] = heroes[key].to_dict()
	return {"version": VERSION, "heroes": hero_dicts, "total_runs": total_runs, "total_wins": total_wins,
		"total_enemies": total_enemies, "total_bosses": total_bosses, "total_turns": total_turns}


static func from_dict(d: Dictionary) -> PlayerProfile:
	var profile := PlayerProfile.new()
	var hero_dicts: Dictionary = d.get("heroes", {})
	for key in hero_dicts:
		profile.heroes[String(key)] = HeroRecord.from_dict(hero_dicts[key])
	profile.total_runs = int(d.get("total_runs", 0))
	profile.total_wins = int(d.get("total_wins", 0))
	profile.total_enemies = int(d.get("total_enemies", 0))
	profile.total_bosses = int(d.get("total_bosses", 0))
	profile.total_turns = int(d.get("total_turns", 0))
	return profile
