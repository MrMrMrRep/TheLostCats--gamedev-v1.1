# The Lost Cats — Project Plan & Status

_Snapshot 2026-10-28, `main` at `03a59f8` (122 commits); Phase A (§6) done the same day. Written from the repo: the docs in `docs/`, the code, the configs and the GitHub state. It sits above [`v1-plan.md`](v1-plan.md) (the milestone checklist), [`gdd-review.md`](gdd-review.md) (design decisions), [`art-style.md`](art-style.md) / [`city-layout.md`](city-layout.md) (look) and [`editing-the-world.md`](editing-the-world.md) (how to edit)._

---

## 1. The game in short

**"The Lost Cats: Nine Lives on the Road"**: a 2D side-view pixel game about a real band on tour.

| Pillar | Reference | What it means here |
|---|---|---|
| Co-op puzzles | The Lost Vikings | 5 band members, each with one thing only they can do; levels gate on those |
| Controls | Celeste | Tight shared controller (coyote, buffer, jump cut, corner correction); members differ only in speed, jump height and one verb |
| Look and pace | Kingdom Eighties | A calm, reflective world map (walk, bike, van) between tense levels (gigs) |

**Cast and skills** (v2, 2026-10-28; full reference and gating matrix in [`skills.md`](skills.md)). Everyone walks, runs, crouches, wall-slides and punches (with a weapon if one is selected).

| Member | Instrument | Special (K) | Instrument skill (L) |
|---|---|---|---|
| Joep | keys | hack panels, doors, cameras, amps; through wall plugs | electric shockwave: rats out/stunned, devices switched |
| Jay | bass | lift and throw flight cases (and band members) | slap bass: rats back, glass breaks, cases fly, defence bubble |
| The Germ | drums | rage punch on fire through rats and crates (slam in the air) | Drumbeat Master: stop, rewind, play time |
| Nikki | guitar | grapple hooks and swing | guitar solo: a note bridge or ramp for the whole band |
| Geoff | vocals | bubble gun: distracts some people | the voice and the charm: persuades people, opens staff doors; better prices; 1 HP |

