// Canal / ditch water, Kingdom-style: a near-true mirror of the street side in
// its own colours (darkened, and tinted toward the water colour more with
// distance), rolling ripples (two travelling waves per row plus a small
// vertical shimmer, stronger further out), thin light crests and dark troughs
// that drift as dashes, the sky mirrored above the top of the screen, a dark
// line at the quay. The mirror starts at the street line (skip_rows), so the
// band, the shop fronts and the houses reflect right below the quay. At night warm lights stay bright gold in the water.
// The result is snapped to the 32-colour world palette (the palette filter's
// table) in solid tones; the mirror is a little blurred so it reads soft.
// WorldWater sets the waterline, the pixel scale, the night and the table.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D lut : filter_nearest;     // V3Painter.palette_lut (1024x32)
uniform bool use_lut = false;
uniform vec4 water_color : source_color = vec4(0.208, 0.376, 0.424, 1.0);
uniform vec4 deep_color : source_color = vec4(0.173, 0.255, 0.322, 1.0);
uniform vec4 highlight : source_color = vec4(0.525, 0.757, 0.733, 1.0);
uniform float water_top_uv = 0.8;           // waterline, 0..1 of the screen height
uniform float px_per_world = 2.0;           // screen pixels per world pixel
uniform float night = 0.0;                  // 0 by day .. 1 at night
uniform float depth_rows = 90.0;            // world rows over which the water darkens
uniform float tint_near = 0.42;             // how much water colour shows by the quay
uniform float tint_far = 0.72;              // ... and far out
uniform float squash = 0.94;                // mirror height (1 = exact)
uniform float ripple = 1.0;                 // ripple strength
uniform float skip_rows = 22.0;             // world rows between the waterline and the street (the mirror shows what stands on it)

const vec3 T0 = vec3(0.114, 0.157, 0.220);
const vec3 T1 = vec3(0.173, 0.255, 0.322);
const vec3 T6 = vec3(0.690, 0.863, 0.788);
const vec3 O2 = vec3(0.949, 0.737, 0.345);
const vec3 O3 = vec3(0.973, 0.863, 0.541);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float bayer4(vec2 p) {
	ivec2 i = ivec2(mod(p, 4.0));
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i.y * 4 + i.x]) + 0.5) / 16.0;
}

vec3 snap(vec3 c, vec2 cell) {
	if (!use_lut) {
		return c;
	}
	vec3 d = c * 31.0;                                        // no dither: calm, solid tones
	ivec3 q = ivec3(clamp(floor(d + 0.5), vec3(0.0), vec3(31.0)));
	return texelFetch(lut, ivec2(q.b * 32 + q.r, q.g), 0).rgb;
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	float dy = max(SCREEN_UV.y - water_top_uv, 0.0);
	float row = floor(dy / px.y / px_per_world);                  // world rows below the line
	float wx = floor(SCREEN_UV.x / px.x / px_per_world);          // world px across the screen
	float depth = clamp(row / depth_rows, 0.0, 1.0);
	float t = TIME;
	// Rolling ripples: two waves travelling at different speeds, a fast small one.
	float w1 = sin(row * 0.52 + t * 2.0);
	float w2 = sin(row * 0.21 - t * 1.25 + 1.7);
	float w3 = sin(row * 1.63 + t * 3.6);
	float amp = (0.4 + depth * 2.2) * ripple;
	float sway = floor((w1 * 0.6 + w2 * 0.4) * amp + w3 * 0.25 * depth * ripple + 0.5);
	float shimmer = floor(sin(row * 0.87 + t * 2.6) * (0.3 + depth * 0.8) * ripple + 0.5);
	float src_row = max(floor(floor(row / 2.0) * 2.0 * squash) + 1.0 + shimmer, 1.0) + skip_rows;   // rows in pairs: calmer
	vec2 ruv = vec2((wx + sway + 0.5) * px_per_world * px.x, water_top_uv - (src_row - 0.5) * px_per_world * px.y);
	ruv.y = max(ruv.y, px.y * 0.5);                               // above the screen: the sky's top row
	// A soft mirror: five samples across (a little blur), not a sharp copy.
	vec2 dx = vec2(px_per_world * px.x, 0.0);
	vec3 s = (texture(screen_tex, ruv).rgb * 3.0
		+ (texture(screen_tex, ruv - dx).rgb + texture(screen_tex, ruv + dx).rgb) * 2.0
		+ texture(screen_tex, ruv - dx * 2.0).rgb + texture(screen_tex, ruv + dx * 2.0).rgb) / 9.0;
	// Mirror in its own colours, darker and bluer with distance.
	vec3 water = mix(water_color.rgb, deep_color.rgb, depth);
	vec3 c = mix(s * 0.9, water, mix(tint_near, tint_far, depth));
	// Crests catch the light, troughs go dark: dashes that drift along the rows.
	float crest = cos(row * 0.52 + t * 2.0);
	float dir = mod(row, 2.0) * 2.0 - 1.0;
	float seg = floor((wx + t * (4.0 + depth * 6.0) * dir) / (8.0 + depth * 14.0));
	float h = hash(vec2(seg, row));
	if (row > 3.0 && crest > 0.94 && h > 0.78) {
		c = mix(c, highlight.rgb, 0.35);                          // now and then a soft glint
	} else if (row > 3.0 && crest < -0.94 && h > 0.6) {
		c = mix(c, deep_color.rgb, 0.3);
	}
	// At night warm lights (windows, lamps) stay gold and bright.
	float lum = dot(s, vec3(0.30, 0.59, 0.11));
	if (night > 0.05 && lum > 0.5 && s.r > s.b + 0.2) {
		c = mix(c, lum > 0.7 ? O3 : O2, 0.75 * night);
	}
	// The dark line along the quay.
	if (row < 1.0) {
		c = T0;
	} else if (row < 2.5) {
		c = mix(c, T1, 0.6);
	}
	COLOR = vec4(snap(c, vec2(wx, row)), 1.0);
}
