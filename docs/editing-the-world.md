# Editing the world map

The world map is now a normal scene: `scenes/world/world_map.tscn`. What you
see in Summer is what the game uses. Move things, copy them, delete them,
press Play.

**Rule of thumb:** you place things and tune numbers; code does the drawing
and the behaviour.

> **Can't see the scene tree, the Inspector or the 2D view?** Turn on
> **developer view** in Summer first.

> The old generator `tools/build_world_map.gd` is **retired**. Don't run it:
> it would wipe out all your edits. It refuses to run anyway.

---

## 1. The scene, top to bottom

The top folders are **depth layers**. Things lower in the list are drawn
**in front of** things higher up. Inside most layers there is a folder per
**district**, west to east:

`WestRoad · Viaduct · Hotels · ParkTheater · OldTown · CanalBelt · Flats · Industry · Storage · Airport`

| Folder | What's in it |
|---|---|
| Sky | The sky and clouds (code only, fills the screen in the game) |
| Background | Far scenery that moves slower than the street: skyline, polder, turbines, windmills |
| Bridges | Bridges and side streets with a view down the canal |
| Buildings | Canal houses (CityBlock), hotels, church, market, flats, mall, storage, airport… |
| Road | The motorway ramp (Highway), the street you walk on (Street) and its invisible floor |
| StreetLife | Lamps, benches, bins, bikes along the street, in stretches |
| PeopleBack / TrafficBack | Walkers and cars **behind** the band (code; see Zones) |
| Signs | Speed signs, the fork, the overhead motorway signs (gantries) |
| RoadBlockWest/East | The ends of the map (the van stops here) |
| Places | Things you use: doors, the storage gate, Geordie, Start, bikes, van, P spots, packages |
| Band | The band |
| PeopleFront / TrafficFront | Walkers and cars **in front of** the band |
| Water | Ditch, canal, ditch: the water strips (resize them like boxes) |
| Houseboats | One node per boat |
| Birds, WaterLife… | Birds (code), ducks and boats on the water |
| FrontGround | The viaduct and grass bank in front of the road |
| Canopies | The big tree clumps that hide the joins between districts |
| Foreground | Things very close to the camera (round hotel, big trees), moving faster than the street |
| MapHud, DialogueBox, DevHint | Screen texts |
| Zones | The district stretches (see 4) |
| Markers | The rule lines (see 3) |

To move a piece to another depth, drag it into another layer folder in the
Scene panel. To move it to another district, you only drag it in the view.
The district folders are just for keeping things tidy.

## 2. Moving, copying, adding

- **Move:** drag it in the 2D view. Only left/right matters for most things;
  the street line is at y = 288.
- **Copy:** select it and press Ctrl+D (Cmd+D on Mac), then drag the copy.
  Copies look the same. Change `seed_value` in the Inspector to get a
  different-looking one (other windows, colours, shops).
- **Delete:** select it and press Delete.
- **Add something new:** copy something that's already there. That's easiest.

Useful settings in the Inspector:

| Piece | Settings |
|---|---|
| Canal houses (CityBlock) | `houses` (how many), `style` (canal / old town / ring), `shop_rate`, `shop_signs`, `sign_text`, `seed_value` |
| Big buildings (WorldBuilding) | `kind` (mall, church, hotel, flats, airport…), `sign_text`, `seed_value` |
| Bridge | `width`, `kind` (bridge or side street), `landmark` (the Pontsteiger view) |
| Canopy (tree clump) | `width`, `seed_value` |
| StreetLife stretch | `kind` (district style), `length`, `keep_clear` (gaps for doors) |
| Viaduct / grass bank | `kind`, `length`, `top` |
| Gantry | `signs` ("Place\|Road" per panel) |
| Water strip | Drag its edges like a box |
| Door | `target_scene`, `closed_text`, `sign_text`, `width` |
| P spot (ParkingSpot) | `width` (the van can only stop inside it) |
| Package | `coins` |

**Don't rename these** (code looks for them by name): `Start`, the markers,
`Band`, `MapHud`, `DialogueBox`, `Birds`, `Places`. Copy the van or the bikes
only if you also give the copy its own `save_id` (that's where the game
remembers where it was parked).

## 3. Markers: the rule lines

The coloured vertical lines with a flag (only visible in the editor). Drag
them left/right.

| Marker | What it does |
|---|---|
| **FootLimit** | West of this line is motorway: no walking, no cycling. The band stops here and says so. |
| **ScenicFrom** | West of this line the van's view slowly zooms far out: the road trip. |
| **RoadTransition** | The city street begins here. West of it the street looks like a motorway, cars drive motorway-style and the van keeps to its lane. *Moves the street look with it.* |
| **SpeedLimitStart / SpeedLimitEnd** | Between these the van can't go faster than the city speed (see vehicle config). |
| **TownWest / TownEast** | The town: no birds here, and the background shows the skyline instead of polder. *Moves the background with it.* |
| **CanalStart** | Where the canal water begins. *Moves the canal's left edge with it.* |

