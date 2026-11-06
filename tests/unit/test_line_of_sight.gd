extends TestCase
## Line of sight and arcing shots (v0.9): direct projectiles need a clear line,
## arcs can always fly but reach less the higher they must climb, and height
## between shooter and target changes an arc's range.


func _combat(rows: PackedStringArray, heights: PackedStringArray) -> CombatState:
	var tree := TerrainData.new()
	tree.id = &"tree"
	tree.symbol = "T"
	tree.walkable = false
	tree.sight_block = 4
	var terrains: Array[TerrainData] = [TestFixtures.grass(), TestFixtures.wall(), tree]
	var grid := BattleGrid.new(MapData.create(terrains, rows, heights))
	return CombatState.new(grid, TestFixtures.rules(), 5)


func _shot(trajectory: SkillData.Trajectory, range_max: int) -> SkillData:
	var skill := TestFixtures.skill(10, 2, range_max)
	skill.tags = [&"proyectil"]
	skill.target_rule = SkillData.TargetRule.ENEMY_UNIT
	skill.trajectory = trajectory
	skill.vertical_reach = 20
	return skill


func _pair(combat: CombatState, from: Vector2i, to: Vector2i) -> Array[UnitState]:
	var shooter := combat.add_unit(TestFixtures.unit_data("Shooter", 30), UnitState.Team.PLAYER, from)
	var foe := combat.add_unit(TestFixtures.unit_data("Foe", 1), UnitState.Team.ENEMY, to)
	return [shooter, foe]


func test_a_tall_wall_blocks_a_direct_shot() -> void:
	var combat := _combat(["ggggggg"], ["0003000"])
	var units := _pair(combat, Vector2i(0, 0), Vector2i(5, 0))
	var arrow := _shot(SkillData.Trajectory.DIRECT, 6)
	assert_not_has(combat.get_targetable_cells(units[0], arrow, units[0].cell), units[1].cell)
	assert_has(combat.get_blocked_cells(units[0], arrow, units[0].cell), units[1].cell, "the forecast knows why")


func test_a_low_step_does_not_block() -> void:
	var combat := _combat(["ggggggg"], ["0001000"])
	var units := _pair(combat, Vector2i(0, 0), Vector2i(5, 0))
	assert_has(combat.get_targetable_cells(units[0], _shot(SkillData.Trajectory.DIRECT, 6), units[0].cell), units[1].cell)


func test_trees_block_sight_but_not_from_high_ground() -> void:
	var low := _combat(["ggTgg"], ["00000"])
	var units := _pair(low, Vector2i(0, 0), Vector2i(4, 0))
	assert_false(low.has_line_of_sight(units[0].cell, units[1].cell))
	var high := _combat(["ggTgg"], ["90000"])
	assert_true(high.has_line_of_sight(Vector2i(0, 0), Vector2i(4, 0)), "shooting down over the tree")


func test_melee_and_magic_ignore_sight() -> void:
	var combat := _combat(["ggggggg"], ["0009000"])
	var units := _pair(combat, Vector2i(0, 0), Vector2i(5, 0))
	var spell := _shot(SkillData.Trajectory.NONE, 6)
	assert_has(combat.get_targetable_cells(units[0], spell, units[0].cell), units[1].cell)


func test_an_arc_always_flies_but_reaches_less_over_a_wall() -> void:
	var open := _combat(["ggggggg"], ["0000000"])
	var walled := _combat(["ggggggg"], ["0006000"])
	var bomb := _shot(SkillData.Trajectory.ARC, 5)
	var clear_range := open.get_arc_range(open.get_effective(_pair(open, Vector2i(0, 0), Vector2i(5, 0))[0], bomb), Vector2i(0, 0), Vector2i(5, 0))
	var units := _pair(walled, Vector2i(0, 0), Vector2i(4, 0))
	var effective := walled.get_effective(units[0], bomb)
	var over_wall := walled.get_arc_range(effective, Vector2i(0, 0), Vector2i(4, 0))
	assert_eq(clear_range, 5)
	assert_true(over_wall < clear_range, "climbing over the wall costs range")
	if over_wall >= 4:
		assert_has(walled.get_targetable_cells(units[0], bomb, units[0].cell), units[1].cell, "still flies if in its shorter range")
	else:
		assert_not_has(walled.get_targetable_cells(units[0], bomb, units[0].cell), units[1].cell)


func test_arcs_reach_further_downhill_and_less_uphill() -> void:
	var combat := _combat(["ggggggggg"], ["400000004"])
	var units := _pair(combat, Vector2i(0, 0), Vector2i(8, 0))
	var bomb := combat.get_effective(units[0], _shot(SkillData.Trajectory.ARC, 5))
	assert_eq(combat.get_arc_range(bomb, Vector2i(0, 0), Vector2i(4, 0)), 5 + 2, "down from 4 levels: +2")
	assert_eq(combat.get_arc_range(bomb, Vector2i(4, 0), Vector2i(8, 0)), 5 - 2, "up 4 levels: -2")


func test_a_downhill_arc_can_hit_beyond_its_base_range() -> void:
	var combat := _combat(["gggggggg"], ["40000000"])
	var units := _pair(combat, Vector2i(0, 0), Vector2i(6, 0))
	var bomb := _shot(SkillData.Trajectory.ARC, 5)
	assert_has(combat.get_targetable_cells(units[0], bomb, units[0].cell), units[1].cell)


func test_projectile_skills_default_to_direct_and_areas_to_arc() -> void:
	var arrow := EffectiveSkill.from_skill(_shot(SkillData.Trajectory.AUTO, 5), _shot(SkillData.Trajectory.AUTO, 5))
	assert_eq(arrow.get_trajectory(), SkillData.Trajectory.DIRECT)
	var rain_data := _shot(SkillData.Trajectory.AUTO, 5)
	rain_data.area_size = 1
	var rain := EffectiveSkill.from_skill(rain_data, rain_data)
	assert_eq(rain.get_trajectory(), SkillData.Trajectory.ARC)
	var sword := TestFixtures.skill()
	assert_eq(EffectiveSkill.from_skill(sword, sword).get_trajectory(), SkillData.Trajectory.NONE)
