// Additive glow for placeholder VFX meshes (projectile core, slash, flashes).
// tint is per instance; on spheres the edge fades (soft core), on quads the
// UV distance to the center fades.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

instance uniform vec4 tint : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform bool use_uv_falloff = false;

void fragment() {
	float falloff;
	if (use_uv_falloff) {
		falloff = 1.0 - clamp(length(UV - 0.5) * 2.0, 0.0, 1.0);
	} else {
		falloff = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	}
	ALBEDO = mix(tint.rgb, vec3(1.0), falloff * falloff * 0.6);
	ALPHA = tint.a * falloff;
}
