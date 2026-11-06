// Animated backdrop of the menus: a dusky gradient, a faint diamond pattern,
// pixel embers drifting up and a vignette. Cheap (one rect, no textures).
shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.05, 0.05, 0.09, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.13, 0.08, 0.1, 1.0);
uniform vec4 ember_color : source_color = vec4(1.0, 0.7, 0.35, 1.0);
uniform float pixel = 3.0;
uniform float ember_density = 0.6;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 px = floor(FRAGCOORD.xy / pixel);
	vec2 uv = UV;
	vec3 color = mix(top_color.rgb, bottom_color.rgb, smoothstep(0.0, 1.0, uv.y));
	// Diamond lattice, very faint.
	color += vec3(0.012) * step(0.47, max(abs(fract((px.x + px.y) / 32.0) - 0.5), abs(fract((px.x - px.y) / 32.0) - 0.5)));
	// Embers: columns of pixels drifting up at their own speed.
	float column = px.x;
	float speed = 8.0 + hash(vec2(column, 3.0)) * 18.0;
	float offset = hash(vec2(column, 7.0)) * 1000.0;
	float ember = step(1.0 - ember_density * 0.004, hash(vec2(column, floor((px.y + TIME * speed + offset) / 40.0))));
	ember *= step(mod(px.y + floor(TIME * speed) + offset, 40.0), 1.0);
	float rise = 1.0 - uv.y;
	color += ember_color.rgb * ember * (0.4 + 0.6 * (1.0 - rise)) * 0.9;
	// Vignette.
	float v = length((uv - 0.5) * vec2(1.2, 1.0));
	color *= 1.0 - smoothstep(0.45, 0.95, v) * 0.6;
	COLOR = vec4(color, 1.0);
}
