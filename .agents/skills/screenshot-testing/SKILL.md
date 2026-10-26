---
name: screenshot-testing
description: >
  Use when a change has to be judged by eye: art, lighting, day and night,
  houses, signs, seams, HUD, or "does this look right". Use when the user
  asks for a screenshot, a visual check, or to look at the running game.
  Use when a log line says a frame was saved and nobody has opened the image.
---

# Screenshot testing

A saved path is not a look. Open the PNG and say what is in the frame before
calling a visual check done.

Pixels need a window. `--headless` draws nothing. Do not screenshot that way.

## Take the frames

From the project root, with the Summer binary (not a second editor):

```
/Applications/Summer.app/Contents/MacOS/Summer --path . res://scenes/world/world_map.tscn -- --capture=3:11780 --capture-dir="$PWD/.shots" --time=11
```

`tools/map_capture.gd` reads those args, parks the band, saves one PNG per
spot, prints `captured <path>`, then quits. Wait for that line and for the
process to exit.

- Each spot is `zoom:x`. `x` is world x (the band's position), not art pixels.
- Zoom `3` is a close row. Zoom `1` is a wide stretch. Several spots are one
  run: `--capture=3:11780,1:10500`.
- `--time=` is the hour. `11` is day. `21` is night. Day and night are two
  runs. The clock does not move during the capture.
- `--capture-dir` is an absolute directory. Use `.shots/` in the project.
  It is gitignored. Do not write into `docs/art/` for a check.

`tools/world_shots.gd` (`res://tools/world_shots.tscn`) is only the fixed
style-mock tour. It writes `docs/art/game_v3_<spot>.png`. Use it when the
comparison is those mocks. `--only=studio,venue` limits the spots.

## Look

Open every PNG with the file reader that accepts images. Do this in the same
turn, before the verdict.

Say what the frame actually shows: which block, sky colour, whether windows
glow, whether a sign and its door are intact, whether two styles meet at a
bridge or side street. Name the file and the `zoom:x` (and the hour) the
claim came from.

One frame shows a state. A before/after claim needs both files, same zoom and
x, and a description of the difference.

## Do not

- Treat `captured ...` or a zero exit code as the look.
- Commit the PNGs unless asked.
- Crop, filter, or redraw the shot before judging it.
- Use `world_shots` for an arbitrary x. It only visits its spot list.
