shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Expanding ground ring: a bright band at `progress` (0..1 of the radius), fading out.

instance uniform vec4 tint : source_color = vec4(1.0, 0.9, 0.7, 1.0);
instance uniform float progress = 0.0;
uniform float width = 0.12;

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float band = 1.0 - smoothstep(0.0, width, abs(d - progress));
	float inner = (1.0 - smoothstep(0.0, progress, d)) * 0.18;
	float fade = 1.0 - progress;
	ALBEDO = tint.rgb * 2.5;
	ALPHA = clamp((band + inner) * fade * tint.a, 0.0, 1.0);
}
