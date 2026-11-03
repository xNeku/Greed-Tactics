// Feedback arrow ribbon. UV.x: 0 at the start -> 1 at the arrow head base,
// > 1 inside the head. UV.y: 0..1 across the ribbon. Drawn on top of everything.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_test_disabled, depth_draw_never, shadows_disabled;

instance uniform vec4 arrow_color : source_color = vec4(0.4, 1.0, 0.5, 1.0);
uniform float dash_count = 9.0;
uniform float dash_speed = 1.6;
uniform float dash_dim : hint_range(0.0, 1.0) = 0.45;
uniform float start_fade : hint_range(0.0, 0.5) = 0.12;

void fragment() {
	float is_head = step(1.0, UV.x);
	float across = 1.0 - abs(UV.y - 0.5) * 2.0;
	float edge = smoothstep(0.0, 0.35, across);
	float dash = mix(dash_dim, 1.0, step(0.4, fract(UV.x * dash_count - TIME * dash_speed)));
	float body_alpha = edge * dash * smoothstep(0.0, start_fade, UV.x);
	ALBEDO = mix(arrow_color.rgb, vec3(1.0), (1.0 - edge) * 0.15 + is_head * 0.1);
	ALPHA = arrow_color.a * mix(body_alpha, 1.0, is_head);
}
