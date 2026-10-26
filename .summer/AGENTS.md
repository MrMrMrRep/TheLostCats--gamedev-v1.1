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
