// Terrain columns (one MultiMesh instance per cell, two per stair cell).
// Pixel-art textures from a Texture2DArray, 32 px per world unit (the pixel
// density of the characters), nearest filtered, in world space so cells
// connect. Per instance:
//   INSTANCE_CUSTOM.r = top texture layer / 255
//   INSTANCE_CUSTOM.g = side texture layer / 255
//   INSTANCE_CUSTOM.b = pixels of the top texture hanging over the sides / 32
//   COLOR.rgb         = tint
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2DArray layers : source_color, filter_nearest, repeat_enable;
uniform float pixels_per_unit = 32.0;
// Thin darker line on cell borders (the tactical grid), 0 = none.
uniform float grid_darken : hint_range(0.0, 1.0) = 0.16;
// Brightness variation per cell on the tops.
uniform float cell_variation : hint_range(0.0, 0.2) = 0.04;
// Darker towards the foot of each column (fake ambient occlusion).
uniform float side_ao : hint_range(0.0, 1.0) = 0.5;
// The pixel row under every top edge catches light.
uniform float rim_light : hint_range(0.0, 1.0) = 0.22;
// Cutaway (walls only, INSTANCE_CUSTOM.a = 1): any wall that hides floor of
// the map behind it dissolves (dithered) above cut_height over that floor,
// like the cut walls of tactics games. map_min / map_max = map rect (xz).
uniform vec2 map_min = vec2(-1000.0);
uniform vec2 map_max = vec2(-999.0);
uniform float floor_y = 0.0;
uniform float cut_height = 0.75;

varying vec3 world_pos;
varying vec3 world_normal;
varying float top_layer;
varying float side_layer;
varying float lip_px;
varying vec3 tint;
varying float column_top;
varying float cuttable;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	top_layer = floor(INSTANCE_CUSTOM.r * 255.0 + 0.5);
	side_layer = floor(INSTANCE_CUSTOM.g * 255.0 + 0.5);
	lip_px = floor(INSTANCE_CUSTOM.b * 32.0 + 0.5);
	tint = COLOR.rgb;
	column_top = (MODEL_MATRIX * vec4(0.0, 0.5, 0.0, 1.0)).y;
	cuttable = INSTANCE_CUSTOM.a;
}

float bayer(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[y * 4 + x]) + 0.5) / 16.0;
}

void fragment() {
	float ppu = pixels_per_unit;
	if (cuttable > 0.5) {
		vec3 view = normalize(world_pos - CAMERA_POSITION_WORLD);
		float t = (floor_y - world_pos.y) / min(view.y, -0.01);
		vec2 ground = (world_pos + view * t).xz;
		bool hides_floor = all(greaterThan(ground, map_min)) && all(lessThan(ground, map_max));
		float above = world_pos.y - (floor_y + cut_height);
		if (hides_floor && above > 0.0 && clamp(above / 0.35, 0.0, 1.0) > bayer(floor(FRAGCOORD.xy / 2.0))) {
			discard;
		}
	}
	if (world_normal.y > 0.5) {
		vec2 p = world_pos.xz + 0.5;
		vec2 cell = floor(p);
		vec3 base = texture(layers, vec3(p, top_layer)).rgb;
		base *= 1.0 + (hash(cell) - 0.5) * 2.0 * cell_variation;
		// One-pixel grid line on the cell border.
		vec2 px = floor(fract(p) * ppu);
		float border = (px.x < 0.5 || px.y < 0.5) ? 1.0 : 0.0;
		base *= 1.0 - border * grid_darken;
		ALBEDO = base * tint;
	} else {
		// Side: u runs along the face, v goes down from the column top.
		float along = abs(world_normal.z) > 0.5 ? world_pos.x : world_pos.z;
		float depth = column_top - world_pos.y;
		float depth_px = floor(depth * ppu);
		float u_px = floor((along + 0.5) * ppu);
		// The top material hangs over the edge with a jagged pixel profile.
		float jag = floor(hash(vec2(u_px, top_layer)) * 2.5) + (mod(u_px, 5.0) < 1.0 ? 1.0 : 0.0);
		vec3 color;
		if (lip_px > 0.0 && depth_px < lip_px + jag) {
			color = texture(layers, vec3(along + 0.5, depth, top_layer)).rgb * 0.88;
		} else if (lip_px > 0.0 && depth_px < lip_px + jag + 1.0) {
			color = texture(layers, vec3(along + 0.5, -world_pos.y, side_layer)).rgb * 0.55;
		} else {
			color = texture(layers, vec3(along + 0.5, -world_pos.y, side_layer)).rgb;
		}
		// Light catching on the edge, darker at the foot.
		color *= 1.0 + (depth_px < 1.0 ? rim_light : 0.0);
		color *= 1.0 - side_ao * clamp(depth * 0.45, 0.0, 1.0);
		ALBEDO = color * tint;
	}
}
