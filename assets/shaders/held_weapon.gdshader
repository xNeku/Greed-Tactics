shader_type spatial;
// A weapon held in a unit's hand. The quad is a Y-fixed billboard like the
// unit sprite; the weapon is placed, rotated, scaled and mirrored in the
// sprite's own pixel space (as in the armory preview), so its pixels turn as
// whole squares and are never re-sampled into the hero's grid.
render_mode unshaded, cull_disabled, depth_draw_opaque, skip_vertex_transform;

uniform sampler2D weapon_texture : source_color, filter_nearest;
uniform vec2 weapon_size = vec2(16.0);
// Pixel of the weapon held in the hand.
uniform vec2 grip = vec2(0.0);
// Current body frame size and hand pixel (y down).
uniform vec2 body_size = vec2(20.0, 28.0);
uniform vec2 hand = vec2(10.0, 20.0);
// Clockwise on screen, radians.
uniform float rotation = 0.0;
uniform float weapon_scale = 1.0;
uniform float flip = 1.0;
// -1 when the body sprite is mirrored.
uniform float body_flip = 1.0;
uniform float pixel_size = 0.036;
// World units towards (+) or away from (-) the camera: in front of / behind the body.
uniform float depth_bias = 0.01;
uniform vec4 tint : source_color = vec4(1.0);
// > 1 glows (rage eyes).
uniform float emission = 1.0;

void vertex() {
	// Texel position of this corner (QuadMesh UV: 0,0 top-left).
	vec2 d = UV * weapon_size - grip - vec2(0.5);
	d.x *= flip;
	d *= weapon_scale;
	float c = cos(rotation);
	float s = sin(rotation);
	vec2 p = hand + vec2(0.5) + vec2(c * d.x - s * d.y, s * d.x + c * d.y);
	vec2 local = vec2((p.x - body_size.x * 0.5) * body_flip, body_size.y - p.y) * pixel_size;
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz));
	vec3 normal = normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0)));
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	vec3 world = MODEL_MATRIX[3].xyz + right * local.x * sx + vec3(0.0, local.y * sy, 0.0) + normal * depth_bias;
	VERTEX = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec4 texel = texture(weapon_texture, UV);
	ALBEDO = texel.rgb * tint.rgb * emission;
	ALPHA = texel.a * tint.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
