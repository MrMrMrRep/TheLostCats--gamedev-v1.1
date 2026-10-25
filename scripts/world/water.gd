@tool
class_name WorldWater
extends ColorRect
## A strip of water on the world map (canal in town, ditch outside) using the
## live reflection shader. Keeps the shader's waterline and pixel scale in step
## with the camera every frame. The rect's top edge is the waterline.

const SHADER := preload("res://shaders/water_reflection.gdshader")

@export var water_color := WorldPalette.WATER:
	set(value):
		water_color = value
		_apply()
@export var deep_color := WorldPalette.WATER_DEEP:
	set(value):
		deep_color = value
		_apply()
@export var street_gap := 36.0:             ## world px from the waterline up to the street (mirrored from there)
	set(value):
		street_gap = value
		_apply()

var _mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = water_color
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	_apply()


func _apply() -> void:
	color = water_color
	if _mat:
		_mat.set_shader_parameter("water_color", water_color)
		_mat.set_shader_parameter("deep_color", deep_color)
		_mat.set_shader_parameter("highlight", WorldPalette.WATER_HI)
		_mat.set_shader_parameter("skip_rows", street_gap)
		if WorldPalette.V3 and not Engine.is_editor_hint():   # snap the mirror to the 32 colours
			_mat.set_shader_parameter("lut", WorldPalette.snap_material().get_shader_parameter("lut"))
			_mat.set_shader_parameter("use_lut", true)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _mat == null:
		return
	var vp := get_viewport()
	var final := vp.get_final_transform()                 # viewport -> window (stretch)
	var canvas := get_global_transform_with_canvas()      # world -> viewport (camera)
	var top_on_screen := (final * canvas * Vector2.ZERO).y
	var screen_h := float(get_window().size.y) if get_window() else 360.0
	_mat.set_shader_parameter("water_top_uv", top_on_screen / screen_h)
	_mat.set_shader_parameter("px_per_world", maxf(final.get_scale().y * canvas.get_scale().y, 0.25))
	_mat.set_shader_parameter("night", WorldDayCycle.night_now)
