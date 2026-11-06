shader_type spatial;
// Square "pixel" particles (sparks, embers, frost, debris): camera-facing,
// solid colour from the particle colour, boosted by `energy` so they glow.
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_opaque;

uniform float energy = 2.0;

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	ALBEDO = COLOR.rgb * energy;
	ALPHA = COLOR.a;
	ALPHA_SCISSOR_THRESHOLD = 0.35;
}