The signs that go with them (`Sign50`, `Sign100`) and the tree clumps that
hide the joins (`Canopies`) are normal pieces: move them along by hand.

## 4. Zones: what goes on in each district

The coloured bands just under the street (only visible in the editor), one per
district. Click one to see its settings:

- `length`: how long it is (the orange line is its east end)
- `people_per_screen`: how many walkers you see at once (0 = nobody)
- `bikes_only`: no cars here, only bikes (old town, canal belt)
- `parked_cars`: cars parked along the street

Drag a zone or change its length to move where a district starts or ends.
Zones may touch but shouldn't overlap. Changes show when you press Play.

## 5. People you can talk to (NPCs)

Geordie is in `Places/Storage`. To add someone: copy Geordie, drag the copy,
and in the Inspector:

- turn **off** `tour_quest` (only Geordie gives the tour quest)
- `speaker`: their name in the dialogue box
- `talk_lines`: what they say, one box per line
- `tint`, `sprite_frames`, `face_left`: how they look

## 6. Background layers (parallax)

Background and Foreground move at a different speed than the street. In the
editor they shift along when you scroll, just like in the game. **What you
see in the middle of your screen is what the game shows when the band stands
there.** So: scroll to the spot, then drag the background piece to where it
should be. (Turn off `editor_preview` on the layer if you want it to stand
still.)

## 7. Code-only things

Made by code every frame, so you can't place them one by one:

- **Sky and clouds:** always fill the screen.
- **Walkers and traffic:** where and how many comes from the Zones and the
  traffic/people config files.
- **Birds:** fly over outside town (TownWest/TownEast).
- **Water reflection:** the water strips reflect what's above them.

---

## 8. Tuning numbers (config files)

All in `resources/config/`. Double-click a file, change numbers in the
Inspector, press **Ctrl+S (Cmd+S)**. While the game runs from Summer it picks
up the change within a second; otherwise press Play again.

Speeds are in **pixels per second** (the band walks 85; a canal house is about
60 px wide). Zoom: higher = closer (3 = very close, 1 = normal, 0.5 = far).

### vehicle_config.tres: bikes and van
| Value | Now | Meaning |
|---|---|---|
| bikes_top_speed | 150 | Bikes at full speed |
| van_top_speed | 295 | Van on the open road |
| city_speed | 190 | Van's limit between the SpeedLimit markers |
| *_pull | 420 / 240 | How hard it speeds up from standstill |
| *_brake | 520 | How hard it brakes when you steer the other way |
| *_rolling, *_drag | 60, 0.3 / 34, 0.12 | How quickly it rolls to a stop when you let go |
| skid_from | 60 | Braking faster than this: the van skids (smoke, marks) |
| pitch_* | | How much the van body tilts and bounces |
| lane_east / lane_west | 4 / -5 | Van's height on the motorway heading in / out of the city |

### map_camera_config.tres: the world map camera
| Value | Now | Meaning |
|---|---|---|
| zoom_walk / zoom_walk_moving | 3.0 / 2.4 | Standing / walking at full pace |
| zoom_bike_slow / zoom_bike | 2.6 / 2.0 | On the bikes, slow / fast |
| zoom_van_slow / zoom_van | 1.7 / 1.3 | Van parked / at speed |
| zoom_road | 0.5 | The road trip (west of ScenicFrom) |
| zoom_out_rate / zoom_in_rate | 1.1 / 0.28 | How fast the zoom changes |
| tempo_settle | 2.5 | Seconds before the zoom calms down after slowing |
| idle_after, zoom_idle, drift_* | 15 s, 1.5 | Standing still a while: the camera slowly wanders out and sways |
| focus_cap, fit_margin, focus_lead | 170, 80, 34 | How the shot frames the group |
| walk_look_ahead / drive_look_ahead | 80 / 160 | How far the view leads ahead |
| water_share, water_min, water_max | 0.13, 22, 160 | How much canal shows under the street |

### band_map_config.tres: the band walking on the map
| Value | Now | Meaning |
|---|---|---|
| walk_speed | 85 | Walking speed on the map |
| walk_gap | 26 | Distance between members |
| catch_up, jog_factor | 90, 1.9 | When someone is this far behind they jog, at this speed |
| sprint_factor | 2 | Holding left Shift on the map: everyone moves this many times faster |
| pause_every, pause_length | 5–12 s, 0.4–1.3 s | Little stops (a look around, a sip) |
| fidget_after | 2.5–7 s | Standing still: they start smoking, drinking, playing |
| ride_gap | 30 | On the bikes: distance between riders (a loose group, like walking) |
| ride_sway, ride_catch_up, ride_sprint, ride_follow | 10, 120, 1.2, 1.4 | How loosely they ride, when they pedal hard to catch up, how firmly they keep their spot |

