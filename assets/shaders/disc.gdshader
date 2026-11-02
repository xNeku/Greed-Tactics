// Flat disc on a quad: used for the team ring under units and the blob shadow.
// disc_color is an instance uniform, so every unit can tint its own ring
// without duplicating materials (GeometryInstance3D.set_instance_shader_parameter).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

instance uniform vec4 disc_color : source_color = vec4(0.25, 0.55, 1.0, 1.0);
uniform float softness : hint_range(0.001, 1.0) = 0.06;
uniform float rim_width : hint_range(0.0, 1.0) = 0.18;
uniform float rim_brightness : hint_range(0.0, 1.0) = 0.35;
uniform float center_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float mask = 1.0 - smoothstep(1.0 - softness, 1.0, r);
	float rim = smoothstep(1.0 - rim_width - softness, 1.0 - rim_width, r);
	ALBEDO = mix(disc_color.rgb, vec3(1.0), rim * rim_brightness);
	ALPHA = mask * disc_color.a * mix(center_alpha, 1.0, rim);
}
