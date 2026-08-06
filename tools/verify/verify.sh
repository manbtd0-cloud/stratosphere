#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$PROJECT_ROOT/tests/test_manifest.txt"
RUN_BENCHMARK=false

for argument in "$@"; do
  case "$argument" in
    --benchmark|-Benchmark) RUN_BENCHMARK=true ;;
    *) echo "Unknown argument: $argument" >&2; exit 2 ;;
  esac
done

resolve_godot() {
  local candidates=("${GODOT_BIN:-}" "${GODOT:-}" "godot4" "godot")
  local candidate
  for candidate in "${candidates[@]}"; do
    [[ -z "$candidate" ]] && continue
    if [[ -x "$candidate" ]]; then printf '%s\n' "$candidate"; return 0; fi
    if command -v "$candidate" >/dev/null 2>&1; then command -v "$candidate"; return 0; fi
  done
  echo "Godot was not found. Set GODOT_BIN or install Godot 4.7.x." >&2
  return 1
}

run_godot_checked() {
  local label="$1"
  shift
  local output_file
  output_file="$(mktemp)"
  local exit_code
  set +e
  GODOT_SILENCE_ROOT_WARNING=1 "$GODOT_EXECUTABLE" "$@" 2>&1 | tee "$output_file"
  exit_code=${PIPESTATUS[0]}
  set -e
  if [[ $exit_code -ne 0 ]]; then
    rm -f "$output_file"
    echo "$label failed with exit code $exit_code." >&2
    return "$exit_code"
  fi
  if grep -Eq 'ObjectDB instances were leaked|resources? still in use at exit' "$output_file"; then
    rm -f "$output_file"
    echo "$label reported leaked Godot objects or resources." >&2
    return 1
  fi
  rm -f "$output_file"
}

GODOT_EXECUTABLE="$(resolve_godot)"
echo "Using Godot: $GODOT_EXECUTABLE"
echo "Project root: $PROJECT_ROOT"

echo "==> Import project"
run_godot_checked "Godot project import" --headless --path "$PROJECT_ROOT" --editor --quit

mapfile -t TESTS < <(grep -vE '^\s*(#|$)' "$MANIFEST")
for test_path in "${TESTS[@]}"; do
  echo "==> Run $test_path"
  run_godot_checked "Test $test_path" --headless --path "$PROJECT_ROOT" --script "$test_path"
done

if [[ "$RUN_BENCHMARK" == true ]]; then
  echo "==> Run non-authoritative benchmark contract"
  run_godot_checked "Benchmark contract" --headless --path "$PROJECT_ROOT" \
    --script res://tools/benchmark/run_benchmark.gd -- \
    --duration=1.0 --profile=medium --output=user://reports/benchmark/latest.json
fi

echo "PASS: repository verification (${#TESTS[@]} tests)"
