class_name ViewWindow
## Map-wide drawings (the street, the polder, the skyline) only draw what's
## near the camera: everything else would still cost a draw call every frame
## (a canvas item that spans the whole map is never culled). A drawing keeps
## the range it drew (in its own local x) and redraws when the camera gets
## close to that range's edge. In the editor everything is drawn.

const MARGIN := 1.0                         # screens drawn beyond either side of the view
const SLACK := 0.4                          # redraw once the view is this close (in screens) to the drawn range's edge


## The local x range to draw for `ci` now: the camera's view, MARGIN screens wider.
static func range_for(ci: Node2D, margin := MARGIN) -> Vector2:
	var cam := ci.get_viewport().get_camera_2d() if ci.is_inside_tree() and not Engine.is_editor_hint() else null
	if cam == null:
		return Vector2(-INF, INF)
	var half := ScreenFit.width(ci) / 2.0 / cam.zoom.x
	var cx := cam.get_screen_center_position().x
	var a := ci.to_local(Vector2(cx - half * (1.0 + 2.0 * margin), 0.0)).x
	var b := ci.to_local(Vector2(cx + half * (1.0 + 2.0 * margin), 0.0)).x
	return Vector2(minf(a, b), maxf(a, b))


## True when the camera's view has come within SLACK screens of `drawn`'s edge.
static func stale(ci: Node2D, drawn: Vector2) -> bool:
	var now := range_for(ci, SLACK)
	return now.x < drawn.x or now.y > drawn.y


static func overlaps(win: Vector2, x: float, w := 0.0) -> bool:
	return x + w >= win.x and x <= win.y
