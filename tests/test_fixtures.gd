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


static func modifier(effect: ModifierData.Effect, value: int, tag: StringName = &"",
		limit: int = 1, trigger := ModifierData.Trigger.ALWAYS, id: StringName = &"") -> ModifierData:
	var m := ModifierData.new()
	m.id = id if id != &"" else StringName("mod_%d_%d" % [effect, value])
	m.effect = effect
	m.value = value
	m.limit = limit
	m.target_tag = tag
	m.trigger = trigger
	return m


static func rage_unit_data(name: String = "Berserker") -> UnitData:
	var data := unit_data(name)
	data.resource_kind = UnitData.ResourceKind.RAGE
	var strike := skill(10)
	var empowered := skill(30)
	empowered.id = &"strike_empowered"
	empowered.display_name = "Golpe brutal"
	strike.empowered_variant = empowered
	strike.empowered_rage_threshold = 50
	var spender := skill(15)
	spender.id = &"spender"
	spender.rage_cost = 30
	spender.skill_type = SkillData.SkillType.AREA
	data.skills = [strike, spender]
	return data


static func zone(layout: ZoneData.Layout) -> ZoneData:
	var z := ZoneData.new()
	z.id = StringName(ZoneData.Layout.keys()[layout].to_lower())
	z.display_name = z.id
	z.layout = layout
	var floor_t := grass()
	var alt := TerrainData.new()
	alt.symbol = "d"
	var high := TerrainData.new()
	high.symbol = "s"
	var obstacle := wall()
	obstacle.symbol = "T"
	var rock := wall()
	rock.symbol = "#"
	z.floor_terrain = floor_t
	z.alt_floor_terrain = alt
	z.high_terrain = high
	z.liquid_terrain = water()
	z.shore_terrain = floor_t
	z.obstacle_terrains = [obstacle]
	z.wall_terrain = rock if layout == ZoneData.Layout.CAVE else null
	z.max_height = 5 if layout == ZoneData.Layout.DESERT else 4
	z.obstacle_density = 0.12
	z.liquid_amount = 0.08
	return z


static func status(kind: StatusData.Kind, duration: int = 2) -> StatusData:
	var s := StatusData.new()
	s.id = StringName(StatusData.Kind.keys()[kind].to_lower())
	s.kind = kind
	s.default_duration = duration
	match kind:
		StatusData.Kind.BURN:
			s.damage_percent_per_turn = 10
		StatusData.Kind.POISON:
			s.damage_flat_per_turn = 5
		StatusData.Kind.SLOW:
			s.move_penalty = 2
			s.speed_percent_penalty = 50
		StatusData.Kind.STUN:
			s.skips_turn = true
		StatusData.Kind.SILENCE:
			s.blocks_skills = true
	return s
