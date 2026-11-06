class_name LightingMood
extends Resource
## Time of day / light of a battle (presentation only, GDD §11 v0.9): the
## backdrop behind the diorama, the sun or moon, ambient, fog and volumetric
## light shafts, bloom and colour grade. A zone lists the moods it can roll.

@export var id: StringName = &""
@export var display_name: String = ""
## Indoors: no sky backdrop, only darkness and the lights of the place.
@export var indoor: bool = false

@export_group("Backdrop")
## Screen-space gradient behind the map (top -> middle -> bottom of the screen).
@export var sky_top := Color(0.08, 0.1, 0.22)
@export var sky_middle := Color(0.2, 0.25, 0.45)
@export var sky_bottom := Color(0.45, 0.4, 0.55)
## 0..1 density of twinkling stars.
@export_range(0.0, 1.0) var stars := 0.0
## Disc in the backdrop: the moon (cool, cratered) or the sun (hot).
@export var disc := false
@export var disc_is_sun := false
@export var disc_color := Color(0.95, 0.97, 1.0)
## Position on screen (0..1) and radius (share of the screen height).
@export var disc_position := Vector2(0.8, 0.18)
@export_range(0.0, 0.3) var disc_size := 0.07
@export var halo_color := Color(0.6, 0.7, 1.0, 0.35)
## 0..1 streaks of cloud across the backdrop.
@export_range(0.0, 1.0) var clouds := 0.0
@export var cloud_color := Color(0.9, 0.6, 0.5)

@export_group("Key light")
@export var light_color := Color(1.0, 0.97, 0.9)
@export_range(0.0, 4.0) var light_energy := 1.0
## Pitch (negative = from above) and yaw of the sun / moon, degrees.
@export var light_rotation := Vector2(-48.0, -35.0)
## Degrees per second the sun turns around the map (a slow day).
@export_range(-5.0, 5.0) var light_spin := 0.0
@export_range(0.0, 1.0) var shadow_opacity := 0.8
## Strength of this light in the volumetric fog (god rays).
@export_range(0.0, 16.0) var light_volumetric := 1.0

@export_group("Ambient")
@export var ambient_color := Color(0.6, 0.65, 0.85)
@export_range(0.0, 2.0) var ambient_energy := 0.45

@export_group("Atmosphere")
@export var fog_color := Color(0.4, 0.45, 0.6)
## Distance fog (0 = none).
@export_range(0.0, 0.1) var fog_density := 0.0
## Volumetric fog density (0 = off): makes light shafts visible.
@export_range(0.0, 0.2) var volumetric_density := 0.0
@export var volumetric_albedo := Color(0.8, 0.85, 1.0)
@export_range(0.0, 3.0) var glow := 0.5
@export_range(0.0, 3.0) var exposure := 1.0
@export_range(0.5, 1.5) var contrast := 1.05
@export_range(0.0, 2.0) var saturation := 1.05
## Strength of the lights of the place (torches, braziers, lamps): x1 by day.
@export_range(0.0, 3.0) var props_light := 1.0
