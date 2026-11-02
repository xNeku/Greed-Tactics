// Overlay quad drawn on top of a cell: translucent fill + bright border.
// One material per highlight layer (move, path, target, area, cursor).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform float fill_alpha : hint_range(0.0, 1.0) = 0.35;
uniform float border_alpha : hint_range(0.0, 1.0) = 0.9;
uniform float border_width : hint_range(0.0, 0.5) = 0.07;
uniform float pulse_speed = 3.0;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	vec2 d = abs(UV - 0.5);
	float edge = smoothstep(0.5 - border_width, 0.5 - border_width * 0.3, max(d.x, d.y));
	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;
	ALBEDO = mix(tint.rgb, vec3(1.0), edge * 0.35);
	ALPHA = clamp(mix(fill_alpha * pulse, border_alpha, edge), 0.0, 1.0);
}
