// Canal / ditch water, Kingdom-style: a soft mirror of the street side in
// its own colours (a little blurred, darker and tinted toward the water with
// distance), slow rolling ripples, soft glints and troughs that fade in and
// out, the sky mirrored above the top of the screen, a dark line at the quay;
// at night warm lights stay gold. Everything is anchored to the world and
// moves smoothly (no pixel snapping, no palette snap), so it never flickers
// when the camera moves. The mirror starts at the street line (skip_rows).
// WorldWater sets the waterline, the pixel scale, the world x and the night.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
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
uniform float world_left = 0.0;           // world x of the screen's left edge (keeps ripples in place)
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
	float row = floor(dy / px.y / px_per_world);                  // world rows below the line (stable)
	float wxf = SCREEN_UV.x / px.x / px_per_world + world_left;   // world x, anchored to the world
	float depth = clamp(row / depth_rows, 0.0, 1.0);
	float t = TIME;
	// Slow rolling ripples, smooth (sub-pixel) and anchored to the world, so
	// nothing swims or pops when the camera moves.
	float w1 = sin(row * 0.45 + t * 1.1);
	float w2 = sin(row * 0.19 - t * 0.7 + 1.7);
	float sway = (w1 * 0.6 + w2 * 0.4) * (0.3 + depth * 1.8) * ripple;
	float src_row = floor(floor(row / 2.0) * 2.0 * squash) + 1.0 + skip_rows;   // rows in pairs: calm
	vec2 ruv = vec2(SCREEN_UV.x + sway * px_per_world * px.x, water_top_uv - (src_row - 0.5) * px_per_world * px.y);
	ruv.y = max(ruv.y, px.y * 0.5);                               // above the screen: the sky's top row
	// A soft mirror: five samples across (a little blur), not a sharp copy.
	vec2 dx = vec2(px_per_world * px.x, 0.0);
	vec3 s = (texture(screen_tex, ruv).rgb * 3.0
		+ (texture(screen_tex, ruv - dx).rgb + texture(screen_tex, ruv + dx).rgb) * 2.0
		+ texture(screen_tex, ruv - dx * 2.0).rgb + texture(screen_tex, ruv + dx * 2.0).rgb) / 9.0;
	// Mirror in its own colours, darker and bluer with distance.
	vec3 water = mix(water_color.rgb, deep_color.rgb, depth);
	vec3 c = mix(s * 0.9, water, mix(tint_near, tint_far, depth));
	// Soft glints on the crests and darker troughs: short world-anchored dashes
	// that drift slowly and fade in and out (never switch on and off).
	float crest = cos(row * 0.45 + t * 1.1);
	float dir = mod(row, 2.0) * 2.0 - 1.0;
	float len = 10.0 + depth * 16.0;
	float pos = wxf + t * (2.0 + depth * 3.0) * dir;
	float seg = floor(pos / len);
	float h = hash(vec2(seg, row));
	float inside = smoothstep(0.0, 2.0, mod(pos, len)) * smoothstep(len * 0.6, len * 0.6 - 2.0, mod(pos, len));
	if (row > 3.0) {
		c = mix(c, highlight.rgb, 0.3 * smoothstep(0.8, 1.0, crest) * step(0.75, h) * inside);
		c = mix(c, deep_color.rgb, 0.25 * smoothstep(-0.8, -1.0, crest) * step(0.6, h) * inside);
	}
	// At night warm lights (windows, lamps) stay gold and bright.
	float lum = dot(s, vec3(0.30, 0.59, 0.11));
	float warm = smoothstep(0.45, 0.6, lum) * smoothstep(0.12, 0.25, s.r - s.b);
	c = mix(c, lum > 0.7 ? O3 : O2, 0.75 * night * warm);
	// The dark line along the quay.
	if (row < 1.0) {
		c = T0;
	} else if (row < 2.5) {
		c = mix(c, T1, 0.6);
	}
	COLOR = vec4(c, 1.0);                                      // no palette snap: it made blends flicker
}
