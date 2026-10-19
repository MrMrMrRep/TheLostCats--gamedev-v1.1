# Version 1 — Plan & Checklist

**Goal of v1:** a playable *vertical slice* that proves (1) the Celeste-style controls feel good for all 5 band members, (2) the co-op ability puzzles are fun, and (3) the calm world map and the tense levels are in balance.
It doesn't need to look final. It needs to *play* right.

Engine: Summer Engine (Godot 4.7), GDScript. Assets: `public/assets/amwoods/` (stand-ins).
Design decisions come from [`gdd-review.md`](gdd-review.md) (§2 fixes, §4 values).

---

## Scope

### In v1
- **World map (hand-built, ~6 screens wide, left and right of center):** band studio/storage (center, spawn), city strip on both sides with 1 shop, van parking, 1 venue door ("Café De Kat", club level), 1 service station (decor only), map edges blocked by "Road closed" signs.
- **Vehicles:** bike (short distance, stops anywhere) and band van (fast, gets in/out only at parking spots).
- **1 NPC questline:** Geordie (tour manager) at the studio → "Get to Café De Kat for soundcheck… and where is Geoff?" → level → back to Geordie → "Tour day 1 complete".
- **1 level with 4 rooms** + finale room "Find Geoff". Each room teaches or combines abilities.
- **All 5 members playable**, switching with Tab/Q/E and 1–5, plus Gather.
- **One core ability per member** (gating matrix in the review, §3.2) + shared drink rule (beer).
- **Celeste controller** with the full feel kit, per-member `MovementProfile`.
- **Shared stamina component** + bar under the HP bar.
- **HP 3 (Geoff 1), i-frames, death → room resets to checkpoint.**
- **Hazards:** spikes, pits, electric floor, 1 enemy type (rat, walks back and forth) + 1 human blocker (bouncer, Geoff persuades him).
- **Solid + one-way platforms**, doors (world ↔ level, room ↔ room), keycard door.
- **Items:** beer, keycard, rolling papers (Geoff lure). 3 slots per member + Give.
- **Camera:** deadzone, look-ahead, room bounds, zoom 1× (map) / 2× (rooms), tween on switch and door.
- **Pace & juice:** two music loops with crossfade, dust, squash/stretch, hit-stop, screen shake, placeholder SFX.
- **End-of-level screen:** Finished / Completed (NPCs talked to x/y).
- **Pause menu** (resume, restart room, quit) and a simple title screen.

### Not in v1 (later versions)
Procedural map, day/night and police, money/fans/merch economy, studio and van upgrades, shops that sell, festival/stadium/harbor, Whiskey/Joint rage modes, traps (Joep), cable bridge (Nikki), Karl/Beth/Frank/Gwinny, hard mode, save system, final band sprites, controller rebinding.

> Note: the Nikki cable bridge and Joep's traps are left out of v1 to keep it small. If you'd rather have them in, they fit in milestone M6.

---

## Milestones

Each milestone ends with a **playtest in the running game** (not just "the code compiles") and a git commit.

### M0 — Project setup
- [x] Pixel settings: viewport 640×360, integer scale, default texture filter **Nearest**, snap 2D transforms/vertices to pixel
- [x] Remove/ignore the `[dotnet]` section and use GDScript only
- [x] Folder structure: `scenes/{world,levels,rooms,characters,ui,props,dev}`, `scripts/{autoload,characters,components}`, `resources/{config,profiles,items,sprites,tiles}`, `audio/{music,sfx}`, `tools/`
- [x] Input map (see below): move L/R/U/D, jump, action A, action B (drink), interact/talk, give, switch prev/next, select 1–5, gather, pause. Keyboard + gamepad
- [x] Autoloads + `default_bus_layout.tres` (Music, SFX): `Game` (state, current member, quest flags), `SceneRouter` (door transitions + fade), `Audio` (music crossfade)
- [x] Physics layers named: world, one_way, player, enemy, hazard, interactable, pushable

