shader_type canvas_item;
// Full-screen punch for skills: colour flash, chromatic aberration and a
// tinted vignette. Only visible while a skill uses it (ScreenFx).

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash = 0.0;
uniform float aberration = 0.0;
uniform vec4 tint_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float tint = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dir = uv - vec2(0.5);
	float shift = aberration * 0.01;
	vec3 color;
	color.r = texture(screen_texture, uv + dir * shift).r;
	color.g = texture(screen_texture, uv).g;
	color.b = texture(screen_texture, uv - dir * shift).b;
	float edge = smoothstep(0.2, 0.85, length(dir));
	color = mix(color, tint_color.rgb, tint * (0.25 + 0.75 * edge));
	color = mix(color, flash_color.rgb, flash);
	COLOR = vec4(color, 1.0);
}
