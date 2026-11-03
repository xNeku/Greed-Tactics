// Melee swing: a billboard crescent that sweeps with `progress` (0 -> 1).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

instance uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float progress = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 c = (UV - vec2(0.5, 0.85)) * vec2(1.0, 1.6);
	float r = length(c);
	float ring = smoothstep(0.28, 0.37, r) * (1.0 - smoothstep(0.41, 0.48, r));
	float sweep = clamp((atan(c.x, -c.y) + 1.6) / 3.2, 0.0, 1.0);
	float shown = step(sweep, progress) * smoothstep(progress - 0.7, progress, sweep);
	ALBEDO = mix(tint.rgb, vec3(1.0), ring * 0.5);
	ALPHA = clamp(ring * shown * tint.a, 0.0, 1.0);
}