### M1 — Assets index (GDD step 1)
- [x] Verify the tileset tile size (**confirmed 24 px**, 21×15 grid) and atlas regions (ground top, ground fill, platforms, slopes, walls)
- [x] `public/assets/amwoods/assets.json`: every file with path, size, type (`background|tileset|spritesheet|decoration`), and for spritesheets: frame size 56×56, columns, animations `{name, row, frames, fps, loop}`; for `shop_anim`: 6 × 118×128
- [x] `SpriteFrames` resource for `char_blue` built from the json (idle, run, jump, fall, attack, hurt, death)
- [x] `TileSet` resource with collision on solid tiles and one-way on platform tiles
- [x] Rebuild script `tools/build_asset_resources.gd` (assets.json → .tres) + preview scene `scenes/dev/asset_preview.tscn`
- [x] **Done when:** both resources load in the editor and the animations play ✅ (verified in a game run: 0 errors, 0 warnings)

### M2 — Baseline scene (GDD step 2)
- [x] `Parallax2D` × 3 with background layers 1–3 (scroll factors 0.2 / 0.5 / 0.8), repeating horizontally
- [x] `TileMapLayer` flat ground across the scene (60 tiles wide), side walls, a 1- and 2-tile step and two one-way platforms for testing
- [x] Player: `CharacterBody2D` + `AnimatedSprite2D` + collision, run/jump, animation state (idle/run/jump_start/jump/fall/land), flips with direction
- [x] Gravity and jump speed derived from jump height (3 tiles) and time to apex (0.34 s), exact at any frame rate
- [x] `Camera2D` follows the player (zoom 2×, smoothing, clamped to level bounds)
- [x] Headless test `tests/test_baseline_movement.gd` (13 checks: jump height and apex, accel/decel, animations, facing, steps)
- [x] **Done when:** you can run and jump left/right with parallax scrolling and correct animations ✅ (main scene: `scenes/dev/baseline.tscn`)

### M3 — Celeste controller + stamina
- [x] `MovementProfile` resource (speed tiles/s, jump tiles, time-to-apex, …), gravity and jump velocity *derived* from height and apex time. 5 profiles in `resources/profiles/`
- [x] Accel/decel (top speed in 0.08 s), fall gravity ×1.8, coyote 0.1 s, buffer 0.12 s, variable jump cut ×0.45, apex hang, ceiling corner correction 4 px + ledge correction 3 px, max fall speed + fast fall (hold down)
- [x] One-way platforms: land from above, drop through with down + jump
- [x] `StaminaComponent` (node): `max_stamina, current_stamina, regen_rate, regen_delay, is_exhausted`, ground regen bonus, `spend()`, `try_spend()`, signals `stamina_changed`, `exhausted`, `recovered`
- [x] All values in `resources/config/stamina_config.tres` (per-member pools + ability costs) + profiles (from review §4)
- [x] Stamina bar under the active member's name (HUD), only visible when below max or just changed, red while exhausted
- [x] Debug overlay (F3): velocity, on-floor, coyote/buffer timers, stamina, fps
- [x] Test room `scenes/dev/movement_test.tscn` (main scene): ledges 1–4, gaps 1–4, ceiling hole, one-way stack, 3-tile ledge. Keys 1–5 swap the feel per member, hold F4 drains stamina
- [x] Headless test `tests/test_movement_feel.gd` (26 checks)
- [x] **Done when:** a test room with 1–4 tile gaps and ledges feels tight. Short hop vs. full jump is clearly different, and edge jumps and early presses always work ✅ (tests pass; your hands-on feel check is still open)

