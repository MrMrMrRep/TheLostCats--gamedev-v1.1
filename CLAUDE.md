# The Lost Cats — agent notes

Side-view pixel game about a band on tour: Lost Vikings co-op puzzles, Celeste controls, Kingdom Eighties look. GDScript on **Summer Engine 0.7.3 = Godot 4.7** (Linux/cloud: official Godot 4.7.2 as `godot` / `Summer`).

Start with `docs/project-plan.md` (status, issues, next steps) and `docs/skills.md` (what each member can do, the gating matrix), then `docs/v1-plan.md` (milestones), `docs/gdd-review.md` (design rules), `docs/art-style.md` + `docs/city-layout.md` (look), `docs/editing-the-world.md` (map editing, config values).

## Commands
```bash
tools/install_godot.sh                                   # Linux: Godot 4.7.2 (cloud sessions: done by the SessionStart hook)
godot --headless --disable-crash-handler --path . --import   # after new assets
tools/run_tests.sh                                       # all headless tests; tools/run_tests.sh test_world for one
godot --display-driver x11 --rendering-driver opengl3 --rendering-method gl_compatibility --audio-driver Dummy --path .   # play (no GPU)
```
CI: `.github/workflows/tests.yml` (every push/PR), `.github/workflows/web.yml` (push to `main` → tests → Web export → `gh-pages`).

## Rules
- Run `tools/run_tests.sh` before committing gameplay changes; add checks to the matching `tests/test_*.gd` (keep `EXPECTED_CHECKS` right).
- Tunable numbers live in `resources/config/*.tres` and `resources/profiles/*.tres`, not in scripts.
- Skills: shared moves in `scripts/characters/band_member.gd`, per member in `scripts/abilities/`. Change a skill → update `docs/skills.md` and `tests/test_abilities.gd`.
- `scenes/world/world_map.tscn` is hand-edited in the editor. **Never run `tools/build_world_map.gd`** (retired; it would wipe the edits). Don't rename `Start`, the markers, `Band`, `MapHud`, `DialogueBox`, `Birds`, `Places`.
- Art: the 32-colour palette in `docs/art-style.md` §3 (`tools/check_palette.py`), no pure black, light from the top-left.
- `const BUILT` in `scripts/ui/title_screen.gd` stays `"dev"`; the web workflow stamps it.
- Don't commit export outputs (`build/`, `*.zip`) or git bundles.

## Project skills
`.claude/skills/`: `lostcats-tests`, `lostcats-web-deploy`, `lostcats-playtest`, plus the relevant gamedev skills linked from `.agents/skills/`.
