class_name EyeGlow
extends Node3D
## Glowing eyes (rage mode): one pixel quad per eye pixel of the unit sprite
## (UnitData.eyes_front / eyes_side), drawn with the held-weapon shader so it
## follows the sprite in every view and mirror, bright enough to bloom.

const EYE_COLOR := Color(1.0, 0.12, 0.08)

@export var glow_shader: Shader

var _quads: Array[MeshInstance3D] = []
var _texture: ImageTexture


func _ready() -> void:
	var image := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	_texture = ImageTexture.create_from_image(image)
	visible = false


## Places the eyes for the current frame (call every frame while visible).
func follow(body: SpriteBase3D, frame: Texture2D, eyes: Array[Vector2i], flipped: bool, pulse: float) -> void:
	if frame == null:
		return
	while _quads.size() < eyes.size():
		_quads.append(_new_quad())
	for i in _quads.size():
		var quad := _quads[i]
		quad.visible = i < eyes.size()
		if not quad.visible:
			continue
		var material := quad.material_override as ShaderMaterial
		material.set_shader_parameter(&"body_size", Vector2(frame.get_size()))
		material.set_shader_parameter(&"hand", Vector2(eyes[i]))
		material.set_shader_parameter(&"body_flip", -1.0 if flipped else 1.0)
		material.set_shader_parameter(&"pixel_size", body.pixel_size)
		material.set_shader_parameter(&"emission", 3.0 + pulse * 2.0)
		material.set_shader_parameter(&"tint", Color(EYE_COLOR, body.modulate.a))


func _new_quad() -> MeshInstance3D:
	var quad := MeshInstance3D.new()
	quad.mesh = QuadMesh.new()
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.extra_cull_margin = 2.0
	var material := ShaderMaterial.new()
	material.shader = glow_shader
	material.render_priority = 2
	material.set_shader_parameter(&"weapon_texture", _texture)
	material.set_shader_parameter(&"weapon_size", Vector2.ONE)
	material.set_shader_parameter(&"grip", Vector2.ZERO)
	material.set_shader_parameter(&"depth_bias", 0.02)
	quad.material_override = material
	add_child(quad)
	return quad