### M4 — Band / party system
- [x] `BandMember` scene (`scenes/characters/band_member.tscn`) = shared controller + profile + stamina + health (`HealthComponent`). Ability node → M6, inventory → M7
- [x] `Band` scene with 5 members (Joep, Jay, Nikki, The Germ, Geoff), tinted `char_blue`, gold name tag above the active member
- [x] Switch: Tab/Q cycle (wraps), 1–5 direct. Inactive members idle in place, `BandCamera` blends to the new member in 0.25 s
- [x] Gather (**hold G**, changed after M7 playtest): the others in the room walk to the leader in a fixed row while G is held and stop when it's released. They **hop walls, gaps and 1-tile hazards their own jump can clear**, walk down small drops, and wait in front of anything too tall, too wide or deadly (e.g. Geoff and The Germ wait at a 2-tile wall; nobody jumps into the 7-tile pit or onto the electric floor)
- [x] HUD: 5 member cards with portrait, key number, HP pips (Geoff 1), stamina bar under the HP (only when below max), 3 item slots (empty until M7). Active card highlighted
- [x] Both dev rooms use the Band (`scripts/levels/dev_room.gd`). The headless tests check how many checks ran, so a crashed check can't look like a pass
- [x] Headless test `tests/test_band.gd` (20 checks)
- [x] **Done when:** you can play all 5 and see the different speeds and jump heights ✅ (tests pass; your hands-on check is still open)

### M5 — Level framework
- [x] `Level` scene with `Room` nodes: bounds (camera limits), resettable contents. The band spawns in a row at the start, a door or a `Checkpoint` flag
- [x] Doors: room → room with a fade, level exit to another scene (`SceneRouter`, world map in M8), locked door (`unlock()`; keycards wire in with the inventory in M7)
- [x] **Door group rule:** everyone in the room goes along when they all stand within **3 tiles (72 px) horizontally and 1 tile vertically** of the member using the door (`Level.group_radius_tiles` / `group_height_tiles`); otherwise only that member goes. The prompt says "E whole band", "E group of N" or "E <name> alone"
- [x] Split band: the camera shows the active member's room (switching to someone in another room cuts there), gather only calls members in the same room, every room keeps its own checkpoint (entry door or flag)
- [x] Health: 3 HP / Geoff 1, 1 s i-frames + knockback + flashing, 1 s respawn grace
- [x] Hazards: spikes (−1 HP), pit and electric floor (instant death). Electric has `set_enabled()` for Joep's hack (M6)
- [x] Death → paused death animation (0.5 s) → fade → **reset of the dying member's room** (enemies, bouncer, doors, hazards) → the members in that room respawn at its checkpoint with checkpoint HP; members in other rooms stay put → fade in. **~1.22 s measured**
- [x] Enemies: rat (patrol, turns at walls/ledges, hurts on touch, `stun()`/`knockback()`/`defeat()`), bouncer (blocks a doorway, only Geoff talks him aside; basic persuade, full ability in M6)
- [x] Camera: deadzone (16×24 px) + look-ahead (40 px) + switch blend, clamped to room bounds
- [x] Interact prompts (E) and speech lines. Test level `scenes/levels/level_test.tscn` (main scene, 3 rooms)
- [x] Headless test `tests/test_level.gd` (40 checks)
- [x] **Critical-path test** `tests/test_critical_path.gd`: each of the 5 members runs the level alone (running and jumping like a player, no teleports) and must arrive unhurt. Found that Geoff and The Germ couldn't cross the 2-tile spikes, the 3-tile pit or the 3-tile electric floor. Fixed: 1-tile spikes, pit = 1-tile gap + 4-tile island + 1-tile gap, one-way catwalk over the electric floor
- [x] **Done when:** you can die and respawn in every way within 1.5 s without broken state ✅ (tests found and fixed a 0-HP-after-respawn bug)

Not in M5 (placeholders until later): spike, rat and door art is drawn in code; pushables come with Jay in M6, items with M7.

