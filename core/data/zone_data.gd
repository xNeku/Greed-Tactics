class_name ZoneData
extends Resource
## A biome/theme (GDD §9): terrains, generator parameters, enemies and look.
## MapGenerator reads this to build maps that make sense for the theme.

enum Layout {
	FOREST,  ## Rolling hills, a river across the map, clusters of trees, rocky outcrops.
	DESERT,  ## Dunes, tall sandstone mesas with ramps, cacti, maybe an oasis.
	CAVE,    ## Enclosed by rock walls, pillars from cellular automata, pools, stalagmites.
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var layout: Layout = Layout.FOREST

@export_group("Terrains")
## Main walkable ground.
@export var floor_terrain: TerrainData
## Secondary walkable ground (paths, dirt, darker floor).
@export var alt_floor_terrain: TerrainData
## Raised walkable ground (rocks, mesas, ledges).
@export var high_terrain: TerrainData
## Liquid (river, oasis, underground pool).
@export var liquid_terrain: TerrainData
## Ground around liquids (riverbank, oasis grass).
@export var shore_terrain: TerrainData
## Unwalkable props scattered on the map (trees, cacti, stalagmites...).
@export var obstacle_terrains: Array[TerrainData] = []
## Unwalkable tall walls (caves). Optional.
@export var wall_terrain: TerrainData

@export_group("Size and shape")
@export var min_size: Vector2i = Vector2i(18, 14)
@export var max_size: Vector2i = Vector2i(24, 18)
## Max height level of the natural terrain.
@export_range(0, 12) var max_height: int = 4
## Noise frequency of the height map (lower = broader hills).
@export_range(0.01, 0.5) var height_frequency: float = 0.08
## 0..1, share of cells that become obstacles (before connectivity fixes).
@export_range(0.0, 0.5) var obstacle_density: float = 0.1
## 0..1, how much liquid the map tends to have.
@export_range(0.0, 0.5) var liquid_amount: float = 0.08

@export_group("Look")
@export var background_color: Color = Color(0.105, 0.115, 0.17)
@export var ambient_color: Color = Color(0.85, 0.88, 1.0)
@export_range(0.0, 2.0) var ambient_energy: float = 0.5
@export var sun_color: Color = Color(1.0, 0.98, 0.94)
@export_range(0.0, 3.0) var sun_energy: float = 0.8
## Sun direction (degrees: pitch, yaw). Low pitch = long shadows.
@export var sun_rotation_degrees: Vector2 = Vector2(-50.0, -35.0)
@export var fog_color: Color = Color(0.5, 0.55, 0.7)
## 0 = no fog.
@export_range(0.0, 0.1) var fog_density: float = 0.0
## Bloom on bright and emissive things (crystals, VFX).
@export_range(0.0, 2.0) var glow_intensity: float = 0.5
## Particles floating over the map (fireflies, dust...). Sized to the map.
@export var ambient_particles: PackedScene

@export_group("Enemies")
@export var enemy_pool: Array[UnitData] = []
@export var miniboss_pool: Array[UnitData] = []


func get_all_terrains() -> Array[TerrainData]:
	var result: Array[TerrainData] = []
	for terrain in [floor_terrain, alt_floor_terrain, high_terrain, liquid_terrain, shore_terrain, wall_terrain]:
		if terrain != null and not result.has(terrain):
			result.append(terrain)
	for terrain in obstacle_terrains:
		if terrain != null and not result.has(terrain):
			result.append(terrain)
	return result
