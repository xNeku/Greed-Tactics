extends TestCase
## Procedural maps (GDD §9): valid, deterministic, varied, big enough and
## always connected with the real movement rules.

const SEEDS := [1, 2, 3, 42, 1234, 99999]


func _layouts() -> Array:
	return ZoneData.Layout.values()


func test_maps_are_valid_and_spawns_walkable() -> void:
	for layout in _layouts():
		var zone := TestFixtures.zone(layout)
		for s in SEEDS:
			var map := MapGenerator.generate(zone, TestFixtures.rules(), s, 4, 5)
			var label := "%s seed %d" % [zone.id, s]
			assert_eq(map.validate(), PackedStringArray(), label)
			assert_eq(map.player_spawns.size(), 4, label)
			assert_eq(map.enemy_spawns.size(), 5, label)
			var grid := BattleGrid.new(map)
			var all := map.player_spawns + map.enemy_spawns
			for cell in all:
				assert_true(grid.is_walkable(cell), "%s spawn %s" % [label, cell])
			var unique := {}
			for cell in all:
				unique[cell] = true
			assert_eq(unique.size(), all.size(), label + " no shared spawns")


func test_every_spawn_can_reach_every_other() -> void:
	for layout in _layouts():
		var zone := TestFixtures.zone(layout)
		for s in SEEDS:
			var map := MapGenerator.generate(zone, TestFixtures.rules(), s, 4, 5)
			var field := Pathfinder.distance_field(BattleGrid.new(map), TestFixtures.rules(), map.player_spawns[0])
			for cell in map.player_spawns + map.enemy_spawns:
				assert_true(field.has(cell), "%s seed %d: %s unreachable" % [zone.id, s, cell])


func test_size_is_within_zone_range() -> void:
	for layout in _layouts():
		var zone := TestFixtures.zone(layout)
		for s in SEEDS:
			var size := MapGenerator.generate(zone, TestFixtures.rules(), s, 4, 4).get_size()
			assert_true(size.x >= zone.min_size.x and size.x <= zone.max_size.x, "width %d" % size.x)
			assert_true(size.y >= zone.min_size.y and size.y <= zone.max_size.y, "height %d" % size.y)


func test_same_seed_same_map_different_seed_different_map() -> void:
	var zone := TestFixtures.zone(ZoneData.Layout.FOREST)
	var a := MapGenerator.generate(zone, TestFixtures.rules(), 5, 4, 4)
	var b := MapGenerator.generate(zone, TestFixtures.rules(), 5, 4, 4)
	var c := MapGenerator.generate(zone, TestFixtures.rules(), 6, 4, 4)
	assert_eq(a.terrain_rows, b.terrain_rows)
	assert_eq(a.height_rows, b.height_rows)
	assert_true(a.terrain_rows != c.terrain_rows or a.height_rows != c.height_rows)


func test_maps_use_several_height_levels() -> void:
	for layout in _layouts():
		var zone := TestFixtures.zone(layout)
		var levels := {}
		for s in SEEDS:
			var map := MapGenerator.generate(zone, TestFixtures.rules(), s, 4, 4)
			for row in map.height_rows:
				for ch in row:
					levels[ch] = true
		assert_true(levels.size() >= 3, "%s uses %d levels" % [zone.id, levels.size()])


func test_cave_is_enclosed_by_walls() -> void:
	var zone := TestFixtures.zone(ZoneData.Layout.CAVE)
	var map := MapGenerator.generate(zone, TestFixtures.rules(), 11, 4, 4)
	var grid := BattleGrid.new(map)
	for x in grid.size.x:
		assert_false(grid.is_walkable(Vector2i(x, 0)))
		assert_false(grid.is_walkable(Vector2i(x, grid.size.y - 1)))