### M6 — Abilities (one core each + drink)
- [x] Ability system: a `MemberAbility` node per member (set on the profile) that hooks into the shared controller (air jump, gravity, horizontal lock, full movement takeover, after-move, damage blocking)
- [x] **Joep:** wall-slide, wall-jump (15 stamina), hold A to grab and climb walls (drains stamina, hops over the top). Hacks panels with E (electric floor off / gates)
- [x] **Jay:** pushes flight cases by walking into them, pulls them while holding A. A next to a member **throws** them ~4.5 tiles up. Otherwise A = **bass wave** (breaks glass/fragile walls 2–4 tiles away, knocks rats back)
- [x] **Nikki:** double jump (+2.2 tiles) and guitar **hover** while holding jump (slow fall, ~2.2 s of stamina; once spent, no hover until she lands)
- [x] **The Germ:** A = punch (rats, wooden crates); A in the air = **ground pound** (cracked floors, wood, rats). Hold B = drumstick **shield** (blocks hits from the front, drains stamina). B + up raises it as a **platform others can stand on**
- [x] **Geoff:** persuades the bouncer (E). A = **bubble**: nearby rats stop, stare and don't bite while it floats
- [x] Breakables as a data table: glass / fragile wall ← Jay's resonance, wood / cracked floor ← The Germ's impact
- [x] Beer: pickups (max 3 per member, shown in the HUD slots), **B drinks** → +1 HP. Joep: quick for 5 s. Nikki: heals members within 2 tiles. *The Germ's B is his shield (GDD), so he drinks through the M7 item key*
- [x] Props: flight case, breakables, gate/bridge, lever, hack panel, beer, bubble (placeholder art drawn in code)
- [x] Test level `scenes/levels/abilities_test.tscn` (main scene): Germ crates → Jay glass + case-step/throw ledge → Joep climb + hack the electric floor → Nikki crosses the pit + lever bridge → Geoff's bouncer → exit. Bonus beer via The Germ's raised shield
- [x] Headless test `tests/test_abilities.gd` (41 checks: every ability, every gate needs the right member, others pass afterwards, nobody dies)
- [x] **Done when:** a test room has one gate that *needs* each member ✅

Not in M6: quiet/stealth part of Joep's beer (nothing listens yet), whiskey/joint rage modes, Nikki's cable bridge and Joep's traps (later versions).

