# Phase 0 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a verified, modular Godot 4.7 Forward+ foundation for the open-world racing game before vehicle or world production begins.

**Architecture:** Phase 0 creates the project contract, local verification, typed configuration resources, input routing, logging, versioned saves, an asset registry, and a benchmark scene. Runtime services communicate through explicit APIs and signals; no service owns gameplay rules outside its responsibility.

**Tech Stack:** Godot 4.7.x, GDScript 2.0, Forward+, Windows PowerShell 5.1+

## Global Constraints

- Primary platform is Windows PC.
- Renderer is Godot 4 Forward+.
- Keyboard is the primary control target; controller remains supported.
- Target GPU class is GTX 1660 / RX 580.
- Do not add multiplayer, pedestrians, a walkable player, or online services.
- Do not add GitHub Actions; verification runs locally to preserve the user's CI budget.
- Core systems must be modular, data-driven, independently testable, and expandable.
- Use one meaningful commit per independently reviewable task, not micro-commits.

---

## Planned file structure

```text
project.godot
src/
  bootstrap/
    main.gd
    main.tscn
  core/
    app_events.gd
    logger.gd
  input/
    input_router.gd
    input_profile.gd
  settings/
    game_settings.gd
    settings_service.gd
  persistence/
    save_data.gd
    save_service.gd
  assets/
    asset_record.gd
    asset_registry.gd
  benchmark/
    benchmark_controller.gd
    benchmark_scene.tscn
tests/
  smoke/test_project_contract.gd
  unit/test_input_profile.gd
  unit/test_game_settings.gd
  unit/test_save_service.gd
  unit/test_asset_registry.gd
tools/verify/verify.ps1
docs/superpowers/specs/2026-08-06-open-world-racing-game-design.md
docs/superpowers/plans/2026-08-06-phase-0-foundation.md
```

### Task 1: Replace the legacy repository with the approved project baseline

**Files:**
- Create: `.gitattributes`
- Create: `.gitignore`
- Create: `README.md`
- Create: `project.godot`
- Create: `src/bootstrap/main.gd`
- Create: `src/bootstrap/main.tscn`
- Create: `tests/smoke/test_project_contract.gd`
- Create: `tools/verify/verify.ps1`
- Create: `docs/superpowers/specs/2026-08-06-open-world-racing-game-design.md`
- Create: `docs/superpowers/plans/2026-08-06-phase-0-foundation.md`
- Delete: every legacy repository path not listed in this task

**Interfaces:**
- Produces: a Godot project whose `application/run/main_scene` equals `res://src/bootstrap/main.tscn`
- Produces: `tools/verify/verify.ps1`, the canonical local verification entrypoint

- [ ] **Step 1: Create the clean tree in one commit**

The commit must use the previous `main` commit as its parent while replacing the complete Git tree. This preserves recoverable history and ensures hidden legacy files are not retained.

- [ ] **Step 2: Run baseline verification**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\verify\verify.ps1
```

Expected output includes:

```text
PASS: project baseline contract
PASS: repository baseline verification
```

- [ ] **Step 3: Commit**

```powershell
git add -A
git commit -m "chore: reset repository for open-world racing game"
```

### Task 2: Add the application event boundary and structured logger

**Files:**
- Create: `src/core/app_events.gd`
- Create: `src/core/logger.gd`
- Modify: `project.godot`
- Create: `tests/unit/test_logger.gd`
- Modify: `tools/verify/verify.ps1`

**Interfaces:**
- Produces: autoload `AppEvents`
- Produces: autoload `GameLogger`
- Produces: `GameLogger.info(category: StringName, message: String, context: Dictionary = {}) -> void`
- Produces: `GameLogger.warning(category: StringName, message: String, context: Dictionary = {}) -> void`
- Produces: `GameLogger.error(category: StringName, message: String, context: Dictionary = {}) -> void`
- Produces: signal `AppEvents.fatal_error(category: StringName, message: String)`

- [ ] **Step 1: Write the failing logger test**

```gdscript
extends SceneTree

func _init() -> void:
    var logger_script := load("res://src/core/logger.gd")
    var logger := logger_script.new()
    logger.info(&"phase0", "logger online", {"build": "development"})
    assert(logger.get_recent_entries().size() == 1)
    assert(logger.get_recent_entries()[0]["category"] == &"phase0")
    quit(0)
```

- [ ] **Step 2: Run it and confirm failure**

```powershell
& $env:GODOT --headless --path . --script res://tests/unit/test_logger.gd
```

Expected: failure because `logger.gd` does not exist.

- [ ] **Step 3: Implement the event boundary and logger**

`app_events.gd` declares only cross-system signals. `logger.gd` stores the latest 500 structured entries, prints readable lines, creates `user://logs`, and writes one UTF-8 log file per session.

