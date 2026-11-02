class_name TestFixtures
extends RefCounted
## Builders for tests: in-memory terrains, maps and units, no .tres needed.


static func grass() -> TerrainData:
	var terrain := TerrainData.new()
	terrain.id = &"grass"
	terrain.symbol = "g"
	return terrain


static func water() -> TerrainData:
	var terrain := TerrainData.new()
	terrain.id = &"water"
	terrain.symbol = "w"
	terrain.move_cost = 2
	terrain.is_liquid = true
	return terrain


static func wall() -> TerrainData:
	var terrain := TerrainData.new()
	terrain.id = &"wall"
	terrain.symbol = "#"
	terrain.walkable = false
	return terrain


## Builds a grid from rows. Heights default to 0 when [param heights] is empty.
static func grid(rows: PackedStringArray, heights: PackedStringArray = []) -> BattleGrid:
	if heights.is_empty():
		for row in rows:
			heights.append("0".repeat(row.length()))
	var terrains: Array[TerrainData] = [grass(), water(), wall()]
	return BattleGrid.new(MapData.create(terrains, rows, heights))


static func flat_grid(width: int, height: int) -> BattleGrid:
	var rows := PackedStringArray()
	for y in height:
		rows.append("g".repeat(width))
	return grid(rows)


static func rules() -> RulesConfig:
	return RulesConfig.new()


static func skill(power: int = 10, range_min: int = 1, range_max: int = 1) -> SkillData:
	var data := SkillData.new()
	data.id = &"test_skill"
	data.power = power
	data.range_min = range_min
	data.range_max = range_max
	data.tags = [&"basico", &"melee"]
	return data


static func unit_data(name: String = "Unit", speed: int = 10) -> UnitData:
	var data := UnitData.new()
	data.display_name = name
	data.speed = speed
	data.max_hp = 100
	data.attack = 10
	data.defense = 0
	data.evasion = 0
	data.crit_chance = 0
	data.skills = [skill()]
	return data
