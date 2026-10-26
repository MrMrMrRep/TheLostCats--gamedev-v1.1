extends SceneTree
# Cuts square crops (SIDE px, sky-filled) around each chunk of the strip, with
# CTX px of context either side. env: STRIPDIR CHUNKS OUTDIR
const SIDE := 460
const Y0 := 10
const CTX := 20
const SKY := Color("8ec5e6")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var sd := OS.get_environment("STRIPDIR")
	var strip := Image.load_from_file(sd + "/strip.png")
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sd + "/pieces.json"))
	var a0: int = int(meta.a)
	var chunks: Array = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("CHUNKS")))
	for c: Dictionary in chunks:
		var inner: int = int(c.b) - int(c.a)
		var x0: int = int(c.a) - a0 - CTX - (SIDE - inner - 2 * CTX) / 2    # centred
		var crop := Image.create(SIDE, SIDE, false, Image.FORMAT_RGBA8)
		crop.fill(SKY)
		var reg := Image.create(SIDE, SIDE, false, Image.FORMAT_RGBA8)
		reg.blit_rect(strip, Rect2i(x0, Y0, SIDE, SIDE), Vector2i.ZERO)
		crop.blend_rect(reg, Rect2i(0, 0, SIDE, SIDE), Vector2i.ZERO)
		crop.save_png(OS.get_environment("OUTDIR") + "/" + c.id + "_crop.png")
		print("CROP ", c.id, " x0 ", x0)
	quit()
