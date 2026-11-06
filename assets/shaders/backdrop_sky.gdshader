// Backdrop behind the battle diorama (the camera looks down, so this is drawn
// in screen space, like a painted HD-2D background). Pixelated gradient with
// dithered bands, twinkling stars that turn with the camera, a moon or sun
// disc with a halo and soft cloud streaks drifting. Colours from LightingMood.
shader_type sky;

uniform vec4 sky_top : source_color = vec4(0.08, 0.1, 0.22, 1.0);
uniform vec4 sky_middle : source_color = vec4(0.2, 0.25, 0.45, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.45, 0.4, 0.55, 1.0);
uniform float stars = 0.0;
uniform bool disc = false;
uniform bool disc_is_sun = false;
uniform vec4 disc_color : source_color = vec4(0.95, 0.97, 1.0, 1.0);
uniform vec2 disc_position = vec2(0.8, 0.18);
uniform float disc_size = 0.07;
uniform vec4 halo_color : source_color = vec4(0.6, 0.7, 1.0, 0.35);
uniform float clouds = 0.0;
uniform vec4 cloud_color : source_color = vec4(0.9, 0.6, 0.5, 1.0);
// Size of one backdrop pixel, in screen pixels (pixel-art backdrop).
uniform float pixel = 3.0;
uniform vec2 screen_size = vec2(1280.0, 720.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return float(m[y * 4 + x]) / 16.0;
}

void sky() {
	vec2 res = screen_size / pixel;
	vec2 px = floor(SCREEN_UV * res);
	vec2 uv = (px + 0.5) / res;
	// Gradient in a few dithered bands.
	float t = uv.y;
	float d = bayer4(px) - 0.5;
	float steps = 10.0;
	float tq = clamp(floor(t * steps + d) / steps, 0.0, 1.0);
	vec3 color = tq < 0.5 ? mix(sky_top.rgb, sky_middle.rgb, tq * 2.0) : mix(sky_middle.rgb, sky_bottom.rgb, (tq - 0.5) * 2.0);
	// Clouds: long horizontal streaks.
	if (clouds > 0.0) {
		vec2 cp = vec2(uv.x * 3.0 + TIME * 0.006, uv.y * 14.0);
		float c = noise(cp) * 0.6 + noise(cp * 2.3 + 4.0) * 0.4;
		float band = smoothstep(0.25, 0.75, sin(uv.y * 18.0 + noise(vec2(uv.x * 2.0, 1.0)) * 3.0) * 0.5 + 0.5);
		float amount = step(1.0 - clouds * 0.55 + d * 0.08, c * band);
		color = mix(color, cloud_color.rgb, amount * 0.85);
	}
	// Stars: fixed on the sky dome, so they turn with the camera.
	if (stars > 0.0) {
		vec3 dir = normalize(vec3(EYEDIR.x, abs(EYEDIR.y) + 0.3, EYEDIR.z));
		vec2 sp = floor(vec2(atan(dir.x, dir.z) * 220.0, dir.y * 220.0));
		float h = hash(sp);
		float twinkle = 0.6 + 0.4 * sin(TIME * (1.0 + h * 3.0) + h * 40.0);
		float on = step(1.0 - stars * 0.006, h) * (1.0 - uv.y * 0.8);
		float big = step(1.0 - stars * 0.0015, hash(sp + 7.0));
		color += vec3(0.9, 0.93, 1.0) * on * twinkle * (1.0 + big);
	}
	// Moon / sun disc with a halo.
	if (disc) {
		vec2 aspect = vec2(screen_size.x / screen_size.y, 1.0);
		vec2 dv = (uv - disc_position) * aspect;
		float r = length(dv) / disc_size;
		float halo = clamp(1.0 - (r - 1.0) / 3.0, 0.0, 1.0);
		halo = floor(halo * 5.0 + d) / 5.0;
		color = mix(color, halo_color.rgb, halo * halo * halo_color.a);
		if (r < 1.0) {
			vec3 body = disc_color.rgb;
			if (!disc_is_sun) {
				// Craters and a darker limb.
				vec2 cp = floor(dv / disc_size * 8.0);
				body *= 1.0 - step(0.72, hash(cp)) * 0.18 - r * r * 0.15;
			} else {
				body *= 1.6;
			}
			color = body;
		}
	}
	COLOR = color;
}
