shader_type canvas_item;
// For a CanvasGroup: draws its children slightly out of focus (a soft
// multi-tap blur over the group's mipmapped buffer), like something close to
// the camera that the lens isn't focused on.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float radius = 3.0;       // screen px
uniform float lod = 1.0;

void fragment() {
	vec4 sum = vec4(0.0);
	float w = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			float k = 1.0 - length(vec2(float(x), float(y))) / 3.2;
			vec2 o = vec2(float(x), float(y)) * radius * 0.5 * SCREEN_PIXEL_SIZE;
			sum += textureLod(screen_tex, SCREEN_UV + o, lod) * k;
			w += k;
		}
	}
	vec4 c = sum / w;
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	COLOR = c;
}
