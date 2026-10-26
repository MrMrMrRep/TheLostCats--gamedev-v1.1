// The palette filter: snaps everything a world node draws to the 32 colours of
// the world palette (WorldPalette, docs/art/style_v2_palette.png), like the
// style mocks' final quantize. One lookup in a 1024x32 table baked by
// V3Painter.palette_lut (x = b * 32 + r, y = g, 5 bits per channel).
// Alpha stays; the night tint (CanvasModulate) is applied after this.
shader_type canvas_item;

uniform sampler2D lut : filter_nearest;

void fragment() {
	vec4 c = COLOR;                          // already texture * modulate in Godot 4 (sampling again squared it: far too dark)
	ivec3 q = ivec3(clamp(floor(c.rgb * 31.0 + 0.5), vec3(0.0), vec3(31.0)));
	COLOR = vec4(texelFetch(lut, ivec2(q.b * 32 + q.r, q.g), 0).rgb, c.a);
}