### traffic_config.tres: cars and bikes on the road
How many vehicles per screen (motorway / town), speeds per kind of vehicle,
how much slower they drive in town, the mix of bikes, buses, vans and trucks,
and how full the parking lanes are.

### people_config.tres: walkers
`busy_scale` (more or fewer people everywhere), walking speeds, share of
kids, how often someone stops to look in a window.

### Jumping, running in levels: `resources/profiles/<member>.tres`
One file per band member (geoff, germ, jay, joep, nikki), grouped in the
Inspector: **Run** (speed, how fast they start and stop), **Jump** (height,
time to the top, fall speed), **Forgiveness** (coyote time, jump buffer,
corner help). These are for the levels; on the map everyone walks at
`walk_speed`.

### day_config.tres: day and night
The clock starts at **08:00** and runs only on the world map. It shows
top right under the coins. A full day now takes 15 real minutes.

| Value | Now | Meaning |
|---|---|---|
| start_hour | 8 | Clock time when a new game starts |
| clock_runs | on | Off: time stands still (handy while building) |
| night_minutes | 3 | Real minutes from 22:00 to 05:00 |
| dawn_minutes | 1 | 05:00 to 07:00 |
| morning_minutes | 4 | 07:00 to 12:00 |
| afternoon_minutes | 4 | 12:00 to 17:00 |
| evening_minutes | 2 | 17:00 to 20:00 (golden hour) |
| dusk_minutes | 1 | 20:00 to 22:00 |
| *_starts | | When each part begins (clock hour), if you want to shift them |
| lights_on_from / lights_full_at | 19 / 21 | Street lights and windows come on one by one |
| lights_dim_from / lights_off_at | 5.5 / 7 | ...and go off again in the morning |
| night_windows | 0.55 | How many windows are lit deep in the night |
| world_tint, sky_top/mid/low | | The colours over the day (click a gradient to edit: left = midnight, middle = noon) |

While testing: click **+1 / +4 / +8** under the clock to sleep that many
hours (the screen fades to black and you wake up later), or press **N** to
jump an hour ahead (Shift+N back). Turn off `time_buttons` to hide the
buttons; `sleep_fade` sets how slowly the screen fades.

**Lights you can place:**
- `WorldLight`: a glow that comes on at night, with an optional pool of
  light on the street. Put one on a lantern, a sign or a doorway.
  Settings: `radius`, `color`, `pool`, `comes_on` (0 = first at dusk, higher
  = later in the night).
- `WorldLampRow`: a row of motorway lamp posts. Two are already in
  `Signs` (MotorwayLampsWest, MotorwayLampsEast). Settings: `length`,
  `spacing`, `height`.

House windows, street lamps, cars and the van light up by themselves.

### Stamina: `resources/config/stamina_config.tres`
Per member and per ability.

---

## 9. The base (the band's storage)

`scenes/levels/base.tscn`: one room, entered through the storage gate on the
map (after Joep's hack). The whole band hangs out here.

- **Party board** ("TOUR", on the wall): E opens *Who goes out?*. Press 1–5
  or click to choose who comes along, then E. Only the chosen members show up
  on the world map and go into levels from there. On the map, **Tab / Q /
  1–5** switch who you control (on foot).
- **Furniture** (`BaseProp`): couch, fridge, beer crate, rug, lamp, posters,
  drums, amps with guitar and bass, keys, mic. Pick the `kind`, drag it,
  copy it.
- **Upgrades:** each piece has `min_base_level`. It only shows once the base
  is at that level (`Game.base_level`, 1 for now). Example: `PosterTour` is
  level 2. Later, upgrades can raise the base level.

## 10. Music, sounds and game feel

- **Music:** calm on the map, in the base and on the title screen
  (`audio/music/map_calm.wav`), tense in levels (`level_tense.wav`). Both
  loop.
- **Sounds** in `audio/sfx/`: jump, land, hit, death, pickup, coin, door,
  switch, bass, hack, lever, break, pound, punch, squeak, talk, sleep.
- These are simple placeholder chiptunes made by `tools/make_audio.py`. To
  use your own, put a `.wav` (or `.ogg`) with the **same name** in the same
  folder.
- **Game feel:** a puff of dust when you jump or land (bigger on hard
  landings), a quick squash and stretch, a short freeze when you get hit or
  hit a rat, and screen shake on the Germ's ground pound, breaking things and
  getting hurt.
