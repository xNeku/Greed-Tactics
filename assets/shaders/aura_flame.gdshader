shader_type spatial;
// Aura around a unit (elites, bosses, rage, buffs): pixelated flames rising
// around the body like a fighting-anime power-up, in up to three colour
// bands (outer -> inner), additive and HDR so it blooms. The quad faces the
// camera (Y-fixed like the unit sprite) and sits just behind the body.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, skip_vertex_transform;

uniform vec2 quad_size = vec2(1.3, 1.7);
uniform float pixel_size = 0.036;
uniform vec4 outer : source_color = vec4(1.0, 0.3, 0.1, 1.0);
uniform vec4 mid : source_color = vec4(1.0, 0.65, 0.2, 1.0);
uniform vec4 inner : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform float strength = 1.0;
// How wild the tongues are (bosses > elites).
uniform float wildness = 0.5;
uniform float speed = 3.0;
uniform float seed = 0.0;
uniform float depth_bias = -0.06;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz));
	vec3 normal = normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0)));
	float sy = length(MODEL_MATRIX[1].xyz);
	vec2 local = VERTEX.xy * quad_size;
	vec3 world = MODEL_MATRIX[3].xyz + right * local.x + vec3(0.0, (local.y + quad_size.y * 0.5) * sy, 0.0) + normal * depth_bias;
	VERTEX = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
}

void fragment() {
	vec2 grid = quad_size / pixel_size;
	vec2 cell = (floor(UV * grid) + 0.5) / grid;
	// p: -1..1 across, 0 (feet) .. 1 (top).
	vec2 p = vec2((cell.x - 0.5) * 2.0, 1.0 - cell.y);
	float t = TIME * speed + seed;
	// Body ellipse a bit above the feet; flames lick upwards.
	vec2 c = vec2(p.x, (p.y - 0.42) * 1.25);
	float angle = atan(c.x, c.y);
	float r = length(c);
	float up = clamp(p.y, 0.0, 1.0);
	float tongues = noise(vec2(angle * 3.0 + seed, p.y * 4.0 - t)) * 0.6 + noise(vec2(angle * 7.0, p.y * 9.0 - t * 1.6)) * 0.4;
	float edge = 0.78 + tongues * (0.18 + wildness * 0.32) * (0.4 + up);
	float flicker = 0.85 + 0.15 * sin(t * 2.3 + seed);
	if (r > edge * flicker || p.y < 0.02) {
		discard;
	}
	float k = r / (edge * flicker);
	vec3 color = k > 0.82 ? outer.rgb : (k > 0.6 ? mid.rgb : inner.rgb);
	float alpha = k > 0.82 ? 0.8 : (k > 0.6 ? 0.45 : 0.18);
	// Fade at the feet so it rises from the ground.
	alpha *= smoothstep(0.0, 0.12, p.y);
	ALBEDO = color * strength * 1.6;
	ALPHA = alpha * clamp(strength, 0.0, 1.0);
}
