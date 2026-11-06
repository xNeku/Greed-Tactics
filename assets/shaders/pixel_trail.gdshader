shader_type spatial;
// Ribbon trail behind a projectile (VfxTrail). Vertex colour alpha = life left;
// it is cut in hard bands and the ribbon edge is hard, so the trail reads as
// pixel art. Additive and HDR: it glows.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.8, 0.5, 1.0);
uniform float emission = 2.0;
uniform float bands = 4.0;

void fragment() {
	float life = COLOR.a;
	// UV.y: 0..1 across the ribbon; thinner as it fades.
	float across = abs(UV.y - 0.5) * 2.0;
	if (across > life) {
		discard;
	}
	float banded = ceil(life * bands) / bands;
	ALBEDO = color.rgb * emission * banded;
	ALPHA = color.a * banded;
}
