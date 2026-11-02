// Stylised animated water: two scrolling value-noise layers whose difference
// draws bright caustic swirls on a blue base. World-space, so tiles connect.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.22, 0.52, 0.95, 1.0);
uniform vec4 light_color : source_color = vec4(0.78, 0.92, 1.0, 1.0);
uniform vec4 side_color : source_color = vec4(0.16, 0.36, 0.72, 1.0);
uniform float noise_scale = 1.3;
uniform float flow_speed = 0.18;
uniform float caustic_sharpness : hint_range(0.01, 0.3) = 0.07;

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float total = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		total += value_noise(p) * amplitude;
		p *= 2.03;
		amplitude *= 0.5;
	}
	return total;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	if (world_normal.y > 0.5) {
		vec2 uv = world_pos.xz * noise_scale;
		float t = TIME * flow_speed;
		float a = fbm(uv + vec2(t, t * 0.7));
		float b = fbm(uv * 1.4 - vec2(t * 0.8, -t * 0.4) + 7.3);
		float caustic = 1.0 - smoothstep(0.0, caustic_sharpness, abs(a - b));
		float tint = smoothstep(0.35, 0.75, a);
		ALBEDO = mix(deep_color.rgb, light_color.rgb, clamp(caustic * 0.85 + tint * 0.25, 0.0, 1.0));
		ROUGHNESS = 0.25;
	} else {
		ALBEDO = side_color.rgb;
		ROUGHNESS = 0.8;
	}
}
