// Terrain columns (one MultiMesh instance per cell).
// INSTANCE_CUSTOM.rgb = top colour, INSTANCE_CUSTOM.a = surface style / 10
// (see TerrainData.Surface), COLOR.rgb = side colour (MultiMesh use_colors).
// Everything is procedural and in world space so neighbouring cells connect.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform float checker_strength : hint_range(0.0, 0.3) = 0.04;
uniform float grid_line_width : hint_range(0.0, 0.2) = 0.03;
uniform float grid_line_darken : hint_range(0.0, 1.0) = 0.22;
uniform float bevel_width : hint_range(0.0, 0.3) = 0.07;
uniform float bevel_light : hint_range(0.0, 0.5) = 0.12;
uniform float cell_variation : hint_range(0.0, 0.3) = 0.07;
uniform float side_ao : hint_range(0.0, 1.0) = 0.45;
uniform float strata_strength : hint_range(0.0, 0.5) = 0.12;

const float PLAIN = 0.0;
const float GRASS = 1.0;
const float ROCK = 2.0;
const float SAND = 3.0;
const float DIRT = 4.0;
const float CAVE = 5.0;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 top_color;
varying vec3 side_color;
varying float style;
varying float column_top;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	return noise(p) * 0.55 + noise(p * 2.1 + 3.7) * 0.3 + noise(p * 4.3 + 9.1) * 0.15;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	top_color = INSTANCE_CUSTOM.rgb;
	side_color = COLOR.rgb;
	style = floor(INSTANCE_CUSTOM.a * 10.0 + 0.5);
	column_top = (MODEL_MATRIX * vec4(0.0, 0.5, 0.0, 1.0)).y;
}

vec3 top_surface(vec2 p, vec2 cell) {
	vec3 base = top_color * (1.0 + (hash(cell) - 0.5) * 2.0 * cell_variation);
	base *= 1.0 - mod(cell.x + cell.y, 2.0) * checker_strength;
	if (style == GRASS) {
		float blotch = fbm(p * 1.3);
		base *= mix(0.9, 1.1, blotch);
		float blades = step(0.86, hash(floor(p * 9.0)));
		base *= 1.0 - blades * 0.18;
		base += vec3(0.05, 0.07, 0.0) * step(0.93, hash(floor(p * 9.0) + 17.0));
	} else if (style == ROCK) {
		float n = fbm(p * 1.4);
		float crack = 1.0 - smoothstep(0.0, 0.018, abs(n - 0.5));
		base *= mix(0.93, 1.05, noise(p * 6.0)) * (1.0 - crack * 0.2);
	} else if (style == SAND) {
		float ripple = sin((p.x * 0.8 + p.y * 0.45) * 9.0 + fbm(p * 1.5) * 6.0);
		base *= 1.0 + ripple * 0.045;
		base *= 1.0 - step(0.95, hash(floor(p * 12.0))) * 0.12;
	} else if (style == DIRT) {
		base *= mix(0.9, 1.06, fbm(p * 2.5));
		float pebble = step(0.9, hash(floor(p * 7.0)));
		base = mix(base, base * 1.25, pebble * 0.6);
	} else if (style == CAVE) {
		base *= mix(0.85, 1.08, fbm(p * 1.8));
		base *= 1.0 - step(0.9, hash(floor(p * 10.0))) * 0.2;
	} else {
		base *= mix(0.95, 1.05, noise(p * 3.0));
	}
	return base;
}

void fragment() {
	vec2 p = world_pos.xz;
	vec2 cell = floor(p + 0.5);
	if (world_normal.y > 0.5) {
		vec3 base = top_surface(p, cell);
		vec2 local = abs(fract(p + 0.5) - 0.5);
		float to_edge = 0.5 - max(local.x, local.y);
		float line = 1.0 - smoothstep(0.0, grid_line_width, to_edge);
		float bevel = 1.0 - smoothstep(grid_line_width, grid_line_width + bevel_width, to_edge);
		base *= 1.0 + (bevel - line) * bevel_light;
		ALBEDO = base * (1.0 - line * grid_line_darken);
	} else {
		float depth = column_top - world_pos.y;
		float along = dot(p, vec2(abs(world_normal.z), abs(world_normal.x)));
		vec3 side = side_color;
		if (style == GRASS) {
			// Grass hangs over the dirt sides with a jagged edge.
			float band = 0.1 + noise(vec2(along * 6.0, 0.0)) * 0.08;
			side = depth < band ? top_color * 0.82 : side_color * mix(0.9, 1.08, noise(vec2(along * 4.0, world_pos.y * 6.0)));
		} else {
			float strata = sin(world_pos.y * 12.0 + noise(vec2(along * 2.0, world_pos.y)) * 2.0);
			side *= 1.0 + strata * strata_strength * (style == SAND || style == ROCK ? 1.0 : 0.4);
			side *= mix(0.92, 1.06, noise(vec2(along * 5.0, world_pos.y * 3.0)));
		}
		// Darker towards the bottom of each column (fake ambient occlusion).
		side *= 1.0 - side_ao * clamp(depth * 0.6, 0.0, 1.0);
		// Thin light lip right below the top edge.
		side *= 1.0 + (1.0 - smoothstep(0.0, 0.04, depth)) * 0.15;
		ALBEDO = side;
	}
}
