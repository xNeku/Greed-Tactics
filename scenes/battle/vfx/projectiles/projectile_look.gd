class_name ProjectileLook
extends Resource
## How a projectile looks and feels (presentation only): pixel sprite or
## magic orb, trail, light, launch and impact, hit-stop and shake. Skills pick
## one with SkillData.projectile_look, or by tag through ProjectileLibrary.

enum Body {
	SPRITE,  ## Pixel art [member sprite] pointing where it flies (arrows, bullets).
	ORB,     ## Procedural pixelated orb / comet (magic).
	WEAPON,  ## The user's own weapon sprite, spinning (thrown axes).
}

enum Launch {
	NONE,
	CHARGE,  ## Particles gather in the hand and the light swells (magic).
	MUZZLE,  ## Muzzle flash, smoke and a shell casing (firearms).
	RELEASE, ## A puff of air at the hand (bows, throws).
}

@export var body: Body = Body.SPRITE
@export var sprite: Texture2D
## World size of one pixel of the sprite or orb (units use 0.036).
@export_range(0.01, 0.1) var pixel_size := 0.036
## Spin on screen in turns per second (0 = points where it flies).
@export_range(-6.0, 6.0) var spin := 0.0
## Body brightness: > 1 glows.
@export_range(0.0, 8.0) var emission := 1.0

@export_group("Orb")
## Size of the orb head in world units.
@export_range(0.05, 1.5) var orb_size := 0.34
@export var core_color := Color(1.0, 1.0, 1.0)
@export var mid_color := Color(0.85, 0.55, 1.0)
@export var edge_color := Color(0.45, 0.2, 0.9)
## 0 = round, 1 = long flickering tail (fire).
@export_range(0.0, 1.0) var tail := 0.4

@export_group("Flight")
## World units per second.
@export_range(2.0, 120.0) var speed := 14.0
## Height of the arc for a direct shot, per unit of distance.
@export_range(0.0, 1.0) var arc_per_unit := 0.05
## Shots fired one after the other (double barrel).
@export_range(1, 6) var count := 1
@export_range(0.0, 0.5) var interval := 0.09
## Area skills: one projectile to every affected cell (arrow rain, buckshot).
@export var one_per_cell := false
@export_range(0.0, 0.3) var per_cell_stagger := 0.05

@export_group("Trail")
@export var trail_color := Color(1.0, 0.8, 0.5)
@export_range(0.0, 0.6) var trail_width := 0.12
## Seconds the trail lasts behind the body.
@export_range(0.0, 1.0) var trail_time := 0.18
@export_range(0.0, 6.0) var trail_emission := 2.0
## Sparkles shed while flying (embers, frost, motes).
@export_range(0, 200) var sparkle_amount := 0
@export var sparkle_color := Color(1.0, 0.8, 0.5)
## Gravity of the sparkles (positive y = they rise, like embers).
@export var sparkle_gravity := Vector3(0.0, -2.0, 0.0)

@export_group("Light")
@export var light_color := Color(1.0, 0.8, 0.5)
@export_range(0.0, 12.0) var light_energy := 0.0
@export_range(0.5, 8.0) var light_range := 2.5

@export_group("Launch")
@export var launch: Launch = Launch.NONE
@export_range(0.0, 1.0) var charge_time := 0.25
@export var launch_color := Color(1.0, 0.85, 0.5)

@export_group("Impact")
@export var impact_color := Color(1.0, 0.8, 0.5)
@export_range(0.2, 3.0) var impact_size := 1.0
## Square pixel sparks thrown by the hit.
@export_range(0, 120) var impact_sparks := 24
## Gravity of the impact sparks: negative falls (debris), positive rises (embers).
@export_range(-12.0, 6.0) var impact_gravity := -7.0
@export var impact_smoke := false
## The projectile stays stuck in the target for a moment (arrows, darts).
@export var sticks := false
## Freeze frames on hit (seconds, real time).
@export_range(0.0, 0.2) var hit_stop := 0.04
@export_range(0.0, 0.6) var shake := 0.12
## Chromatic aberration pulse on hit.
@export_range(0.0, 1.0) var aberration := 0.0
