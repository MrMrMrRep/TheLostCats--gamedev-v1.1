@tool
class_name CityBlock
extends Node2D
## A row of Amsterdam canal houses (placeholder art drawn in code): narrow,
## tall, coloured brick with gables and white-framed windows. `seed_value`
## keeps each block's look stable. Origin = street level, left end.

const PALETTE := [Color("6b3a2e"), Color("3e2a24"), Color("5a2e2a"), Color("7a5a3a"),
	Color("2e3a3e"), Color("4a3a5a"), Color("5e4a2e")]

@export var houses := 6:
	set(value):
		houses = value
		queue_redraw()
@export var seed_value := 1:
	set(value):
		seed_value = value
		queue_redraw()
@export var sign_text := "":                ## big sign on the middle house (STUDIO, CAFÉ DE KAT...)
	set(value):
		sign_text = value
		queue_redraw()


func width() -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var w := 0.0
	for i in houses:
		w += rng.randi_range(36, 52)
		rng.randi_range(80, 130)
		rng.randi_range(0, PALETTE.size() - 1)
		rng.randi_range(0, 2)
	return w


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var x := 0.0
	var mid := houses / 2
	for i in houses:
		var w := float(rng.randi_range(36, 52))
		var h := float(rng.randi_range(80, 130))
		var c: Color = PALETTE[rng.randi_range(0, PALETTE.size() - 1)]
		var gable := rng.randi_range(0, 2)
		_house(Vector2(x, 0), w, h, c, gable)
		if sign_text != "" and i == mid:
			draw_rect(Rect2(x + 2, -h + 22, w - 4, 12), Color("1a1418"))
			draw_string(ThemeDB.fallback_font, Vector2(x + 3, -h + 31), sign_text, HORIZONTAL_ALIGNMENT_CENTER, w - 6, 8, Color("ffd36b"))
		x += w


func _house(at: Vector2, w: float, h: float, c: Color, gable: int) -> void:
	draw_rect(Rect2(at.x, at.y - h, w, h), c)
	var top := at.y - h
	match gable:
		0:                                  # step gable
			draw_rect(Rect2(at.x + w * 0.2, top - 8, w * 0.6, 8), c)
			draw_rect(Rect2(at.x + w * 0.35, top - 14, w * 0.3, 6), c)
		1:                                  # bell gable
			draw_colored_polygon(PackedVector2Array([Vector2(at.x + 4, top), Vector2(at.x + w / 2, top - 16), Vector2(at.x + w - 4, top)]), c)
		_:                                  # neck gable
			draw_rect(Rect2(at.x + w * 0.3, top - 12, w * 0.4, 12), c)
	draw_line(Vector2(at.x, top), Vector2(at.x, at.y), c.darkened(0.3), 1.0)
	var rows := int((h - 30) / 22)
	for r in rows:
		for k in 2:
			var wx := at.x + 7 + k * (w - 22) * 0.9
			var wy := top + 10 + r * 22
			draw_rect(Rect2(wx, wy, 8, 12), Color("e8e0c8"))
			draw_rect(Rect2(wx + 1, wy + 1, 6, 10), Color("2a3442") if (r + k) % 3 else Color("e8c878"))
