// Soft dark corners: frames the board and gives the scene some mood.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.02, 0.02, 0.05, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.45;
uniform float inner_radius : hint_range(0.0, 1.5) = 0.55;
uniform float outer_radius : hint_range(0.0, 2.0) = 1.15;

void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.6, 1.0);
	float d = length(p) / 0.94;
	COLOR = vec4(tint.rgb, smoothstep(inner_radius, outer_radius, d) * strength);
}
