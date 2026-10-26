class_name WorldColorGrade
extends CanvasLayer
## The world map's colour grade (shaders/color_grade.gdshader): the palette's
## teal sky, haze and water pulled towards a clear azure, like the reference
## street scene. Sits over the world and under the HUD. Tune it live in the
## shader's uniforms (strength 0 turns it off).

const SHADER := preload("res://shaders/color_grade.gdshader")


static func attach(parent: Node) -> CanvasLayer:
	var g: CanvasLayer = load("res://scripts/world/color_grade.gd").new()
	g.name = "ColorGrade"
	parent.add_child(g)
	return g


func _ready() -> void:
	layer = 30                              # over the world, under the night fade (35) and the HUD (40)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	rect.material = mat
	add_child(rect)
