# Art Style — World Map ("Amsterdam canal, Kingdom Eighties feel")

**Status: palette and zoom approved; first pass built into the world map (2026-10-19): sky + clouds, skyline, back street, polder layers, canal houses, 3 bridges, live canal reflection, birds, zoom zones, band van. Not built yet: the road trip between cities, day/night, foreground reeds, van radio.** Mocks: `docs/art/style_mock_city_2x.png`, `docs/art/style_mock_polder_2x.png` (rendered by `tools/style_mock.gd`, the same palette and layer stack as below).

## 1. In one line
Crisp pixel art at a native 1× grid, an Amsterdam canal front seen **from across the water**: a saturated blue sky with big clouds, narrow gabled houses in **slate blue + Dutch orange + warm brick**, cream trims, and a **canal in the foreground that mirrors the street**.

## 2. What we take from the references
| Reference | We take |
|---|---|
| "Love this one" (blue/orange) | The palette backbone: slate/steel blues against Dutch orange, navy instead of black, cream/white trims, boats, a patterned quay |
| Pixel canal houses | Dithered sky gradient, 1-px cornices and window frames, step/bell/neck gables, roof tiles |
| Flat vector row | Facade variety: warehouse doors, arched windows, stone plinths, a pier |
| Pastel silhouette row | Shop awnings, arched ground floors, no two neighbours the same colour |
| Live wallpaper | The layer order: skyline → houses → trees/lamps → street (bikes, cars) → railing → quay → water. Day/evening/night later |
| Canal (Kingdom Eighties) | Water fills the bottom ~35% of the screen with a full mirror reflection, per-row jitter and light streaks; reeds on banks; puffy clouds |

## 3. Palette (32 colours; hex)
| Group | Colours |
|---|---|
| Sky | `#7fb0ea` top · `#a9cbf2` mid · `#d4e5f8` horizon · sun `#fff1b8` |
| Clouds | `#f6f9fe` light · `#d3e0f3` shade · `#b4c8e6` underside |
| Haze (far skyline) | `#9db6d8` · `#86a2c9` |
| Facades (mix, no neighbours alike) | slate blue `#5b7fa6` · light blue `#8fb0d2` · deep blue `#41587a` · **Dutch orange `#e07a2e`** · light orange `#f2a65a` · salmon brick `#d08a72` · terracotta `#b8604a` · dark brick `#4e2c26` · plum brown `#5c4149` · ochre `#c9a15a` |
| Details | trim `#f2e8da` · white `#fbf8f2` · glass `#1e2433` · lit window `#f4cf78` · door/navy `#232c42` · roof tiles `#3b2522` |
| Street & quay | cobble `#8a8292` / `#6c6476` · curb `#b9b1bb` · quay stone `#6f6a72` / `#524e58` · iron `#2a2830` |
| Water | canal `#2b5779` · deep `#1f4060` · highlight `#9cc4e4` · ditch `#3f7396` |
| Greens | leaves `#3f6b34` `#5d8c3e` `#86b44f` · grass `#6ea142` `#8dbc52` `#a9cf63` · far fields `#9cc06a` |
| Rural | barn `#a8432f` / `#6b3a2a` · mill wood `#5a4636` · sails `#efe6d2` · turbines `#e9eef2` · road `#4a4a52` |

Rules: **no pure black** (the darkest colour is navy/glass); **light from the top-left** (the right edge of each facade is 1 shade darker); orange is an accent (about 1 in 4 houses, awnings, boats), not the majority.

