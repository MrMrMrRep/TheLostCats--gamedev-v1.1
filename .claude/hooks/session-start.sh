#!/bin/bash
# Cloud sessions: install Godot 4.7.2 as `godot` / `Summer` and import the
# project, so the headless tests (tools/run_tests.sh) can run.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}"
tools/install_godot.sh >/dev/null
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

# Import once per checkout (.godot/ is git-ignored and holds the import cache).
if [ ! -d .godot/imported ]; then
  "$HOME/.local/bin/godot" --headless --disable-crash-handler --path . --import >/dev/null 2>&1 || true
fi
