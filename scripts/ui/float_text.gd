class_name FloatText
extends Node2D
## Short text that floats up and fades ("+Beer", "Unlocked"). spawn() adds it
## to the level at a world position.

const RISE := 14.0
const TIME := 0.9


static func spawn(parent: Node, pos: Vector2, text: String, color := Color.WHITE) -> void:
	var ft := FloatText.new()
	parent.add_child(ft)
	ft.global_position = pos
	ft._show(text, color)


func _show(text: String, color: Color) -> void:
	z_index = 20
	var l := Label.new()
	l.text = text
	l.size = Vector2(200, 12)
	l.scale = Vector2(0.5, 0.5)
	l.position = Vector2(-50, -6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 3)
	add_child(l)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - RISE, TIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, TIME).set_delay(TIME * 0.4)
	tween.chain().tween_callback(queue_free)
