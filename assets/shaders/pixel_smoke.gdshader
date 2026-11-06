shader_type spatial;
// Soft smoke puffs drawn as pixelated discs (gun smoke, impact dust).
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;

uniform float pixels = 8.0;

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = ((floor(UV * pixels) + 0.5) / pixels - 0.5) * 2.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float shade = r < 0.55 ? 1.0 : 0.8;
	ALBEDO = COLOR.rgb * shade;
	ALPHA = COLOR.a * (r < 0.55 ? 0.85 : 0.6);
}
