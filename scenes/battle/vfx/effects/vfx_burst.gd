class_name VfxBurst
extends Node3D
## Square "pixel" particles configured from a ParticlesStep: bursts, rains over
## an area, or sparks converging to a point. Frees itself when done.

@onready var _particles: GPUParticles3D = $Particles


func play(cfg: ParticlesStep, extents: Vector3) -> void:
	var material := ParticleProcessMaterial.new()
	match cfg.shape:
		ParticlesStep.Shape.POINT:
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
		ParticlesStep.Shape.SPHERE:
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			material.emission_sphere_radius = cfg.radius
		ParticlesStep.Shape.AREA_RAIN:
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			material.emission_box_extents = Vector3(extents.x, 0.2, extents.z)
		ParticlesStep.Shape.CONVERGE:
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
			material.emission_sphere_radius = cfg.radius
			material.radial_accel_min = -cfg.speed * 5.0
			material.radial_accel_max = -cfg.speed * 3.0
	material.direction = cfg.direction.normalized() if cfg.direction != Vector3.ZERO else Vector3.UP
	material.spread = cfg.spread
	material.initial_velocity_min = cfg.speed * (0.0 if cfg.shape == ParticlesStep.Shape.CONVERGE else 0.55)
	material.initial_velocity_max = cfg.speed * (0.0 if cfg.shape == ParticlesStep.Shape.CONVERGE else 1.0)
	material.gravity = cfg.gravity
	material.scale_min = 0.6
	material.scale_max = 1.3
	material.damping_min = 0.5
	material.damping_max = 2.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(cfg.color_start.r * cfg.brightness, cfg.color_start.g * cfg.brightness, cfg.color_start.b * cfg.brightness, cfg.color_start.a))
	ramp.set_color(1, cfg.color_end)
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = ramp
	material.color_ramp = ramp_texture
	_particles.process_material = material

	var quad := QuadMesh.new()
	quad.size = Vector2(cfg.size, cfg.size)
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.vertex_color_use_as_albedo = true
	look.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if cfg.additive else BaseMaterial3D.BLEND_MODE_MIX
	look.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	quad.material = look
	_particles.draw_pass_1 = quad

	_particles.amount = cfg.amount
	_particles.lifetime = cfg.lifetime
	_particles.one_shot = cfg.emit_time <= 0.0
	_particles.explosiveness = 0.95 if cfg.emit_time <= 0.0 else 0.0
	_particles.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))
	_particles.emitting = true
	var tween := create_tween()
	if cfg.emit_time > 0.0:
		tween.tween_interval(cfg.emit_time)
		tween.tween_callback(func() -> void: _particles.emitting = false)
	tween.tween_interval(cfg.lifetime + 0.3)
	tween.tween_callback(queue_free)
