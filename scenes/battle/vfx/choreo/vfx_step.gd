class_name VfxStep
extends Resource
## One beat of a skill choreography (SkillChoreography): sky, camera, time,
## light, particles... Subclasses implement run(). Presentation only: the rules
## never read these.

enum Phase {
	CAST,    ## Before the user moves or attacks.
	ARRIVE,  ## After the user's motion (leap, teleport), before the hits.
	IMPACT,  ## On every landed hit (anchored to that target).
	END,     ## After everything; then the scene is restored.
}

enum Anchor {
	USER,         ## The user (where it stands when the step runs).
	TARGET,       ## The aimed cell (IMPACT: the hit target).
	AREA_CENTER,  ## Centre of all affected cells.
}

@export var phase: Phase = Phase.CAST
@export var anchor: Anchor = Anchor.TARGET
## Seconds (real time) before the step starts.
@export_range(0.0, 3.0) var delay := 0.0
## Block the choreography until this step ends (otherwise it plays alongside).
@export var wait := false
## Height above the anchor's ground.
@export_range(-1.0, 6.0) var height := 0.45


## Cinematic beats (sky, camera, time, screen tint) are skipped when the
## skill plays its short version (repeated uses, see SkillChoreography).
func is_cinematic() -> bool:
	return false


## Runs the effect at [param at]. May await (wait = true makes the caller wait).
func run(_ctx: ChoreoContext, _at: Vector3) -> void:
	pass
