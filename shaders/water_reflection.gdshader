// Canal / ditch water with a live reflection of everything above the
// waterline (Kingdom Eighties look): mirrors the screen about the waterline,
// pulls it toward the water colour, jitters rows a little (more with depth,
// animated), and adds moving light streaks. WorldWater sets the waterline and
// the screen-pixels-per-world-pixel scale every frame.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec4 water_color : source_color = vec4(0.169, 0.341, 0.475, 1.0);
uniform vec4 deep_color : source_color = vec4(0.122, 0.251, 0.376, 1.0);
uniform vec4 highlight : source_color = vec4(0.612, 0.769, 0.894, 1.0);
uniform float water_top_uv = 0.8;           // waterline, 0..1 of the screen height
uniform float px_per_world = 2.0;           // screen pixels per world pixel
uniform float tint = 0.42;                  // how much water colour over the reflection

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 suv = SCREEN_UV;
	float dy = max(suv.y - water_top_uv, 0.0);
	float row = floor(dy / SCREEN_PIXEL_SIZE.y / px_per_world);       // world-pixel row below the line
	float t = floor(TIME * 4.0);
	float j = floor(hash(row * 0.37 + floor(row / 2.0) + t * 0.11) * 3.0) - 1.0;   // -1, 0, 1
	float amp = 1.0 + floor(row / 40.0);
	float shift = j * amp * px_per_world * SCREEN_PIXEL_SIZE.x;
	vec2 ruv = vec2(suv.x + shift, water_top_uv - dy - SCREEN_PIXEL_SIZE.y * px_per_world);
	vec4 refl = ruv.y > 0.0 ? texture(screen_tex, ruv) : water_color;
	vec4 c = mix(refl, deep_color, clamp(tint + row * 0.0015, 0.0, 0.9));
	// light streaks drifting slowly to the side
	float wx = floor(suv.x / SCREEN_PIXEL_SIZE.x / px_per_world);
	float seg = floor((wx + floor(TIME * 5.0) * (mod(row, 2.0) * 2.0 - 1.0)) / 7.0);
	float h = hash(seg * 1.31 + row * 7.77);
	if (h > 0.975) {
		c = mix(c, highlight, 0.6);
	} else if (h < 0.012) {
		c = mix(c, deep_color * 0.8, 0.5);
	}
	if (row < 1.0) {
		c = mix(c, highlight, 0.35);        // bright line at the waterline
	}
	COLOR = vec4(c.rgb, 1.0);
}
