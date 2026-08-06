#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

resolve_godot() {
  local candidates=(
    "${GODOT_BIN:-}"
    "${GODOT:-}"
    "godot4"
    "godot"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    [[ -z "$candidate" ]] && continue
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
  done

  echo "Godot was not found. Set GODOT_BIN or install Godot 4.7.x." >&2
  return 1
}

GODOT_EXECUTABLE="$(resolve_godot)"
TESTS=(
  "res://tests/smoke/test_project_contract.gd"
  "res://tests/smoke/test_cross_platform_contract.gd"
  "res://tests/unit/test_logger.gd"
)

echo "Using Godot: $GODOT_EXECUTABLE"
echo "Project root: $PROJECT_ROOT"

echo "==> Import project"
GODOT_SILENCE_ROOT_WARNING=1 "$GODOT_EXECUTABLE" --headless --path "$PROJECT_ROOT" --editor --quit

for test_path in "${TESTS[@]}"; do
  echo "==> Run $test_path"
  GODOT_SILENCE_ROOT_WARNING=1 "$GODOT_EXECUTABLE" --headless --path "$PROJECT_ROOT" --script "$test_path"
done

echo "PASS: repository baseline verification"
