#!/bin/bash
# Runs every headless test in tests/ (or the ones named) and fails if any fails.
#   tools/run_tests.sh                 all tests
#   tools/run_tests.sh test_world      one test
# GODOT overrides the binary (default: godot, then Summer).
set -uo pipefail

cd "$(dirname "$0")/.."
GODOT="${GODOT:-$(command -v godot || command -v Summer)}"
if [ -z "$GODOT" ]; then
  echo "No Godot binary: install Godot 4.7.2 or set GODOT=..." >&2
  exit 2
fi

if [ ! -d .godot/imported ]; then
  "$GODOT" --headless --disable-crash-handler --path . --import >/dev/null 2>&1
fi

if [ $# -gt 0 ]; then
  tests=("$@")
else
  tests=()
  for f in tests/test_*.gd; do tests+=("$(basename "$f" .gd)"); done
fi

failed=()
for t in "${tests[@]}"; do
  t="${t%.gd}"
  log="$(mktemp)"
  timeout 600 "$GODOT" --headless --disable-crash-handler --path . --script "res://tests/$t.gd" >"$log" 2>&1
  code=$?
  # Tests exit 1 on a failed check; most also print "FAILURES: n".
  if [ $code -eq 0 ] && ! grep -qE "FAILURES: [1-9]" "$log"; then
    echo "PASS  $t ($(grep -cE '^ +(ok|PASS) ' "$log") checks)"
  else
    echo "FAIL  $t (exit $code)"
    grep -E "FAIL|ERROR|SCRIPT ERROR|FAILURES" "$log" | head -40
    failed+=("$t")
  fi
  rm -f "$log"
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "${#failed[@]} of ${#tests[@]} tests failed: ${failed[*]}"
  exit 1
fi
echo "All ${#tests[@]} tests passed."
