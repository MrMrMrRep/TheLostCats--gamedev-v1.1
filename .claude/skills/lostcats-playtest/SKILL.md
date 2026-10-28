---
name: lostcats-playtest
description: Run the v1 slice playtest and balance pass for The Lost Cats (milestone M11). Use when asked to playtest, time, balance or tune the slice, or to write docs/v1-playtest-notes.md.
---

# The Lost Cats: slice playtest (M11)

Goal of v1 (`docs/v1-plan.md`): the controls feel good for all five, the co-op puzzles are fun, the calm map balances the tense level. Measure it; don't add features.

## Route
Title → world map → Geordie (storage) → Café De Kat (`scenes/levels/venue_puzzle.tscn`: BackEntrance, Storage, Bar, Backstage, Finale "Where is Geoff?") → end screen → back to Geordie ("Tour day 1 complete").

## Targets
| What | Target |
|---|---|
| World-map leg | 1–3 min |
| Level | 8–15 min; each room 1.5–3 min |
| Deaths per room | R1 0–1 · R2–R3 1–3 · R4/finale 2–5 |
| Abilities | each one used at least once and needed at least once |
| Console | no errors start → finish |

## How
1. `tools/run_tests.sh` first; the critical-path test proves every member can cross the shared parts alone.
2. Play in a window (cloud: `godot --display-driver x11 --rendering-driver opengl3 --rendering-method gl_compatibility --audio-driver Dummy --path .`) or the live web build on desktop and phone (touch pad).
3. F3 shows the debug overlay (velocity, coyote/buffer timers, stamina, fps).
4. Log per room: time, deaths and where, which member/ability solved what, where you got stuck.
5. Tune **only** in `.tres` files: `resources/profiles/<member>.tres` (run/jump/forgiveness), `resources/config/stamina_config.tres`, the map configs. Re-run the tests after each change.
6. 2–3 outside players without help (send the web link). Note where they stop or ask.
7. Write `docs/v1-playtest-notes.md`: numbers vs targets, problems ranked, the `.tres` changes made, what to change for v2. Then tick M11 in `docs/v1-plan.md`.

Useful skills: `level-design`, `platformer`, `game-feel`, `screenshot-testing`, `performance-optimization`.
