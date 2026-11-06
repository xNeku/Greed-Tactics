shader_type spatial;
// Overhead health bar, drawn as pixel art on a camera-facing quad:
// dark frame, the "ghost" (lost HP that drains after a short delay, or healed
// HP that fills first), the current HP, tick marks every few HP, a white flash
// on the chunk just lost and a pulse when low. Values are 0..1 ratios.
render_mode unshaded, cull_disabled, shadows_disabled, depth_test_disabled, depth_draw_never;

uniform vec2 pixels = vec2(28.0, 5.0);
uniform float hp = 1.0;
uniform float ghost = 1.0;
// > hp: damage ghost (drains). < hp: heal (the new part shows in heal_color first).
uniform float flash = 0.0;
uniform float tick = 0.25;
uniform float low_pulse = 0.0;
uniform float alpha = 1.0;
uniform vec4 fill_color : source_color = vec4(0.4, 0.9, 0.45, 1.0);
uniform vec4 fill_dark : source_color = vec4(0.2, 0.55, 0.25, 1.0);
uniform vec4 ghost_color : source_color = vec4(1.0, 0.85, 0.35, 1.0);
uniform vec4 heal_color : source_color = vec4(0.75, 1.0, 0.7, 1.0);
uniform vec4 back_color : source_color = vec4(0.12, 0.1, 0.14, 1.0);
uniform vec4 frame_color : source_color = vec4(0.03, 0.03, 0.05, 1.0);

void vertex() {
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sx, INV_VIEW_MATRIX[1] * sy, INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 px = floor(UV * pixels);
	// 1-pixel frame around.
	if (px.x < 1.0 || px.y < 1.0 || px.x > pixels.x - 2.0 || px.y > pixels.y - 2.0) {
		ALBEDO = frame_color.rgb;
	} else {
		float inner = pixels.x - 2.0;
		float x = (px.x - 1.0 + 0.5) / inner;
		float row = px.y - 1.0;
		vec3 color = back_color.rgb;
		float lo = min(hp, ghost);
		float hi = max(hp, ghost);
		if (x < lo) {
			// Top row lighter, bottom row darker: a little bevel.
			color = row < 0.5 ? mix(fill_color.rgb, vec3(1.0), 0.35) : (row > pixels.y - 3.5 ? fill_dark.rgb : fill_color.rgb);
			color = mix(color, vec3(1.0, 0.25, 0.2), low_pulse * 0.6);
		} else if (x < hi) {
			color = ghost > hp ? mix(ghost_color.rgb, vec3(1.0), flash) : heal_color.rgb;
		}
		// Tick marks every `tick` of the bar (darker pixel column).
		float cells = 1.0 / max(tick, 0.02);
		float t = fract(x * cells);
		if (tick < 0.99 && t < cells / inner && x > 0.02 && x < hi) {
			color *= 0.55;
		}
		ALBEDO = color;
	}
	ALPHA = alpha;
}