### M7 — Items & inventory
- [x] `ItemData` resource (id, name, description, icon shape/colour, consumable, `only_for`, `lures`). Items: beer, red keycard, rolling papers (`resources/items/`)
- [x] `Inventory` component: 3 slots per member + selected slot. HUD cards show the items, with the active member's selected slot outlined
- [x] `ItemPickup` in rooms (first member with a free slot takes it, "+Beer" float text). **R** uses the current item, **T** next slot, **V** drops (the dropper can't re-grab it for 1 s), **B** still quick-drinks a beer. The Germ drinks with R
- [x] **F** gives the current item to the nearest member within 1 tile
- [x] Keycards: E at a locked door uses the matching card from your inventory, unlocks the door and goes through (prompt "E use keycard"). Opened with a key, the door stays open after a death (no soft-lock)
- [x] Rolling papers: Geoff follows whoever carries them (same room) with the same walking AI as gather (hops what he can clear, e.g. the 1-tile spikes, waits at the 3-tile electric floor), and comes along through a door with the carrier ("E Joep + Geoff")
- [x] Fixed after playtest: the room 3 keycard sat on a solid 3-tile block **in the walking path** (Jay, The Germ and Geoff couldn't reach the red door). It's now on a floating one-way platform you walk under; the critical-path test covers room 3
- [x] Test level: beer in room 1, keycard on a 3-tile ledge in room 3, red door → new room 4 "Backstage" (papers, step, gap, beer, exit). Main scene = `scenes/levels/level_test.tscn`
- [x] Headless test `tests/test_items.gd` (23 checks); critical-path test now also covers room 4
- [x] **Done when:** keycard and beer can be handed over, and Geoff follows the papers through a room ✅

### M8 — World map
- [x] `scenes/world/world_map.tscn` (**main scene**, 3840 px, about 6 screens): road block → west city → **Studio** (Geordie, bikes) → van P → east city → service station + P → venue P → **Café De Kat** → road block. Canal houses, studio and venue fronts drawn in code (placeholder art)
- [x] The band moves as a group: the active member leads, the others trail on the leader's exact path, 16 px apart (jumps included). No switching, no deaths
- [x] **Bikes**: E at the bikes, the whole band rides at 1.6× walking speed; E anywhere to get off, the bikes stay parked there
- [x] **Band van**: 3× walking speed with smooth acceleration; get in/out only at a **P** sign. Where you parked it is remembered across levels
- [x] Doors: Café De Kat → the test level; the service station says "not open yet". Coming out of the level's last door brings you back to the venue
- [x] Packages: +10 coins once (remembered); not collected from inside the van
- [x] Geordie: "!" → dialogue box (typewriter, E advances) → quest "Get to Café De Kat" → after the gig "?" → "Tour day 1 complete!"
- [x] Map HUD: objective + coins + vehicle hint. Camera: zoom 1×, slower follow, look-ahead 80 px walking / 160 px driving. World text full size on the map
- [x] Headless test `tests/test_world.gd` (38 checks)
- [x] **Done when:** you can take the bike or van from the studio to the venue and enter it ✅
- [x] **Art pass** (`docs/art-style.md`): sky + drifting clouds, parallax skyline / back street / polder (turbines, mills, cows, highway), new canal houses, 3 bridges, live canal reflection (`shaders/water_reflection.gdshader`), birds outside town, the black band van sprite. Zoom zones 3× studio, 2× city, 1× van in town, 0.5× outside town. The map is built by `tools/build_world_map.gd`
- [x] **Studio door** → the abilities test level; its exit brings you back to the studio
- [x] **Bigger map (9600 px)**: polder west with a farm (the van waits there), the canal centre twice as long (6 bridges, studio, Café De Kat), outskirts (service station, shopping centre, car parks, self storage) and **the band's storage** at the east end. Houses ~1.3× bigger
- [x] **Storage gate**: locked keypad, Joep hacks it with his phone (gate opens on his hack-complete frame), then it's the door into the abilities level. Coming out of a level puts you back at the door you used. Geordie waits in front of the storage
- [x] **Vehicles**: engine/pedal pull that fades near top speed, coasting with drag, braking by steering back; the van pitches on a spring and puffs exhaust smoke
- [x] **Map 18400 px, softer edges**: west of the centre the old town (churches, market square, bars and little shops), a park and the theatre, hotels; then a highway sweeps in from the distance and joins a long country road (~15 s by van). East of the centre new apartment blocks lead into the industrial outskirts
- [x] **Traffic**: a back lane (behind the band, smaller, hazy; bikes in town) and a front lane outside town (in front of the band, reflected) — you pass and get passed, never bump. Van 2.2x walking speed; the driving zoom eases slowly (~10 s)
- [x] **City detail + scale pass** (`docs/city-layout.md`): city drawn at the band sprites' pixel density, people-based scale for doors/windows/cars, pedestrians at band scale, real-size traffic (car-free centre, parked cars on the ring), houseboats, airport with hotels at the east end
- [x] **Van radio** (R): dummy synth songs on 3 Dutch stations (German ones are ready for Germany), static between channels, station in the HUD
- [x] **Controls review**: E uses the selected item when nothing is near, Esc/P pause with a controls screen, hint bars fixed (abilities are J/K, not A/B). `tests/test_controls.gd` (27 checks) presses the real keys

Not in M8: day/night and police, studio interior and upgrades, shops that sell, fans/merch, procedural map, music (M10).

### M9 — The slice level "Café De Kat"
Blockout with grey tiles first, then dress with the amwoods tileset. One new idea per room, then combine (level-design skill: teach → test → twist).
- [ ] **R1 Back entrance:** movement basics, Nikki double jump/hover, Joep wall-jump. Checkpoint
- [ ] **R2 Storage:** Jay pushes crates and throws The Germ up. The Germ smashes crates. Rats. Beer pickup
- [ ] **R3 Bar & bouncer:** Geoff persuades the bouncer. Electric floor, Joep hacks the fuse box. Keycard behind glass (Jay's bass wave), Give the keycard to the member at the door
- [ ] **R4 Backstage:** combines all of the above. Split the team over two paths
- [ ] **Finale "Where is Geoff?":** Geoff is asleep in the drum case on top of the stage rig. The other four reach him (no Geoff abilities needed), then the rolling papers lure him to the exit
- [ ] Hidden extra NPC (Gwinny) with a faint sound cue, counts for "Completed"
- [ ] End screen: Finished / Completed (NPCs x/y), back to the world map → Geordie completes the quest

### M10 — Pace, audio & juice
- [ ] Two music loops (calm world map / tense level), 1.5 s crossfade on door transitions
- [ ] Zoom tween 1× ↔ 2× on world ↔ level transitions
- [ ] Landing dust, jump puff, squash/stretch on jump/land, hit-stop 60–80 ms on hits, small screen shake on ground-pound/break, particles on breakables
- [ ] Placeholder SFX: jump, land, hit, death, pickup, door, switch member, bass wave, hack, talk blips
- [ ] Title screen + pause menu (resume / restart room / quit)

### M11 — Playtest, tune & balance
- [ ] Run the full slice start → finish without errors in the console
- [ ] Time it: world-map leg **1–3 min**, level **8–15 min**, each room 1.5–3 min
- [ ] Death count per room (target: R1 0–1, R2–R3 1–3, R4/finale 2–5)
- [ ] Each ability used at least once and needed at least once
- [ ] Tune movement profiles and stamina values in the `.tres` files only
- [ ] 2–3 outside players play without help. Note where they get stuck
- [ ] Write `docs/v1-playtest-notes.md` with what to change for v2

---

## Approach (how we'll work)

- **Small steps, one milestone at a time.** I build, run the game, check it with screenshots and runtime probes, then commit. You review before the next milestone. M1 and M2 are exactly the GDD's "do it slowly" steps.
- **Skills per milestone:** M2–M3 `godot-2d-movement`, `celeste-momentum-platforming`, `platformer`. M1 `godot-tilemap`, `godot-animation`, `godot-resources`. M4/M7 `godot-ui-control`, `game-ui-ux`. M5 `camera-systems`, `godot-physics`. M8 `dialogue-systems`. M9 `level-design`. M10 `game-feel`, `audio-design`. M11 `playtesting-a-feature`.
- **Data over code:** all tunable numbers in `.tres` resources, so you can balance without editing scripts.

---

## Controls (set in M0)

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | WASD / arrows | D-pad / left stick |
| Jump | Space / C | A |
| Ability A (punch, wave, throw, grab/climb, bubble) | J / X | X |
| Ability B (drink beer; The Germ: shield, + up = platform) | K / Z | Y |
| Interact / talk / hack; **with nothing to interact with: use the selected item** | E | B |
| Give item | F | Left trigger |
| Use item (in the van: radio channel) | R | Right trigger |
| Next item slot | T | Right stick click |
| Drop item | V | Left stick click |
| Gather band (hold) | G (hold) | Back (hold) |
| Previous / next member | Q / Tab (wraps around) | LB / RB |
| Select member | 1–5 | — |
| Pause (shows the controls) | Esc / P | Start |
| Debug overlay | F3 | — |

## Running the tests

```bash
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/test_baseline_movement.gd
```

```bash
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/test_movement_feel.gd
```

```bash
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/test_band.gd
```

```bash
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/test_level.gd
```

```bash
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/test_critical_path.gd
```

```bash
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/test_abilities.gd
```

```bash
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/test_items.gd
```

```bash
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/test_world.gd
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script res://tests/test_controls.gd
```
