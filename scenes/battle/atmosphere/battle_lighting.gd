class_name BattleLighting
extends Node
## Light and atmosphere of a battle (GDD §11, v0.9): applies a LightingMood
## (backdrop sky, sun or moon, ambient, fog and volumetric shafts, bloom,
## colour grade), turns the sun slowly during the battle, and keeps an HD-2D
## depth of field focused on the camera's point of interest.

## Lights of props (torches, braziers...) join this group; their energy is
## scaled by the mood (dim by day, bright at night). Base energy in meta.
const PROP_LIGHTS_GROUP := &"mood_lights"

@export var world_environment: WorldEnvironment
@export var sun: DirectionalLight3D
@export var camera_rig: CameraRig
@export var sky_shader: Shader
## Depth of field: blur starts this far behind / in front of the focus.
@export var dof_far_offset := 9.0
@export var dof_near_offset := 7.0
@export_range(0.0, 0.3) var dof_amount := 0.045

var mood: LightingMood
var _attributes := CameraAttributesPractical.new()
var _sky_material: ShaderMaterial


## Applies the mood [param mood_id] of [param zone] (or one picked from
## [param pick_seed] when empty). Zones without moods keep their old look.
func apply(zone: ZoneData, mood_id: String, pick_seed: int) -> void:
	mood = _pick(zone, mood_id, pick_seed)
	var env := world_environment.environment
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.camera_attributes = _attributes
	_attributes.dof_blur_far_enabled = true
	_attributes.dof_blur_near_enabled = true
	_attributes.dof_blur_amount = dof_amount
	if mood == null:
		_apply_legacy(zone)
		return
	var m := mood
	_sky_material = ShaderMaterial.new()
	_sky_material.shader = sky_shader
	for key in ["sky_top", "sky_middle", "sky_bottom", "stars", "disc", "disc_is_sun", "disc_color",
			"disc_position", "disc_size", "halo_color", "clouds", "cloud_color"]:
		_sky_material.set_shader_parameter(key, m.get(key))
	if m.indoor:
		_sky_material.set_shader_parameter(&"stars", 0.0)
		_sky_material.set_shader_parameter(&"disc", false)
	var sky := Sky.new()
	sky.sky_material = _sky_material
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.ambient_light_color = m.ambient_color
	env.ambient_light_energy = m.ambient_energy
	sun.light_color = m.light_color
	sun.light_energy = m.light_energy
	sun.rotation_degrees = Vector3(m.light_rotation.x, m.light_rotation.y, 0.0)
	sun.shadow_enabled = m.light_energy > 0.0
	sun.shadow_opacity = m.shadow_opacity
	sun.light_volumetric_fog_energy = m.light_volumetric
	env.fog_enabled = m.fog_density > 0.0
	env.fog_light_color = m.fog_color
	env.fog_density = m.fog_density
	# Volumetric fog only inside a box over the map (FogVolume): light shafts
	# show on the diorama without veiling the camera, which stands far away.
	env.volumetric_fog_enabled = m.volumetric_density > 0.0
	env.volumetric_fog_density = 0.0
	env.volumetric_fog_albedo = m.volumetric_albedo
	env.volumetric_fog_length = 64.0
	env.volumetric_fog_detail_spread = 1.0
	env.volumetric_fog_temporal_reprojection_enabled = true
	env.glow_enabled = m.glow > 0.0
	env.glow_intensity = m.glow
	env.glow_hdr_threshold = 0.9
	env.glow_bloom = 0.04
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.tonemap_exposure = m.exposure
	env.adjustment_enabled = true
	env.adjustment_contrast = m.contrast
	env.adjustment_saturation = m.saturation
	scale_prop_lights.call_deferred()


## Fills [param bounds] (the map) with the mood's volumetric fog, thicker low.
func fill_fog(bounds: AABB) -> void:
	if mood == null or mood.volumetric_density <= 0.0:
		return
	var volume := FogVolume.new()
	volume.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	volume.size = Vector3(bounds.size.x + 6.0, 7.0, bounds.size.z + 6.0)
	var material := FogMaterial.new()
	material.density = mood.volumetric_density
	material.albedo = mood.volumetric_albedo
	material.height_falloff = 0.25
	material.edge_fade = 0.4
	volume.material = material
	add_child(volume)
	volume.global_position = bounds.get_center() + Vector3(0.0, 2.5, 0.0)


## Scales every prop light by the mood (call again after props spawn).
func scale_prop_lights() -> void:
	var factor := mood.props_light if mood != null else 1.0
	for node in get_tree().get_nodes_in_group(PROP_LIGHTS_GROUP):
		if node.has_method(&"set_mood_factor"):
			node.call(&"set_mood_factor", factor)
			continue
		var light := node as Light3D
		if light == null:
			continue
		if not light.has_meta(&"base_energy"):
			light.set_meta(&"base_energy", light.light_energy)
		light.light_energy = float(light.get_meta(&"base_energy")) * factor
		light.visible = factor > 0.01


func _process(delta: float) -> void:
	if mood != null and mood.light_spin != 0.0:
		sun.rotation_degrees.y += mood.light_spin * delta
	if camera_rig != null:
		# Focus on the point the camera orbits; blur what is far behind / in front.
		var focus := camera_rig.get_camera().global_position.distance_to(camera_rig.global_position)
		_attributes.dof_blur_far_distance = focus + dof_far_offset
		_attributes.dof_blur_far_transition = 10.0
		_attributes.dof_blur_near_distance = maxf(focus - dof_near_offset, 0.5)
		_attributes.dof_blur_near_transition = 4.0
	if _sky_material != null:
		_sky_material.set_shader_parameter(&"screen_size", Vector2(get_viewport().get_visible_rect().size))


func _pick(zone: ZoneData, mood_id: String, pick_seed: int) -> LightingMood:
	if zone == null or zone.moods.is_empty():
		return null
	for candidate in zone.moods:
		if String(candidate.id) == mood_id:
			return candidate
	var rng := RandomNumberGenerator.new()
	rng.seed = pick_seed
	return zone.moods[rng.randi_range(0, zone.moods.size() - 1)]


func _apply_legacy(zone: ZoneData) -> void:
	var env := world_environment.environment
	env.background_color = zone.background_color
	env.ambient_light_color = zone.ambient_color
	env.ambient_light_energy = zone.ambient_energy
	sun.light_color = zone.sun_color
	sun.light_energy = zone.sun_energy
	sun.rotation_degrees = Vector3(zone.sun_rotation_degrees.x, zone.sun_rotation_degrees.y, 0.0)
	env.fog_enabled = zone.fog_density > 0.0
	env.fog_light_color = zone.fog_color
	env.fog_density = zone.fog_density
	env.glow_enabled = zone.glow_intensity > 0.0
	env.glow_intensity = zone.glow_intensity
