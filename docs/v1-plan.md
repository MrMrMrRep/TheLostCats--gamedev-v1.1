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
- [ ] `Parallax2D` × 3 with background layers 1–3 (scroll factors ~0.2 / 0.5 / 0.8), repeating horizontally
- [ ] `TileMapLayer` flat ground across the scene
- [ ] Player: `CharacterBody2D` + `AnimatedSprite2D` + collision, basic run/jump, animation state (idle/run/jump/fall), flips with direction
- [ ] `Camera2D` follows the player
- [ ] **Done when:** you can run and jump left/right with parallax scrolling and correct animations

### M3 — Celeste controller + stamina
- [ ] `MovementProfile` resource (speed tiles/s, jump tiles, time-to-apex, …), gravity and jump velocity *derived* from height and apex time
- [ ] Accel/decel (top speed in 0.05–0.1 s), fall gravity ×1.8, coyote 0.1 s, buffer 0.12 s, variable jump cut ×0.45, apex hang, corner correction 2 px, max fall speed
- [ ] One-way platforms: land from above, drop through with down + jump
- [ ] `StaminaComponent` (node): `max_stamina, current_stamina, regen_rate, regen_delay, is_exhausted`, ground regen bonus, `spend()`, `try_spend()`, signals `stamina_changed`, `exhausted`, `recovered`
- [ ] All values in `resources/config/stamina_config.tres` + profiles (from review §4)
- [ ] Debug overlay (F3): velocity, on-floor, coyote/buffer timers, stamina
- [ ] **Done when:** a test room with 1–4 tile gaps and ledges feels tight. Short hop vs. full jump is clearly different, and edge jumps and early presses always work

### M4 — Band / party system
- [ ] `BandMember` scene = shared controller + profile + ability node + stamina + health + inventory
- [ ] 5 instances with tinted `char_blue` (Joep, Jay, Nikki, The Germ, Geoff), name label above head
- [ ] Switch: Tab/Q/E cycle, 1–5 direct. Inactive members idle in place, camera tween 0.25 s
- [ ] Gather: inactive members walk to the leader (simple follow, only when reachable on flat ground)
- [ ] HUD: 5 portraits (placeholder) with HP pips, active one highlighted, stamina bar under the active HP (only visible when < max or just changed), 3 item slots
- [ ] **Done when:** you can play all 5, and you can see the different speeds and jump heights

### M5 — Level framework
- [ ] `Room` scene: bounds (camera limits), spawn points per member, `Checkpoint`
- [ ] Doors: room → room (all members transported, fade), level → world map, keycard door
- [ ] Health: 3 HP / Geoff 1, 1 s i-frames + knockback + flash
- [ ] Hazards: spikes (−1 HP), pit and electric floor (instant death)
- [ ] Death → short death animation → **room reset** (members, pushables, enemies, items back to checkpoint state)
- [ ] Enemies: rat (patrol, hurts on touch, stunnable), bouncer (blocks a passage, talkable)
- [ ] Camera: deadzone + look-ahead, clamp to room bounds
- [ ] **Done when:** you can die and respawn in every way within 1.5 s without broken state

### M6 — Abilities (one core each + drink)
- [ ] **Joep:** wall-slide + wall-jump + climb climbable walls (stamina). Hack panel → opens a gate / disables an electric floor
- [ ] **Jay:** push/pull crates. Bass wave (ranged) breaks glass/fragile walls and knocks back rats. **Throw a band member** up
- [ ] **Nikki:** double jump + hover by holding jump (stamina)
- [ ] **The Germ:** punch, air punch = ground-pound (breaks crates/cracked floors, stuns). Shield hold forward/up (stamina) blocks projectiles and falling debris
- [ ] **Geoff:** talk/persuade humans (bouncer moves aside). Bubble distraction (humans/rats look at bubble 2 s)
- [ ] Breakable materials as a data table: glass / fragile wall → Jay, wood / crate / cracked floor → The Germ
- [ ] Drink (B): beer heals 1 HP for everyone + Joep speed/quiet 5 s + Nikki heal aura 1 HP to members within 2 tiles
- [ ] **Done when:** a test room has one gate that *needs* each member

### M7 — Items & inventory
- [ ] `ItemData` resource (id, name, icon, consumable, owner restriction)
- [ ] Pickups in rooms, 3 slots per member, use/drop
- [ ] Give: when another member is within 1 tile → item moves to them
- [ ] Rolling papers: Geoff follows whoever carries them (simple follow AI)
- [ ] **Done when:** keycard and beer can be handed over, and Geoff follows the papers through a room

### M8 — World map
- [ ] Wide scene with parallax (same bg for now), hand-placed segments: studio (center) → city → service station → venue (one side), city → road block (other side)
- [ ] Band moves as a group (leader + followers in a line), no deaths
- [ ] Bike: get on/off anywhere, ~1.6× walk speed. Van: get in/out only at parking spots, ~3× walk speed, smooth accel
- [ ] Doors: studio (interior later), venue → level. Packages to pick up (+coins counter)
- [ ] NPC Geordie: dialogue box (typewriter, next/close), quest flag start/complete, "!" marker
- [ ] Camera: zoom 1×, slower follow, wider look-ahead (bigger while driving)
- [ ] **Done when:** you can take the bike or van from the studio to the venue and enter it

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
| Ability A | J / X | X |
| Ability B (drink) | K / Z | Y |
| Interact / talk | E | B |
| Give item | F | Left trigger |
| Gather band | G | Back |
| Previous / next member | Q / Tab | LB / RB |
| Select member | 1–5 | — |
| Pause | Esc / P | Start |
| Debug overlay | F3 | — |
