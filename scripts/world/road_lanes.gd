class_name RoadLanes
## The lanes of the band's road from west to east, as tyre lines (world px
## below the street line). Traffic, the van and the street's markings all
## read them here, so every vehicle follows the road:
##   motorway (x < WEST.x, x > EAST.y)  two lanes each way: westbound on the
##        far carriageway, eastbound on the near one (we drive on the right)
##   the city's edges (the hotels and the park; the flats, the industry and the
##        storage)  one lane each way on the asphalt
##   the centre (old town, red light district, canal belt)  one lane on the
##        cobbles, one-way east for cars (bikes ride both ways)
## Where the count changes the lanes taper into each other (WEST, EAST,
## CENTRE_TAPER), so a vehicle on a lane that ends drifts onto the one that
## goes on. LEFT / RIGHT are seen in the driving direction: LEFT is next to
## the median (the overtaking lane), RIGHT next to the verge.

enum Side { LEFT, RIGHT }
enum Section { MOTORWAY, EDGE, CENTRE }

const WEST := Vector2(5600, 6000)           # motorway -> the city's edge: the lanes merge, the median ends
const EAST := Vector2(18706, 19100)         # the city's edge -> motorway
const CENTRE := Vector2(7822, 16436)        # one lane (the old town to the canal belt's end)
const CENTRE_TAPER := 120.0                 # px outside CENTRE where the two lanes come together

# Tyre lines (world px below the street line).
const MW_EAST := [9.0, 19.0]                # near carriageway: LEFT, RIGHT
const MW_WEST := [-4.0, -11.0]              # far carriageway: LEFT, RIGHT
const EDGE_EAST := 21.5                     # the city's edges: the near half of the road
const EDGE_WEST := 15.5                     # ... the far half
const CENTRE_Y := 18.0
const PARK_TOWN := 11.0                     # parked against the far kerb in town
const PARK_ROAD := 24.0                     # on the hard shoulder outside it

# Road bands for the markings (world px): the town road and the motorway's carriageways.
const TOWN_ROAD := Vector2(8.5, 23.0)
const MW_FAR := Vector2(-17.0, -3.0)
const MW_NEAR := Vector2(0.0, 21.0)


## 1 on the motorway, 0 in town, in between along the tapers.
static func motorway_weight(x: float) -> float:
	if x <= WEST.x or x >= EAST.y:
		return 1.0
	if x < WEST.y:
		return 1.0 - smoothstep(WEST.x, WEST.y, x)
	if x > EAST.x:
		return smoothstep(EAST.x, EAST.y, x)
	return 0.0


## 1 in the one-lane centre, 0 elsewhere, in between along its tapers.
static func centre_weight(x: float) -> float:
	if x >= CENTRE.x and x <= CENTRE.y:
		return 1.0
	if x < CENTRE.x:
		return smoothstep(CENTRE.x - CENTRE_TAPER, CENTRE.x, x)
	return 1.0 - smoothstep(CENTRE.y, CENTRE.y + CENTRE_TAPER, x)


static func section(x: float) -> Section:
	if motorway_weight(x) > 0.5:
		return Section.MOTORWAY
	return Section.CENTRE if centre_weight(x) > 0.5 else Section.EDGE


## How many lanes go each way here (the motorway: 2; a lane that's tapering
## away no longer counts).
static func lanes(x: float) -> int:
	return 2 if motorway_weight(x) > 0.75 else 1


## The tyre line of lane `side` for traffic going `dir` (+1 east, -1 west).
static func y(x: float, dir: float, side: int = Side.LEFT) -> float:
	var mw: float = (MW_EAST if dir > 0.0 else MW_WEST)[side]
	var edge := EDGE_EAST if dir > 0.0 else EDGE_WEST
	var town := lerpf(edge, CENTRE_Y, centre_weight(x))
	return lerpf(town, mw, motorway_weight(x))


## Where a parked vehicle stands.
static func park_y(x: float) -> float:
	return lerpf(PARK_TOWN, PARK_ROAD, motorway_weight(x))


## Vehicles further back are drawn a little smaller (the far carriageway).
static func depth_scale(tyre_y: float) -> float:
	return clampf(0.9 + (tyre_y - MW_WEST[1]) / (CENTRE_Y - MW_WEST[1]) * 0.1, 0.9, 1.0)
