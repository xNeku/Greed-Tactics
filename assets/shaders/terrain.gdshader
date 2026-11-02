// Terrain columns (one MultiMesh instance per cell).
// INSTANCE_CUSTOM.rgb = top colour, COLOR.rgb = side colour (MultiMesh use_colors).
// Draws a subtle checkerboard and grid lines on top faces, all in world space.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform float checker_strength : hint_range(0.0, 0.3) = 0.06;
uniform float grid_line_width : hint_range(0.0, 0.2) = 0.03;
uniform float grid_line_darken : hint_range(0.0, 1.0) = 0.18;
uniform float side_gradient : hint_range(0.0, 1.0) = 0.25;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 top_color;
varying vec3 side_color;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	top_color = INSTANCE_CUSTOM.rgb;
	side_color = COLOR.rgb;
}

void fragment() {
	if (world_normal.y > 0.5) {
		vec2 cell = floor(world_pos.xz + 0.5);
		float parity = mod(cell.x + cell.y, 2.0);
		vec3 base = top_color * (1.0 - parity * checker_strength);
		vec2 local = abs(fract(world_pos.xz + 0.5) - 0.5);
		float edge = smoothstep(0.5 - grid_line_width, 0.5, max(local.x, local.y));
		ALBEDO = base * (1.0 - edge * grid_line_darken);
	} else {
		// Slightly darker towards the bottom of each column.
		float shade = 1.0 - side_gradient * clamp(-world_pos.y * 0.5, 0.0, 1.0);
		ALBEDO = side_color * shade;
	}
}
