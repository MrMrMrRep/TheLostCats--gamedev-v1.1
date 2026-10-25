// Canal / ditch water in the style v3 look (docs/art/style_v3_*, the mocks'
// _reflect): a live mirror of the street side, squashed a little and swaying
// in bands, painted on a few water colours by brightness (greens stay olive,
// warm colours go brick, the rest teal), a dark line at the quay, and light
// dashes on the ripples that drift slowly. At night bright warm lights
// (windows, lamps) reflect as gold. WorldWater sets the waterline and the
// screen-pixels-per-world-pixel scale every frame.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec4 water_color : source_color = vec4(0.208, 0.376, 0.424, 1.0);
uniform vec4 deep_color : source_color = vec4(0.173, 0.255, 0.322, 1.0);
uniform vec4 highlight : source_color = vec4(0.525, 0.757, 0.733, 1.0);
uniform float water_top_uv = 0.8;           // waterline, 0..1 of the screen height
uniform float px_per_world = 2.0;           // screen pixels per world pixel
uniform float night = 0.0;                  // 0 by day .. 1 at night
uniform float depth_rows = 90.0;            // world rows over which the water darkens

const vec3 T0 = vec3(0.114, 0.157, 0.220);
const vec3 T1 = vec3(0.173, 0.255, 0.322);
const vec3 T2 = vec3(0.208, 0.376, 0.424);
const vec3 T3 = vec3(0.294, 0.506, 0.537);
const vec3 T4 = vec3(0.392, 0.635, 0.651);
const vec3 T6 = vec3(0.690, 0.863, 0.788);
const vec3 G0 = vec3(0.169, 0.267, 0.204);
const vec3 G1 = vec3(0.275, 0.400, 0.227);
const vec3 B0 = vec3(0.369, 0.180, 0.212);
const vec3 B1 = vec3(0.561, 0.247, 0.251);
const vec3 B2 = vec3(0.741, 0.353, 0.294);
const vec3 O1 = vec3(0.878, 0.541, 0.212);
const vec3 O2 = vec3(0.949, 0.737, 0.345);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 ramp(int i, int kind) {
	if (kind == 1) {                        // greens
		return i == 0 ? T0 : (i == 1 ? T1 : (i == 2 ? G0 : G1));
	}
	if (kind == 2) {                        // warm
		return i == 0 ? T0 : (i <= 2 ? T1 : (i == 3 ? B0 : B1));
	}
	if (kind == 3) {                        // lights at night
		return i <= 1 ? B1 : (i == 2 ? B2 : (i == 3 ? O1 : O2));
	}
	return i == 0 ? T0 : (i == 1 ? T1 : (i == 2 ? T2 : (i == 3 ? T3 : T4)));
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	float dy = max(SCREEN_UV.y - water_top_uv, 0.0);
	float row = floor(dy / px.y / px_per_world);                  // world rows below the line
	float wx = floor(SCREEN_UV.x / px.x / px_per_world);          // world px across the screen
	float depth = clamp(row / depth_rows, 0.0, 1.0);
	float t = floor(TIME * 3.0);
	// Sway in bands of two rows, more with depth.
	float band = floor(row / 2.0);
	float sway = floor(sin(band * 1.7 + t * 0.45) * (1.0 + depth * 3.0) + 0.5);
	// Mirror, squashed to 0.9.
	float src_row = floor(row * 0.9) + 1.0;
	vec2 ruv = vec2((wx + sway + 0.5) * px_per_world * px.x, water_top_uv - src_row * px_per_world * px.y);
	vec3 s = water_color.rgb;
	if (ruv.y > 0.0) {
		vec2 d = vec2(px_per_world * px.x * 0.5, 0.0);
		s = (texture(screen_tex, ruv - d).rgb + texture(screen_tex, ruv + d).rgb) * 0.5;
	}
	float lum = dot(s, vec3(0.30, 0.59, 0.11));
	int kind = 0;
	if (s.g > s.r + 0.05 && s.g > s.b + 0.05) {
		kind = 1;
	} else if (s.r > s.b + 0.15 && s.r > s.g + 0.1) {
		kind = 2;
	}
	if (night > 0.05 && lum > 0.5 && s.r > s.b + 0.2) {
		kind = 3;
	}
	int idx = int(clamp(floor(lum * 5.0 - depth * 0.9 - 0.5), 0.0, 4.0));
	vec3 c = ramp(idx, kind);
	// Light dashes on the ripples, longer further out, drifting sideways.
	float cell = 22.0;
	float off = hash(vec2(row, 3.0)) * cell + floor(TIME * 2.0) * (mod(row, 2.0) * 2.0 - 1.0);
	float seg = floor((wx + off) / cell);
	float lx = mod(wx + off, cell);
	float h = hash(vec2(seg, row));
	float len = 1.5 + depth * 12.0;
	if (row > 2.0 && h > 0.86 && lx < len) {
		c = hash(vec2(row, seg)) < 0.55 ? T3 : T4;
		if (h > 0.96 && lx > 1.0 && lx < len - 1.0) {
			c = T6;
		}
	}
	// The dark line along the quay.
	if (row < 1.0) {
		c = T0;
	} else if (row < 2.5) {
		c = T1;
	}
	COLOR = vec4(c, 1.0);
}
