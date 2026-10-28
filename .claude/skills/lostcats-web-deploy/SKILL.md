---
name: lostcats-web-deploy
description: Publish The Lost Cats browser build to GitHub Pages, check what's live, or fix a failing Web build workflow. Use when asked to deploy, update the browser/phone build, or when the live link looks stale.
---

# The Lost Cats: web build and deploy

Live: https://mrmrmrrep.github.io/TheLostCats--gamedev-v1.1/ (served from the `gh-pages` branch).

## Normal path: automatic
Every push to `main` runs `.github/workflows/web.yml`:
1. installs Godot 4.7.2 + Web export templates (`tools/install_godot.sh --templates`, checksum-verified, cached),
2. runs `tools/run_tests.sh` (a failing test stops the deploy),
3. writes the commit time (Europe/Amsterdam, `dd/mm  HH:MM`) into `const BUILT` in `scripts/ui/title_screen.gd`. In the repo it stays `"dev"`; never hand-edit it,
4. exports the `Web` preset to `build/web/index.html`,
5. commits the result to `gh-pages` ("Browser build of <sha>.").

To redeploy without a code change: run the workflow by hand (Actions → Web build → Run workflow).

## Check what's live
The title screen's top-left stamp = commit time of the deployed build. Compare with `git log -1 main`. The Pages run ("pages build and deployment") follows each `gh-pages` commit.

## Local export (fallback)
```bash
tools/install_godot.sh --templates
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server -d build/web 8060
```
`build/` is git-ignored. The Web preset excludes `tests/*`, `docs/*`, `*.zip`, `*.bundle`, `.grok/*`; it uses the no-threads template (no COOP/COEP headers needed on Pages). Its `head_include` makes phones go fullscreen + landscape on first tap.
