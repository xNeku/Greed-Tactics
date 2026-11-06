shader_type spatial;
// Projectile body. A camera-facing quad turned on screen towards the travel
// direction (plus spin), so pixel art arrows and bullets point where they fly
// and their pixels turn as whole squares. Two looks:
//   orb = false: the sprite texture, nearest filtered.
//   orb = true:  a procedural pixelated orb/comet (magic), animated with noise
//                and drawn in palette bands (edge, mid, white-hot core).
// Colours above 1.0 feed the environment glow.
render_mode unshaded, cull_disabled, depth_draw_opaque, skip_vertex_transform, shadows_disabled;

uniform sampler2D sprite : source_color, filter_nearest;
uniform bool orb = false;
// World size of the quad (x along the travel direction).
uniform vec2 quad_size = vec2(0.5, 0.2);
// World direction of travel (only its screen projection matters).
uniform vec3 direction = vec3(1.0, 0.0, 0.0);
// Extra rotation on screen, radians (spinning axes, rocks).
uniform float spin = 0.0;
uniform float emission = 1.0;
uniform vec4 tint : source_color = vec4(1.0);
// Orb look.
uniform float orb_pixels = 14.0;
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 mid_color : source_color = vec4(0.8, 0.5, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.4, 0.15, 0.8, 1.0);
// 0 = round orb, 1 = long comet tail behind it (fire).
uniform float tail = 0.4;
uniform float flicker_speed = 6.0;
uniform float seed = 0.0;

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
	vec3 center = (VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz, 1.0)).xyz;
	vec3 view_dir = (VIEW_MATRIX * vec4(direction, 0.0)).xyz;
	float angle = (length(view_dir.xy) > 0.0001 ? atan(view_dir.y, view_dir.x) : 0.0) + spin;
	vec2 local = VERTEX.xy * quad_size;
	float c = cos(angle);
	float s = sin(angle);
	VERTEX = center + vec3(c * local.x - s * local.y, s * local.x + c * local.y, 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	if (!orb) {
		vec4 texel = texture(sprite, UV);
		ALBEDO = texel.rgb * tint.rgb * emission;
		ALPHA = texel.a * tint.a;
		ALPHA_SCISSOR_THRESHOLD = 0.5;
	} else {
		// Pixel grid: the quad is wider than tall, keep pixels square.
		vec2 grid = vec2(orb_pixels * quad_size.x / quad_size.y, orb_pixels);
		vec2 cell = (floor(UV * grid) + 0.5) / grid;
		// Orb centre towards the front (+x = travel), tail behind it.
		vec2 p = vec2((cell.x - 0.72) * quad_size.x / quad_size.y, cell.y - 0.5) * 2.0;
		float t = TIME * flicker_speed + seed;
		float behind = max(-p.x, 0.0);
		float wobble = (noise(vec2(behind * 3.0 - t, p.y * 4.0 + seed)) - 0.5) * 0.45 * behind * tail;
		float stretch = mix(1.0, 0.28, tail);
		float r = length(vec2(p.x > 0.0 ? p.x : p.x * stretch, (p.y + wobble) * (1.0 + behind * 1.2 * tail)));
		r += (noise(cell * 9.0 + vec2(t, -t * 0.7)) - 0.5) * 0.35;
		if (r > 0.95) {
			discard;
		}
		vec3 color = r < 0.35 ? core_color.rgb : (r < 0.62 ? mid_color.rgb : edge_color.rgb);
		float boost = r < 0.35 ? 2.2 : (r < 0.62 ? 1.6 : 1.15);
		ALBEDO = color * tint.rgb * emission * boost;
		ALPHA = tint.a;
		ALPHA_SCISSOR_THRESHOLD = 0.5;
	}
}
