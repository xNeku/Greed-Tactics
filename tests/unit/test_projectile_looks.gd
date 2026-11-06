extends TestCase
## Projectile looks (v0.8.2): every projectile skill gets a look, by its own
## projectile_look or by tag (element first), and every look can be drawn.

const LIBRARY := "res://content/vfx/projectiles/library.tres"
const SKILLS := "res://content/skills"


func _effective(skill: SkillData) -> EffectiveSkill:
	return EffectiveSkill.from_skill(skill, skill)


func _skill(tags: Array[StringName]) -> SkillData:
	var skill := SkillData.new()
	skill.tags = tags
	return skill


func _all_skills(dir: String, into: Array[SkillData]) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_all_skills(dir.path_join(sub), into)
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".tres"):
			var skill := load(dir.path_join(file)) as SkillData
			if skill != null:
				into.append(skill)


func test_element_beats_the_generic_tags() -> void:
	var library := load(LIBRARY) as ProjectileLibrary
	var fire := _skill([&"basico", &"proyectil", &"flecha", &"fuego"])
	assert_eq(library.pick(_effective(fire)), library.by_tag[&"fuego"])


func test_own_look_wins_over_tags() -> void:
	var library := load(LIBRARY) as ProjectileLibrary
	var skill := _skill([&"fuego"])
	var own := ProjectileLook.new()
	skill.projectile_look = own
	assert_eq(library.pick(_effective(skill)), own)


func test_unknown_tags_fall_back() -> void:
	var library := load(LIBRARY) as ProjectileLibrary
	assert_eq(library.pick(_effective(_skill([&"proyectil"]))), library.fallback)


func test_every_projectile_skill_has_a_drawable_look() -> void:
	var library := load(LIBRARY) as ProjectileLibrary
	var skills: Array[SkillData] = []
	_all_skills(SKILLS, skills)
	var checked := 0
	for skill in skills:
		var effective := _effective(skill)
		var style := effective.get_vfx_style()
		if style != SkillData.VfxStyle.PROJECTILE and style != SkillData.VfxStyle.LOB:
			continue
		var look := library.pick(effective)
		assert_not_null(look, "%s has a look" % skill.id)
		if look != null and look.body == ProjectileLook.Body.SPRITE:
			assert_not_null(look.sprite, "%s look has a sprite" % skill.id)
		checked += 1
	assert_true(checked > 10, "projectile skills were found")


func test_arrows_and_bullets_use_their_looks() -> void:
	var library := load(LIBRARY) as ProjectileLibrary
	var shot := load("res://content/skills/archer/shot.tres") as SkillData
	var gun := load("res://content/skills/gunner/point_blank.tres") as SkillData
	var trasgo := load("res://content/skills/enemies/trasgo_arrow.tres") as SkillData
	assert_eq(library.pick(_effective(shot)), library.by_tag[&"flecha"])
	assert_eq(library.pick(_effective(gun)), library.by_tag[&"polvora"])
	assert_eq(library.pick(_effective(trasgo)).sprite, library.by_tag[&"flecha"].sprite, "enemy arrows look like arrows")
