# Agent Notes

Project-specific guidance for AI agents lives here.

## Linux and Cloud Agents

Summer Engine 0.7.3 (the version in `project.godot`) does not publish a Linux editor. This environment runs the project on Godot 4.7.2, which is the Godot version Summer 0.7.3 is built on. `godot` and `Summer` on `PATH` are that binary (installed by `tools/install_godot.sh`; in Claude Code cloud sessions the SessionStart hook runs it).

Import after a fresh checkout or when new assets appear (the image already has a completed import):

```bash
godot --headless --disable-crash-handler --path . --import
```

Run a test (exit code is the test's `quit()` code; `FAILURES: 0` is the pass line):

```bash
godot --headless --disable-crash-handler --path . --script res://tests/test_baseline_movement.gd
```

Play on a display. There is no GPU here, so use software OpenGL:

```bash
godot --display-driver x11 --rendering-driver opengl3 --rendering-method gl_compatibility --audio-driver Dummy --path .
```

The main scene is the title screen. "Start the tour" opens the world map.

Title menu: Enter starts the tour. Move with WASD. There is no sound device; Godot falls back to the dummy audio driver.

Run every test: `tools/run_tests.sh`.
