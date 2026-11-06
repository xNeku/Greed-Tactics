class_name SkillChoreography
extends Resource
## The show of a skill (SkillData.choreography): an ordered list of VfxSteps
## grouped by phase. Rage users only get it with rage (the mutated skill);
## the others get the full cinematic once per battle, then the short version.
## (Below: the original summary.)
## grouped by phase. BattleController plays CAST, then the motion, ARRIVE, the
## hits (IMPACT per landed hit) and END, then restores sky, camera and time.

@export var steps: Array[VfxStep] = []
## Skip the generic VfxPlayer cast (placeholder projectile / slash / nova).
@export var replaces_default_cast := true
## Camera follows the action (focus on user, then target) while it plays.
@export var follow_camera := true


func has_phase(phase: VfxStep.Phase) -> bool:
	return steps.any(func(s: VfxStep) -> bool: return s.phase == phase)


## Plays every step of [param phase]. IMPACT steps go to [param impact_at].
## [param short]: only the effects, without the cinematic beats.
func play(phase: VfxStep.Phase, ctx: ChoreoContext, impact_at := Vector3.INF, short := false) -> void:
	for step in steps:
		if step.phase != phase or (short and step.is_cinematic()):
			continue
		var at := impact_at if impact_at != Vector3.INF and step.anchor == VfxStep.Anchor.TARGET \
			else ctx.anchor_position(step.anchor)
		at += Vector3.UP * step.height
		if step.wait:
			await _run(step, ctx, at)
		else:
			_run(step, ctx, at)


func _run(step: VfxStep, ctx: ChoreoContext, at: Vector3) -> void:
	if step.delay > 0.0:
		await ctx.wait(step.delay)
	await step.run(ctx, at)
