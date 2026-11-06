shader_type spatial;
// Impact flash: a pixelated four-point star (with a rotated smaller one) that
// faces the camera. `progress` 0 -> 1 grows it and eats it from the inside.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, depth_test_disabled;

instance uniform vec4 tint : source_color = vec4(1.0, 0.9, 0.6, 1.0);
instance uniform float progress = 0.0;
uniform float pixels = 24.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	vec2 p = ((floor(UV * pixels) + 0.5) / pixels - 0.5) * 2.0;
	vec2 a = abs(p);
	float star = a.x * a.y * 14.0 + max(a.x, a.y) * 0.9;
	vec2 d = abs(vec2(p.x + p.y, p.x - p.y)) * 0.7071;
	float small = d.x * d.y * 20.0 + max(d.x, d.y) * 1.6;
	float shape = min(star, small);
	float outer = mix(0.3, 1.0, progress);
	float inner = max(progress * 1.3 - 0.35, 0.0);
	if (shape > outer || shape < inner) {
		discard;
	}
	float hot = 1.0 - smoothstep(0.0, outer, shape);
	ALBEDO = mix(tint.rgb, vec3(1.0), hot * 0.7) * (2.0 + hot * 2.0);
	ALPHA = tint.a;
}
