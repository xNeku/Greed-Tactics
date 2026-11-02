extends TestCase
## Sanity checks over the authored content in content/ (no code changes
## needed to add content, but it must follow the rules).

const RUN_CONFIG := "res://content/run/default_run.tres"


func _config() -> RunConfig:
	return load(RUN_CONFIG) as RunConfig


func test_four_playable_classes_with_the_skill_template() -> void:
	var config := _config()
	assert_eq(config.heroes.size(), 4)
	var classes := {}
	for hero in config.heroes:
		classes[hero.unit_class] = true
		assert_eq(hero.get_missing_skill_types(), PackedStringArray(), hero.display_name)
		assert_eq(hero.skills.size(), 4, hero.display_name)
	assert_eq(classes.size(), 4, "4 different classes")


func test_resources_per_class() -> void:
	var kinds := {}
	for hero in _config().heroes:
		kinds[hero.unit_class] = hero.resource_kind
	assert_eq(kinds["Guerrero"], UnitData.ResourceKind.RAGE)
	assert_eq(kinds["Asesina"], UnitData.ResourceKind.RAGE)
	assert_eq(kinds["Maga"], UnitData.ResourceKind.MANA)
	assert_eq(kinds["Arquero"], UnitData.ResourceKind.NONE)


func test_rage_classes_have_mutations_and_no_mana_costs() -> void:
	for hero in _config().heroes:
		if hero.resource_kind != UnitData.ResourceKind.RAGE:
			continue
		var mutations := 0
		for skill in hero.skills:
			assert_eq(skill.mp_cost, 0, "%s uses no mana" % skill.display_name)
			if skill.empowered_variant != null:
				mutations += 1
				assert_eq(skill.empowered_variant.skill_type, skill.skill_type, skill.display_name)
		assert_eq(mutations, 4, "%s: every skill mutates with rage" % hero.display_name)


func test_archer_uses_no_mana_nor_rage() -> void:
	for hero in _config().heroes:
		if hero.resource_kind == UnitData.ResourceKind.NONE:
			for skill in hero.skills:
				assert_eq(skill.mp_cost + skill.rage_cost, 0, skill.display_name)


func test_zones_are_complete_and_symbols_unique() -> void:
	var config := _config()
	assert_eq(config.zones.size(), 3)
	for zone in config.zones:
		assert_not_null(zone.floor_terrain, zone.display_name)
		assert_false(zone.enemy_pool.is_empty(), zone.display_name)
		assert_false(zone.miniboss_pool.is_empty(), zone.display_name)
		var symbols := {}
		for terrain in zone.get_all_terrains():
			assert_false(symbols.has(terrain.symbol), "%s: duplicated symbol %s" % [zone.display_name, terrain.symbol])
			symbols[terrain.symbol] = true


func test_modifier_ids_unique_and_incompatibilities_exist() -> void:
	var ids := {}
	for modifier in _config().modifier_pool:
		assert_false(ids.has(modifier.id), "duplicated %s" % modifier.id)
		ids[modifier.id] = true
	for modifier in _config().modifier_pool:
		for other in modifier.incompatible_with:
			assert_true(ids.has(other), "%s references unknown %s" % [modifier.id, other])


func test_every_zone_generates_valid_maps() -> void:
	var rules := load("res://content/rules/default_rules.tres") as RulesConfig
	for zone in _config().zones:
		for s in [1, 2, 3]:
			var map := MapGenerator.generate(zone, rules, s, 4, 6)
			assert_eq(map.validate(), PackedStringArray(), "%s seed %d" % [zone.display_name, s])
