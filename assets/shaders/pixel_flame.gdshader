// Pixel-art flame on a camera-facing quad (torches, braziers): a flickering
// teardrop in palette bands, white-hot core to red tips. Unshaded and HDR,
// so it blooms.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec2 pixels = vec2(10.0, 16.0);
uniform float speed = 7.0;
uniform float energy = 2.5;
uniform vec4 core : source_color = vec4(1.0, 0.98, 0.8, 1.0);
uniform vec4 mid : source_color = vec4(1.0, 0.7, 0.2, 1.0);
uniform vec4 tip : source_color = vec4(0.9, 0.25, 0.08, 1.0);
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
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 cell = (floor(UV * pixels) + 0.5) / pixels;
	float y = 1.0 - cell.y;  // 0 bottom, 1 top
	float t = TIME * speed + seed;
	float sway = (noise(vec2(y * 3.0 - t * 0.6, seed)) - 0.5) * 0.35 * y;
	float x = (cell.x - 0.5 - sway) * 2.0;
	float width = (1.0 - y) * 0.9 + 0.1;
	width *= 0.75 + noise(vec2(t, y * 4.0)) * 0.35;
	float r = abs(x) / max(width, 0.01) + (noise(vec2(cell.x * 6.0, y * 5.0 - t)) - 0.5) * 0.4;
	if (r > 1.0 || y > 0.95) {
		discard;
	}
	float heat = (1.0 - r) * (1.0 - y * 0.8);
	vec3 color = heat > 0.55 ? core.rgb : (heat > 0.28 ? mid.rgb : tip.rgb);
	ALBEDO = color * energy;
}