## 4. Screen layout (world map, 640×360 view at 1×)
- Sky: y 0–206 (the houses take the lower part)
- **Street (the band's feet): y 206**, 14 px cobbles + curb
- Quay wall with railing and bollards: y 220–228
- **Canal: y 228–360** (about 35% of the screen), reflecting everything above it

This replaces today's layout (street at y 288 with a thin canal strip).

## 5. Layer stack (back → front) and parallax
| # | Layer | Parallax | Notes |
|---|---|---|---|
| 0 | Sky gradient + dither | 0 | Static; later day/evening/night palettes |
| 1 | Sun | 0.02 | |
| 2 | Far clouds | 0.05 + slow drift | |
| 3 | Near clouds | 0.12 + drift | |
| 4 | Skyline silhouette (rooftops, church towers, cranes) | 0.2 | Hazy blue |
| 5 | Back street (smaller muted houses + trees) | 0.45 | Shows through **gaps** in the front row |
| 6 | Trees, lamps | 0.8 | |
| 7 | **Play layer**: canal houses, doors (studio, venue), street, bikes, NPCs, band | 1.0 | **Bridges** (3 in Amsterdam, 96 px each): the house row opens, you look down a side canal (houses on both banks shrinking to a vanishing point), iron railing on the deck, stone arch in the quay wall |
| 8 | Quay wall, railing, bollards, moored boats | 1.0 | |
| 9 | **Canal water**: live reflection of the play layer (screen-reading shader: mirror + per-row jitter + streaks) | 1.0 | Priority item |
| 10 | Foreground (reeds, a boat bow, a lamppost) | 1.3, darker | Sparse, never blocks the band |

## 6. Zones along the map
| Zone | Where | Back layers (4–6) | Play layer | Water |
|---|---|---|---|---|
| **Centrum** | Studio ± ~1.5 screens | Dense skyline, churches | Dense canal houses, shops, awnings, bikes | Canal with houseboats |
| **Outskirts** | Further out | Fewer, lower houses; more trees; a tram/bike path | Sparse houses, tree-lined street, service station | Canal → wider "vaart" |
| **Polder** | Beyond the city (towards festival/stadium later) | Big sky, **wind turbines** on the horizon (rotors turn), a distant **highway** with small cars, striped fields with ditches | **Dike road**; farms, **old windmills** (sails turn), **cows**, trees | Wide ditch with reeds |

Zones blend over ~400 px (layers 4–6 crossfade by camera x), so driving out of town feels like a journey.

## 7. Characters on this background (for the sprite work)
- The band at map scale: **~32 px tall** (houses are ~3.5–4 characters tall), feet on the street line
- Same rules: no pure black (outline with the darkest shade of each colour), light from the top-left, stay inside this palette's family. Skin/clothes ramps of 3–4 shades
- See §8 for the technical handoff

## 8. Sprite handoff spec (for the sprite-animation session)
So new band sprites drop straight into the engine:
- **One PNG sprite sheet per member**, transparent background, character facing **right**. Path: `public/assets/band/<id>/<id>.png` with `<id>` = `joep`, `jay`, `nikki`, `germ`, `geoff`
- **Cell 56×56 px**, rows = animations, frames left to right; **feet touch the bottom edge of the cell**, body centred horizontally; body about **22×32 px** (the collision box is 12×28)
- **Minimum animations** (row names): `idle`, `run`, `jump_start`, `jump`, `fall`, `land`, `hurt`, `death`
- **Ability animations** (any order, any frame count): Joep `climb`, `wall_slide`; Jay `push`, `throw`, `bass_wave`; Nikki `hover` (standing on the guitar); The Germ `punch`, `air_attack` (ground pound), `shield`, `shield_up`; Geoff `talk`, `bubble`; everyone `drink`, `ride_bike` (sitting)
- Per sheet, describe it in `public/assets/band/assets.json` like `public/assets/amwoods/assets.json` (`frame_size`, `columns`, `animations: [{name, frames: [[col,row]...], fps, loop}]`). The engine builds the SpriteFrames from that
- Silhouettes should tell members apart at 32 px: Geoff (mic, singer pose), Jay (bass), Joep (keys/keytar), Nikki (guitar), The Germ (drumsticks, sturdy build)

## 9. Decisions so far (2026-10-19)
1. **Palette**: approved as in the mocks.
2. **Water is not everywhere**: it fades out with the zones (city canal → polder ditch → no water in Germany, hills instead). See §10.
3. **Driving between cities** is part of the game (§10).
4. **Day/night cycle**: wanted; proposal in §11.
5. **Zoom**: 3× studio, 2× city, 0.5× road trip with radio and birds (§10).
6. **Bridges** in the city (§5, layer 7).

## 10. Zoom levels and the road trip
The camera zoom tells you what kind of moment you're in:

| Where | Zoom | View | Feel |
|---|---|---|---|
| Studio / storage (home base) | **3×** | 213×120 | Close, cosy, detailed |
| City streets on foot / bikes (Amsterdam, Essen) | **2×** | 320×180 | The walkable map |
| Driving the van in town | **1×** | 640×360 | A little wider while driving |
| On the road between cities | **0.5×** | 1280×720 | Wide, calm, "meditation", radio and birds |

Zoom changes ease (~1.6 s) when you enter or leave a zone. It's pixel-perfect at 3×, 2×, 1× and 0.5×; in between there's brief shimmer, acceptable during a smooth ease. The camera keeps the canal at the bottom of the screen: the more you zoom out, the more water and sky you see (`world_map.gd` `_apply_zoom`).

**The road trip** (e.g. Amsterdam → Ruhrpott/Essen–Düsseldorf):
- You get in the van at a P sign, choose the next tour stop, and drive: the camera eases out to 0.5×, **the van radio starts** (the band's music, a calm mix), **birds** fly in loose flocks, clouds drift
- Scenery zones pass in parallax: Amsterdam centrum → outskirts → **polder** (ditches, cows, old mills, turbines) → border → **Germany: rolling hills** in 3 parallax layers, forests, half-timbered villages → **Ruhrpott**: mine headframes, chimneys, slag heaps, then the city
- **Water fades with the zones**: the canal strip shrinks into a ditch and then disappears; the ground rises to fill the screen (no hard cut)
- **Length**: a target of **60–90 s** per leg, tunable in one number. Playtest it: long enough to breathe, short enough not to bore. You can stop on the way (services, a detour)
- Light gameplay while driving: steer/speed, maybe overtake, the police at night (§11), fuel later

## 11. Day/night cycle (proposal)
- **Time only runs on the world map / road**, never in levels (gigs are their own scenes)
- **One tour day ≈ 8 minutes of map time**: morning 2 min → afternoon 3 min → evening 1.5 min → night 1.5 min. Visiting a gig skips you to after the show (night). Sleeping (studio/hotel/van) jumps to the next morning = next tour day
- **Visual**: sky palette and lighting shift (day → golden evening → blue night), sun/moon, stars; windows light up, street lamps and van headlights glow (as in your night references)
- **Gameplay** (after v1, one at a time): venues open in the evening ("soundcheck at 4"); shops have opening hours; NPCs move around (Geordie at the studio by day, at the venue at night); **police patrol the highway at night** (GDD); calmer radio by night; more fans in the evening
- **v1**: the visual cycle plus venue opening hours. The rest after v1

## 12. Band van (first pass: `public/assets/vehicles/band_van.png`)
- Boxy 70s/80s panel van (reference 1 shape) with reference 2's detail: dark outline, roof shine, highlight band, tinted windows with reflection streaks, chrome bumpers and grille, headlight/indicator/tail light, hubcaps, shadow
- **Black** (GDD: "Black Band Van") with a Dutch-orange/cream **retro stripe** and a small cat logo on the sliding door
- Sheet: 4 frames of 112×56 px (wheels turn), facing right. Previews: `docs/art/band_van_preview_4x.png`, `docs/art/band_van_on_street_2x.png`. Drawn by `tools/van_sprite.gd`, so colours and details are easy to change
- Next, if you like it: suspension bob, exhaust puff, brake light, open sliding door for boarding