- [ ] **Step 4: Register both autoloads**

Add:

```ini
[autoload]
AppEvents="*res://src/core/app_events.gd"
GameLogger="*res://src/core/logger.gd"
```

- [ ] **Step 5: Run the full verification script**

Expected: baseline and logger tests pass.

- [ ] **Step 6: Commit**

```powershell
git add project.godot src/core tests/unit/test_logger.gd tools/verify/verify.ps1
git commit -m "feat: add application events and structured logging"
```

### Task 3: Add typed settings and input profiles

**Files:**
- Create: `src/settings/game_settings.gd`
- Create: `src/settings/settings_service.gd`
- Create: `src/input/input_profile.gd`
- Create: `src/input/input_router.gd`
- Modify: `project.godot`
- Create: `tests/unit/test_game_settings.gd`
- Create: `tests/unit/test_input_profile.gd`
- Modify: `tools/verify/verify.ps1`

**Interfaces:**
- Produces: `GameSettings` resource with graphics, audio, camera, assist, and traffic fields
- Produces: `SettingsService.load_settings() -> GameSettings`
- Produces: `SettingsService.save_settings(settings: GameSettings) -> Error`
- Produces: `InputProfile` resource with dead zones, sensitivities, ramps, and bindings
- Produces: `InputRouter.get_steering() -> float`
- Produces: `InputRouter.get_throttle() -> float`
- Produces: `InputRouter.get_brake() -> float`
- Produces: `InputRouter.shift_up_pressed() -> bool`
- Produces: `InputRouter.shift_down_pressed() -> bool`

- [ ] **Step 1: Write tests for default settings and profile round-tripping**

Assert 1280×720 defaults, medium traffic, Forward+ compatible quality, keyboard steering ramp greater than zero, and controller steering dead zone between 0.0 and 0.5.

- [ ] **Step 2: Run tests and confirm the missing classes fail**

- [ ] **Step 3: Implement typed resources with explicit defaults**

Do not store untyped arbitrary setting dictionaries as the source of truth.

- [ ] **Step 4: Implement JSON persistence under `user://settings.json`**

Unknown fields are ignored. Missing fields retain code defaults. Invalid enum-like strings are rejected and logged.

- [ ] **Step 5: Configure canonical input actions**

Actions: `drive_steer_left`, `drive_steer_right`, `drive_throttle`, `drive_brake`, `drive_handbrake`, `drive_shift_up`, `drive_shift_down`, `drive_reset`, `camera_next`, `pause`.

- [ ] **Step 6: Verify tests and commit**

```powershell
git add project.godot src/settings src/input tests/unit tools/verify/verify.ps1
git commit -m "feat: add settings and input foundations"
```

### Task 4: Add versioned and atomic save persistence

**Files:**
- Create: `src/persistence/save_data.gd`
- Create: `src/persistence/save_service.gd`
- Create: `tests/unit/test_save_service.gd`
- Modify: `project.godot`
- Modify: `tools/verify/verify.ps1`

**Interfaces:**
- Produces: `SaveData.CURRENT_VERSION: int`
- Produces: `SaveService.load_slot(slot: int) -> SaveData`
- Produces: `SaveService.write_slot(slot: int, data: SaveData) -> Error`
- Produces: `SaveService.delete_slot(slot: int) -> Error`
- Produces: `SaveService.has_slot(slot: int) -> bool`

- [ ] **Step 1: Write tests for fresh, round-trip, backup, and corrupt-save behavior**

The test writes to an isolated `user://test-save/` directory and verifies that a failed parse preserves the last valid `.bak` copy.

- [ ] **Step 2: Run tests and confirm failure**

- [ ] **Step 3: Implement `SaveData` with explicit approved fields**

Include version, money, reputation, licenses, championships, owned vehicles, tuning, upgrades, damage, event results, discovered locations, unlocked regions, current vehicle, and settings reference.

- [ ] **Step 4: Implement atomic writes**

Write `slot-N.tmp`, flush and close it, copy the existing valid save to `slot-N.bak`, then rename the temporary file to `slot-N.json`. Never mutate the live file in place.

- [ ] **Step 5: Implement migration dispatch**

`migrate(payload: Dictionary, from_version: int) -> Dictionary` applies sequential version migrations and rejects future versions.

- [ ] **Step 6: Verify and commit**

```powershell
git add project.godot src/persistence tests/unit/test_save_service.gd tools/verify/verify.ps1
git commit -m "feat: add versioned atomic save service"
```

