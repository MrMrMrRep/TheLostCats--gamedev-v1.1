// World-map colour grade: turns the palette's teal (sky, haze, water, teal
// facades) towards a clear azure, like the reference street scene
// (docs/art-style.md, "Colour grade"). Only hues inside the teal band move,
// so brick, wood, greens, skin and the band's colours stay as they are. Each
// palette colour maps to exactly one new colour, so the pixel art stays crisp.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float centre_hue : hint_range(0.0, 360.0) = 178.0;   // middle of the band that moves (degrees)
uniform float band_width : hint_range(1.0, 90.0) = 34.0;     // half width of the band (degrees)
uniform float hue_shift : hint_range(-60.0, 60.0) = 22.0;    // degrees towards blue
uniform float saturation : hint_range(0.0, 2.0) = 1.25;      // saturation in the band
uniform float lift : hint_range(-0.2, 0.2) = 0.02;           // a touch brighter in the band

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 src = texture(screen, SCREEN_UV);
	vec3 hsv = rgb2hsv(src.rgb);
	float h = hsv.x * 360.0;
	float d = abs(mod(h - centre_hue + 180.0, 360.0) - 180.0);
	float w = (1.0 - smoothstep(band_width * 0.6, band_width, d)) * strength;
	w *= smoothstep(0.04, 0.12, hsv.y);          // greys stay grey
	float light = smoothstep(0.3, 0.75, hsv.z);  // the sky and haze move most; dark teal facades and water less
	hsv.x = fract((h + hue_shift * w * mix(0.45, 1.0, light)) / 360.0);
	hsv.y = clamp(hsv.y * mix(1.0, saturation, w * light), 0.0, 1.0);
	hsv.z = clamp(hsv.z + lift * w, 0.0, 1.0);
	COLOR = vec4(hsv2rgb(hsv), 1.0);
}
