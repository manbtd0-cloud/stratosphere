#!/usr/bin/env bash
set -euo pipefail
export TERM="${TERM:-xterm}"

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
  TERM="$TERM" GODOT_SILENCE_ROOT_WARNING=1 "$GODOT_EXECUTABLE" "$@" 2>&1 | tee "$output_file"
  exit_code=${PIPESTATUS[0]}
  set -e
  if [[ $exit_code -ne 0 ]]; then
    rm -f "$output_file"
    echo "$label failed with exit code $exit_code." >&2
    return "$exit_code"
  fi
  if grep -Eq 'SCRIPT ERROR|ERROR: FAIL|ObjectDB instances were leaked|resources? still in use at exit' "$output_file"; then
    rm -f "$output_file"
    echo "$label reported a script error, failed assertion, or leaked Godot object/resource." >&2
    return 1
  fi
  rm -f "$output_file"
}

run_tick_probe() {
  local ticks="$1"
  local output_file
  output_file="$(mktemp)"
  local exit_code
  set +e
  TERM="$TERM" GODOT_SILENCE_ROOT_WARNING=1 "$GODOT_EXECUTABLE" \
    --headless --fixed-fps "$ticks" --path "$PROJECT_ROOT" \
    --script res://tests/phase1/test_41_tick_rate_probe.gd -- --ticks="$ticks" \
    >"$output_file" 2>&1
  exit_code=$?
  set -e
  cat "$output_file"
  if [[ $exit_code -ne 0 ]] || grep -Eq 'SCRIPT ERROR|ERROR: FAIL|ObjectDB instances were leaked|resources? still in use at exit' "$output_file"; then
    rm -f "$output_file"
    echo "Tick-rate probe at ${ticks} Hz failed." >&2
    return 1
  fi
  local speed
  speed="$(sed -nE "s/.*TICK_RESULT ticks=${ticks} speed=([0-9.]+).*/\1/p" "$output_file" | tail -n1)"
  rm -f "$output_file"
  [[ -n "$speed" ]] || { echo "Tick-rate probe at ${ticks} Hz did not report speed." >&2; return 1; }
  printf '%s\n' "$speed"
}

GODOT_EXECUTABLE="$(resolve_godot)"
echo "Using Godot: $GODOT_EXECUTABLE"
echo "Project root: $PROJECT_ROOT"

echo "==> Import project"
run_godot_checked "Godot project import" --headless --path "$PROJECT_ROOT" --editor --quit

mapfile -t TESTS < <(grep -vE '^\s*(#|$)' "$MANIFEST")
for test_path in "${TESTS[@]}"; do
  echo "==> Run $test_path"
  run_godot_checked "Test $test_path" --headless --fixed-fps 120 --path "$PROJECT_ROOT" --script "$test_path"
done

echo "==> Cross-process physics tick-rate matrix"
SPEED_60="$(run_tick_probe 60 | tee /dev/stderr | tail -n1)"
SPEED_120="$(run_tick_probe 120 | tee /dev/stderr | tail -n1)"
RELATIVE_DIFF="$(python3 - "$SPEED_60" "$SPEED_120" <<'PY'
import sys
s60, s120 = map(float, sys.argv[1:])
den = max(abs(s60), abs(s120), 1e-9)
print(abs(s60 - s120) / den)
PY
)"
python3 - "$RELATIVE_DIFF" <<'PY'
import sys
value = float(sys.argv[1])
limit = 0.12
if value > limit:
    raise SystemExit(f"Tick-rate relative speed difference {value:.4%} exceeds {limit:.0%}")
print(f"PASS: 60/120 Hz relative speed difference = {value:.2%}")
PY

if "$RUN_BENCHMARK"; then
  echo "==> Run non-authoritative benchmark contract"
  run_godot_checked "Benchmark contract" --headless --fixed-fps 120 --path "$PROJECT_ROOT" \
    --script res://tools/benchmark/run_benchmark.gd -- \
    --duration=1.0 --profile=medium --output=user://reports/benchmark/latest.json
fi

echo "PASS: repository verification (${#TESTS[@]} tests + physics tick matrix)"
