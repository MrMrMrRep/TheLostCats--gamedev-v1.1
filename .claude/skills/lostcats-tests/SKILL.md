---
name: lostcats-tests
description: Run and write The Lost Cats headless Godot tests (tests/test_*.gd). Use before every commit that touches scripts, scenes or resources, when CI's Tests workflow fails, or when adding a test for new gameplay.
---

# The Lost Cats: headless tests

## Run
```bash
tools/run_tests.sh               # all tests, PASS/FAIL per file
tools/run_tests.sh test_world    # one test
```
- Needs `godot` (Godot 4.7.2) on PATH. Cloud sessions get it from `.claude/hooks/session-start.sh`; elsewhere run `tools/install_godot.sh` (Linux) or set `GODOT=/Applications/Summer.app/Contents/MacOS/Summer`.
- New assets? Re-import first: `godot --headless --disable-crash-handler --path . --import`.
- A test passes when it exits 0 (and doesn't print a non-zero `FAILURES:` line). The whole suite takes ~5 min.
- CI runs the same script (`.github/workflows/tests.yml`) on every push and PR; the web deploy only publishes when it passes.

## Write a test
Copy the shape of an existing file (e.g. `tests/test_venue_puzzle.gd`):
- `extends SceneTree`, `_initialize()` defers `_run()`.
- Keep game classes **untyped** (naming a class compiles it before the autoloads exist in `--script` mode).
- Count checks in `_check(cond, label)`, print `  ok   <label>` / `  FAIL <label>`, and compare against `const EXPECTED_CHECKS` at the end, so a crash halfway can't look like a pass.
- Drive the game like a player (press actions, wait frames); no teleports in critical-path tests.
- End with `print("FAILURES: %d" % failures)` and `quit(1 if failures else 0)`.

## Suites
baseline movement, movement feel, band, level, critical path (each member alone, unhurt), abilities, items, world, controls (real keys), base, venue puzzle, touch pad.