### Task 5: Add the asset registry contract

**Files:**
- Create: `src/assets/asset_record.gd`
- Create: `src/assets/asset_registry.gd`
- Create: `data/assets/.gitkeep`
- Create: `tests/unit/test_asset_registry.gd`
- Modify: `project.godot`
- Modify: `tools/verify/verify.ps1`

**Interfaces:**
- Produces: `AssetRecord` resource with id, kind, source, license status, path, scale, orientation, polygon count, material count, texture resolution, collision status, LOD status, rig status, cockpit suitability, cleanup notes, and runtime status
- Produces: `AssetRegistry.register(record: AssetRecord) -> Error`
- Produces: `AssetRegistry.get_record(id: StringName) -> AssetRecord`
- Produces: `AssetRegistry.validate_record(record: AssetRecord) -> PackedStringArray`

- [ ] **Step 1: Write tests rejecting duplicate IDs and missing required fields**

- [ ] **Step 2: Run and confirm failure**

- [ ] **Step 3: Implement records and registry**

IDs are stable lowercase namespaced strings such as `vehicle.prototype_rwd_coupe`. Registration rejects duplicate IDs, nonexistent runtime paths, nonpositive scale, and unknown asset kinds.

- [ ] **Step 4: Add JSON import/export for audit reports**

- [ ] **Step 5: Verify and commit**

```powershell
git add project.godot src/assets data/assets tests/unit/test_asset_registry.gd tools/verify/verify.ps1
git commit -m "feat: add auditable asset registry"
```

### Task 6: Add a reproducible performance benchmark scene

**Files:**
- Create: `src/benchmark/benchmark_controller.gd`
- Create: `src/benchmark/benchmark_scene.tscn`
- Create: `tests/smoke/test_benchmark_contract.gd`
- Modify: `tools/verify/verify.ps1`
- Modify: `README.md`

**Interfaces:**
- Produces: `BenchmarkController.begin_run(duration_seconds: float) -> void`
- Produces: signal `benchmark_completed(report: Dictionary)`
- Report keys: `average_fps`, `minimum_fps`, `maximum_frame_ms`, `frame_count`, `duration_seconds`, `renderer`, `resolution`

- [ ] **Step 1: Write the benchmark contract test**

Assert the scene loads, contains a `BenchmarkController`, and emits a report with every required key after a short headless run.

- [ ] **Step 2: Run and confirm failure**

- [ ] **Step 3: Implement a deterministic baseline workload**

Use repeated instanced meshes, lights, static collisions, and camera movement representative of an early countryside scene. Do not claim the benchmark represents final-world performance.

- [ ] **Step 4: Add `-Benchmark` support to `verify.ps1`**

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\verify\verify.ps1 -Benchmark
```

Write the JSON report to `reports/benchmark/latest.json`.

- [ ] **Step 5: Verify and commit**

```powershell
git add src/benchmark tests/smoke/test_benchmark_contract.gd tools/verify/verify.ps1 README.md
git commit -m "feat: add phase zero performance benchmark"
```

### Task 7: Complete the Phase 0 quality gate

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/plans/2026-08-06-phase-0-foundation.md`
- Create: `docs/status/phase-0-report.md`

**Interfaces:**
- Consumes: all Phase 0 services and verification commands
- Produces: a reproducible Phase 0 completion report

- [ ] **Step 1: Run the full local gate**

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\verify\verify.ps1 -Benchmark
```

- [ ] **Step 2: Record exact engine, renderer, resolution, CPU, GPU, test totals, and benchmark output**

- [ ] **Step 3: Confirm no placeholder scan failures**

```powershell
Get-ChildItem -Recurse -File | Select-String -Pattern 'TBD|TODO|FIXME|implement later'
```

Expected: no unresolved implementation placeholders in production files.

- [ ] **Step 4: Confirm repository cleanliness**

```powershell
git status --short
```

Expected: no output.

- [ ] **Step 5: Commit the completion report**

```powershell
git add README.md docs/superpowers/plans/2026-08-06-phase-0-foundation.md docs/status/phase-0-report.md
git commit -m "docs: record phase zero verification"
```

## Plan self-review

- Specification coverage: Phase 0 project contract, verification, input, settings, logging, saves, asset registry, and performance benchmark are assigned to explicit tasks.
- Scope: vehicle physics, world generation, racing, AI, career, police, and audio remain outside Phase 0 and require separate plans.
- Placeholder scan: no undefined implementation steps, TBD markers, or unspecified interfaces remain.
- Type consistency: service names and method signatures are consistent across tasks.
