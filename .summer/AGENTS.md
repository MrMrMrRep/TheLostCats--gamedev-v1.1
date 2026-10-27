# Agent Notes

Project-specific guidance for AI agents lives here.

## Running on Linux

The game is GDScript on Godot 4.7 (`project.godot` feature `4.7`, Summer app version `0.7.3`). Summer does not publish a Linux engine binary: `npx summer-engine install` looks up `SummerEngine/SummerEngine` releases and gets HTTP 404, and the download page only offers macOS and Windows. Use the official Godot 4.7.2 editor. On a Cloud Agent it is installed as `godot` and also as `Summer` (same binary), so the commands in `docs/v1-plan.md` work.

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/test_baseline_movement.gd
```

A window needs a display and software GL. Forward+ needs Vulkan, which this environment does not have:

```bash
godot --path . --rendering-driver opengl3 --rendering-method gl_compatibility
```

Title menu: Enter starts the tour. Move with WASD. There is no sound device; Godot falls back to the dummy audio driver.

## Linux and Cloud Agents

Summer Engine 0.7.3 (the version in `project.godot`) does not publish a Linux editor. This environment runs the project on Godot 4.7.2, which is the Godot version Summer 0.7.3 is built on. `godot` and `Summer` on `PATH` are that binary.

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