**Loop**: world map (Amsterdam, 18–20k px wide: polder → old town → canal belt → flats → industry → band storage → airport) → talk to Geordie (tour manager) → reach the venue → play the level → "Where is Geoff?" finale (he's asleep in the drum case; lure him out with rolling papers) → Finished / Completed (hidden NPCs) → back to Geordie.

**v1 goal** (from `v1-plan.md`): a vertical slice that proves the controls feel good for all 5, the co-op puzzles are fun, and the calm map balances the tense levels. It should *play* right; it doesn't have to look final.

---

## 2. Style guide (condensed)

Full version: `docs/art-style.md`, `docs/city-layout.md`.

- **Look**: crisp pixel art, an Amsterdam canal front seen from across the water. Saturated blue sky, big clouds, narrow gabled houses in slate blue + Dutch orange + warm brick, cream trims, a canal mirroring the street.
- **Palette**: 32 fixed colours (table in `art-style.md` §3). Checked by `tools/check_palette.py`; `shaders/palette_snap.gdshader` + `color_grade.gdshader` keep the world on palette (teal pushed towards azure).
- **Rules**: no pure black (darkest = navy `#232c42` / glass `#1e2433`); light from the top-left (right edge one shade darker); orange is an accent (~1 in 4 houses); every element gets frame + shadow + one highlight; one small story per house, no more; no two neighbours share a colour.
- **Pixel density**: the city is drawn at the band sprites' density ("art px" = half a world px). Band = 27 world px tall on the map.
- **Scale**: door 17×34, window 11×18, car 62×22, our van 81×34, canal house 54–72 wide (`city-layout.md` §3).
- **Layers** (back → front): sky, sun, clouds, far skyline, back street, trees/lamps, play layer, quay, water (live reflection shader), foreground (parallax 1.3).
- **Camera**: walk 1.5× (1.33 moving), bike 1.4/1.2, van 1.33/1.1, road trip 0.5×. Levels 2×.
- **UI**: one pixel font for everything (`scripts/ui/ui_font.gd`), 1 px outlines, navy shadows.
- **Characters**: 56×56 cells, facing right, feet on the bottom edge, ~22×32 body; required rows idle/run/jump_start/jump/fall/land/hurt/death + ability rows (§8 of `art-style.md`).
- **Audio**: map ~80–90 BPM dub/reggae (calm), levels ~140–160 BPM ska-punk (tense), 1.5 s crossfade. Current files are generated placeholders (`tools/make_audio.py`).

---

## 3. Tech stack and connectivities

| Area | What's used |
|---|---|
| Engine | **Summer Engine 0.7.3** (a Godot 4.7 fork) on macOS. On Linux / cloud agents: official **Godot 4.7.2** (Summer has no Linux build; see `.summer/AGENTS.md`) |
| Language | GDScript only (the `[dotnet]` section in `project.godot` is a leftover) |
| Renderer | Forward+ (desktop); web export runs on Compatibility/WebGL2 |
| Display | 640×360 viewport, integer scaling, nearest filter, pixel snap |
| Autoloads | `Game` (state, quest flags), `SceneRouter` (doors + fades), `Audio` (crossfade, SFX), `Pause`, `TouchPad` (on-screen gamepad for phones) |
| Data | All tunables in `resources/config/*.tres` and `resources/profiles/*.tres` (hot-reload while running from Summer) |
| Hosting | **GitHub Pages** from the `gh-pages` branch: https://mrmrmrrep.github.io/TheLostCats--gamedev-v1.1/, published by `.github/workflows/web.yml` on every push to `main` |
| Other export | `summer.games` preset (writes `TheLostCats -gamedev-v1.1.zip` into the repo root; now git-ignored) |
| CI | `.github/workflows/tests.yml`: all headless tests on every push and PR (`tools/run_tests.sh`, Godot via `tools/install_godot.sh`) |
| Assets repo | `the-lost-cats--assets` (separate repo): finished band sprites, copied in by `tools/sync_sprites.sh` |

**MCP servers / external services** (`.cursor/mcp.json`)

| Server | Used for |
|---|---|
| `summer-engine` (`npx summer-engine@latest mcp`) | Editor control from an agent (Cursor) |
| `spritecook` (`https://mcp.spritecook.ai/mcp/cursor`) | AI pixel-art edits of the side openings and house rows (`tools/spritecook/README.md`, asset ids in `spritecook-assets.json`) |

**Agent skills** (`.agents/skills/`, locked in `skills-lock.json`, source `gamedev-skills/awesome-gamedev-agent-skills`; `.grok/skills` symlinks a subset).
Relevant to this game: `godot-2d-movement`, `platformer`, `godot-gdscript(-patterns)`, `godot-gdscript-headless-testing`, `godot-nodes-scenes`, `godot-resources`, `godot-signals-groups`, `godot-physics`, `godot-tilemap`, `godot-animation`, `godot-shaders`/`shader-programming`, `godot-ui-control`, `game-ui-ux`, `camera-systems`, `game-feel`, `audio-design`/`godot-audio`, `level-design`, `puzzle`, `dialogue-systems`, `save-systems`, `input-systems`, `performance-optimization`, `screenshot-testing`, `create-game-assets`, `godot-export`, `itch-publish`, `steam-publish`.
Not relevant (can be removed to cut noise): `fps-shooter`, `card-game`, `tower-defense`, `roguelike`, `survival-crafting`, `godot-3d-essentials`, `godot-multiplayer`, `godot-csharp`, `visual-novel`, `rpg`, `procedural-gen` (until the procedural map), `ai-behavior-trees-utility-ai`.

**Claude Code skills** (`.claude/skills/`): the relevant ones above are linked from `.agents/skills/`, plus three project skills: `lostcats-tests` (run/write the headless tests), `lostcats-web-deploy` (Pages build), `lostcats-playtest` (the M11 procedure).

**Cloud sessions**: `.claude/hooks/session-start.sh` installs Godot 4.7.2 (checksum-verified) as `godot` / `Summer` and imports the project. It still has to be registered in `.claude/settings.json` (see §6, Phase A).

---

## 4. Build status

### Milestones (`v1-plan.md`)

| Milestone | Status | Notes |
|---|---|---|
| M0 Setup | ✅ | |
| M1 Assets index | ✅ | |
| M2 Baseline scene | ✅ | |
| M3 Celeste controller + stamina | ✅ | hands-on feel check still open |
| M4 Band / party system | ✅ | hands-on check still open |
| M5 Level framework | ✅ | |
| M6 Abilities | ✅ → reworked as M6b | skill set v2 (2026-10-28): run, crouch, wall-slide, punch for all + special/instrument per member ([`skills.md`](skills.md)) |
| M7 Items & inventory | ✅ | |
| M8 World map | ✅ (well beyond scope) | 18k+ px city, traffic, day/night, radio, airport. **Rebuild in progress** (2026-10-28): canal belt done from the SpriteCook canal kit ([`city-layout.md`](city-layout.md) §8); old town and ring road next |
| M9 Slice level "Café De Kat" | ✅ | `scenes/levels/venue_puzzle.tscn`: BackEntrance, Storage, Bar, Backstage, Finale; Gwinny hidden NPC; end screen |
| M10 Pace, audio & juice | ✅ (one item open) | crossfade 1.5 s (`audio.gd`), dust/squash/hit-stop/shake (`scripts/fx/`), 18 SFX, title + pause. Open: zoom tween on world ↔ level doors (they fade only) |
| M11 Playtest, tune & balance | ❌ not started | no `docs/v1-playtest-notes.md` |

Extra work outside the v1 plan: day/night cycle (`day_config.tres`), base / party board (`scenes/levels/base.tscn`), touch gamepad + mobile fullscreen for the web, title "pick who starts", canal loading screen, final sprite sheets for Joep, Jay, Nikki, The Germ and Geoff.

### Code and tests

- ~23k lines of GDScript in `scripts/` + `tests/` (122 scripts in `scripts/`), 4 shaders.
- 12 headless test scripts (`tests/`): baseline, movement feel, band, level, critical path, abilities, items, world, controls, base, venue puzzle, touch pad. Each counts its checks so a crash can't pass.
- Static check: all 238 `res://` references in scripts, scenes and resources point at files that exist.
- **All 12 tests pass** on Godot 4.7.2 (2026-10-28, `tools/run_tests.sh`, ~10 min): abilities 69 checks (skill set v2), band 24, base 8, baseline 14, controls 29, critical path 20, items 23, level 40, movement feel 26, touch pad, venue puzzle 14, world 68 (incl. the canal kit).
- The Web export works headless and boots in Chromium without console errors.

### Deployment

- Live build last deployed **2026-10-27 03:44 UTC** ("Update the browser build with the studio row").
- Since then on `main`: canal terrace, centre quay, streets/quay/bridges, backyard trees, loading screen, instrument clips → **the live build is ~10 commits behind**. Fixed once Phase A reaches `main`: the web workflow republishes on every push.

---

## 5. Problems and issues

### High: gets in the way now
1. ✅ _fixed in Phase A_ — **No CI.** 12 good test suites, but nothing runs them on push or PR. With ~20 PRs merged in two days (mostly art), a gameplay regression would go unnoticed.
2. ✅ _fixed in Phase A_ — **Manual, stale web deploy.** The export goes to a folder outside the repo and gets pushed to `gh-pages` by hand; the live link is behind `main`.
3. **M11 never happened.** The whole point of v1 (does it play right?) is unmeasured: no timings, no death counts, no outside players. Recent work is almost all world-map art polish.
4. **Scope drift into the map.** The map grew from ~6 screens (3,840 px) to 18–20k px with traffic, airport, day/night and radio — items the plan put *after* v1. Meanwhile there is exactly one real level.

### Medium: repo hygiene (costs every clone and every agent)
5. ✅ _removed in Phase A (still in history)_ — **~17 MB of binaries that don't belong in git**: `docs/art/v3_ingame/branch.bundle` (8.2 MB), `mac.bundle` (3.1 MB), `lostcats.bundle` (3.1 MB), `TheLostCats -gamedev-v1.1.zip` (1.9 MB, an export output), `docs/art/v3_ingame/v3res.tgz` (1 MB). Git bundles inside the repo duplicate history. Pack is 37 MB.
6. **Stand-in assets**: `assets/sprites/characters/_temp/` (old Germ/Nikki/Geoff sheets) are no longer used by the game, but `tools/make_bike_riders.py` still reads them, so they stay. The `public/assets/amwoods/` knight is still the stand-in for NPCs (Geordie, bouncer, Gwinny).
7. **Machine-specific files committed**: ✅ `.claude/launch.json` removed (stale `/private/tmp/...` paths). `.vscode/settings.json` (`/Users/jaya/...`) kept so the owner's editor setup isn't deleted on pull.
8. **Generator scripts and one-off edits pile up in `tools/`** (`style_mock*.gd`, `scene_edits/2026_10_*`, the retired `build_world_map.gd`). Fine as history, but they should be marked or moved to `tools/archive/`.
9. ✅ _removed_ — **Leftover `[dotnet]` section** in `project.godot` (review §5 said to drop it).
10. ✅ _generated by the web workflow; `"dev"` in the repo_ — **Build stamp is hand-edited**: `scripts/ui/title_screen.gd:19` `const BUILT := "28/10  00:17"`, changed in nearly every commit message. Should be generated at export time.

### Medium: docs out of date
11. ✅ `v1-plan.md` M10 is unticked although built; the "Running the tests" block only lists macOS paths and 9 of the 12 tests.
12. ✅ `editing-the-world.md` §8 said `zoom_walk` 3.0 / van 1.7–1.3; the config has 1.5 / 1.33–1.1 (`art-style.md` §13 is right).
13. ✅ `art-style.md` §8 says band sheets go in `public/assets/band/<id>/`; they actually live in `assets/sprites/characters/<instrument>_<name>/`.
14. ✅ (README) `README.md` is 7 lines: no description, controls, run/test commands or links to the docs. The GDD itself (Notion export) isn't in the repo.
15. ✅ `.summer/AGENTS.md` repeats the Linux section twice.

### Low / later
16. **No save system**: "remembered" (van position, packages, quest) only lives in memory; a reload starts over. Fine for a slice, needed before more levels.
17. **Placeholder audio** (generated chiptunes, ~1.6 MB of WAV); web build would benefit from OGG.
18. **Open design questions**: road trip as semi-cutscene or driven; junctions; police at night; Nikki's cable bridge and Joep's traps (cut from v1); five-character switching fatigue (review §3.3).
19. **Real-people risk** (review §6): agree with the band on likenesses and the drinking/joint jokes before any public release; age rating for stores.

---

## 6. Plan: next steps

### Phase A — Stabilise ✅ (2026-10-28)
1. ✅ **CI**: `.github/workflows/tests.yml` runs `tools/run_tests.sh` on every push and PR (Godot 4.7.2 via `tools/install_godot.sh`, cached).
2. ✅ **Deploy**: `.github/workflows/web.yml` on `main`: tests → stamp `const BUILT` with the commit time → Web export → commit to `gh-pages`. Pages keeps serving that branch, so no Pages setting changes.
3. ✅ **Repo clean-up**: bundles, export zip and `v3res.tgz` removed; `.gitignore` covers `/build/`, `/*.zip`, `*.bundle`; `[dotnet]` dropped; stale `.claude/launch.json` removed. History rewrite to shrink the pack: optional, not done.
4. ✅ **Docs**: M10 ticked, stale numbers/paths fixed, `CLAUDE.md` + README, merged `AGENTS.md`.
5. ✅ **Agent setup**: cloud SessionStart hook installs Godot; skills for all phases exposed in `.claude/skills/` (+3 project skills).
6. ⏳ **Owner to do**: register the hook and allow rules in `.claude/settings.json` (an agent may not write that file), merge this work into `main`, and check the first Web build run.

### Phase B — Finish v1 = M11 (1–2 weeks)
5. Freeze new map art for now. Play the slice end to end: title → map → Geordie → Café De Kat → venue puzzle → finale → Geordie.
6. Measure against the targets: map leg 1–3 min, level 8–15 min, rooms 1.5–3 min, deaths R1 0–1 / R2–3 1–3 / R4+finale 2–5; each ability needed at least once.
7. Tune only in `.tres` files. Do the open hands-on feel checks from M3/M4.
8. 2–3 outside players via the web link (phones too: touch pad). Write `docs/v1-playtest-notes.md`.

### Phase C — v1.x / v2 (after the playtest)
9. Save system (`save-systems` skill): quest flags, coins, van/bike positions, packages, base level, clock.
10. Second level, to check the gating matrix holds up beyond one venue; decide on Nikki's cable bridge / Joep's traps.
11. Real NPC sprites (Geordie, bouncer, Gwinny), real music (dub map / ska-punk levels), OGG audio.
12. The road trip to the Ruhrpott (art-style §10), then police at night, economy, upgrades — one at a time, as in the GDD review.

### Skills / tools per phase
| Phase | Skills | Tools / connections |
|---|---|---|
| A | `lostcats-tests`, `lostcats-web-deploy`, `godot-gdscript-headless-testing`, `godot-export` | GitHub Actions, GitHub Pages, Godot 4.7.2 Linux build |
| B | `lostcats-playtest`, `level-design`, `puzzle`, `physics-tuning`, `camera-systems`, `platformer`, `game-feel`, `screenshot-testing`, `performance-optimization` | Web build on phones, `tools/map_capture.gd` / `world_shots.gd` |
| C | `save-systems`, `dialogue-systems`, `audio-design`, `godot-audio`, `create-game-assets`, `godot-animation`, `godot-shaders`, `game-ui-ux`, `itch-publish` | SpriteCook MCP, Summer MCP |
