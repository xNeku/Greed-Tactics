extends TestCase
## Account progression (v0.10): levels I-X from run XP (won or lost), the
## walls at V (and mastery at X) opened by gate bosses, the progression line
## unlocks, the hero a run starts with, and saving.

const TEST_PATH := "user://test_profile.json"

var config: ProgressionConfig
var gate_v: UnitData
var gate_x: UnitData


func before_each() -> void:
	config = ProgressionConfig.new()
	gate_v = TestFixtures.unit_data("GateV")
	gate_v.id = &"gate_v"
	gate_x = TestFixtures.unit_data("GateX")
	gate_x.id = &"gate_x"
	config.gate_v_bosses = [gate_v]
	config.gate_x_bosses = [gate_x]
	var track := ProgressionTrack.new()
	track.hero = TestFixtures.unit_data("Hero")
	track.hero.id = &"hero"
	var stats := ProgressionReward.new()
	stats.level = 2
	stats.max_hp = 10
	stats.attack = 3
	var mod := ProgressionReward.new()
	mod.level = 3
	mod.kind = ProgressionReward.Kind.MODIFIER
	mod.modifier = TestFixtures.modifier(ModifierData.Effect.DAMAGE_FLAT, 2)
	var weapon := ProgressionReward.new()
	weapon.level = 3
	weapon.kind = ProgressionReward.Kind.WEAPON
	weapon.weapon = WeaponData.new()
	weapon.weapon.id = &"stick"
	var late := ProgressionReward.new()
	late.level = 6
	late.attack = 9
	track.rewards = [stats, mod, weapon, late]
	config.tracks = [track]


func _summary(xp: int, won := false, bosses: Array[StringName] = []) -> RunSummary:
	var summary := RunSummary.new()
	summary.hero_id = &"hero"
	summary.run_xp = xp
	summary.won = won
	summary.bosses_defeated = bosses
	summary.enemies_defeated = 3
	summary.battles_won = 2
	return summary


func test_roman_numerals() -> void:
	assert_eq(ProgressionConfig.roman(1), "I")
	assert_eq(ProgressionConfig.roman(4), "IV")
	assert_eq(ProgressionConfig.roman(9), "IX")
	assert_eq(ProgressionConfig.roman(10), "X")


func test_a_lost_run_still_gives_xp_and_stats() -> void:
	var profile := PlayerProfile.new()
	var report := profile.apply_run(config, _summary(200))
	assert_eq(report.xp_gained, 200)
	assert_eq(report.level_before, 1)
	assert_eq(report.level_after, 2)
	assert_eq(profile.get_record(&"hero").runs, 1)
	assert_eq(profile.get_record(&"hero").wins, 0)
	assert_eq(profile.total_enemies, 3)
	assert_eq(report.unlocks.size(), 1, "level II unlock")


func test_level_v_is_a_wall_until_a_gate_boss_falls() -> void:
	var profile := PlayerProfile.new()
	var report := profile.apply_run(config, _summary(99999))
	assert_eq(report.level_after, 5)
	assert_eq(report.wall, 5)
	assert_eq(profile.get_record(&"hero").xp, config.level_xp[5] - 1, "the bar fills up to VI and waits")
	var breaking := profile.apply_run(config, _summary(10, false, [&"gate_v"]))
	assert_true(breaking.wall_broken)
	assert_true(breaking.level_after >= 6)
	assert_eq(profile.get_wall(config, &"hero"), 0)


func test_mastery_needs_the_gate_x_boss() -> void:
	var profile := PlayerProfile.new()
	profile.apply_run(config, _summary(10, false, [&"gate_v"]))
	profile.apply_run(config, _summary(99999))
	assert_eq(profile.get_level(config, &"hero"), 10)
	assert_false(profile.is_master(config, &"hero"))
	var report := profile.apply_run(config, _summary(0, true, [&"gate_x"]))
	assert_true(report.became_master)


func test_victory_and_bosses_add_bonus_xp() -> void:
	var profile := PlayerProfile.new()
	var summary := _summary(100, true, [&"gate_v"])
	summary.stages_cleared = 2
	var report := profile.apply_run(config, summary)
	assert_eq(report.xp_gained, 100 + config.xp_victory_bonus + config.xp_per_boss + 2 * config.xp_per_stage_cleared)


func test_the_run_hero_carries_its_unlocks() -> void:
	var profile := PlayerProfile.new()
	profile.apply_run(config, _summary(config.level_xp[2]))
	var base := config.tracks[0].hero
	var hero := profile.build_hero(config, base)
	assert_eq(hero.max_hp, base.max_hp + 10)
	assert_eq(hero.attack, base.attack + 3)
	assert_eq(hero.id, base.id, "same hero for the run")
	assert_eq(profile.get_modifiers(config, &"hero").size(), 1)
	assert_null(profile.get_weapon(config, &"hero"), "unlocked but not equipped")
	profile.get_record(&"hero").weapon = "stick"
	assert_eq(profile.build_hero(config, base).weapon.id, &"stick")


func test_profile_saves_and_loads() -> void:
	var profile := PlayerProfile.new()
	profile.apply_run(config, _summary(400, true, [&"gate_v"]))
	assert_true(ProfileStore.save_profile(profile, TEST_PATH))
	var loaded := ProfileStore.load_profile(TEST_PATH)
	assert_eq(loaded.get_record(&"hero").xp, profile.get_record(&"hero").xp)
	assert_eq(loaded.get_record(&"hero").bosses, ["gate_v"] as Array[String])
	assert_eq(loaded.total_wins, 1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_missing_profile_is_a_fresh_one() -> void:
	var profile := ProfileStore.load_profile("user://does_not_exist.json")
	assert_eq(profile.total_runs, 0)


func test_every_roster_hero_has_a_full_line() -> void:
	var progression := load("res://content/meta/progression.tres") as ProgressionConfig
	var run_config := load("res://content/run/default_run.tres") as RunConfig
	for hero in run_config.roster:
		var track := progression.get_track(hero.id)
		assert_not_null(track, "%s has a line" % hero.display_name)
		if track == null:
			continue
		for level in range(2, 11):
			assert_false(track.get_rewards_at(level).is_empty(), "%s has something at %s" % [hero.display_name, ProgressionConfig.roman(level)])
	assert_false(progression.gate_v_bosses.is_empty())
	assert_false(progression.gate_x_bosses.is_empty())
