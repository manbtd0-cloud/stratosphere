# Phase 1 Vehicle Laboratory Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-grade custom RWD vehicle stack, measured Vehicle Lab, telemetry system, and deterministic 350Z preparation pipeline on Godot 4.7.1/Jolt.

**Architecture:** The car is a custom `RigidBody3D` whose four wheel contacts are solved independently from typed resources. Suspension, tires, engine, clutch, gearbox, LSD, brakes and assists stay modular and testable; presentation consumes telemetry rather than owning physics. The 350Z is a visual source only and can be replaced without changing physics.

**Tech Stack:** Godot 4.7.1 Forward+, Jolt Physics, GDScript, Blender Python preparation script, Linux Bash and Windows PowerShell verification.

## Global Constraints

- Windows x86_64 and Linux x86_64 remain first-class targets.
- Physics behavior must remain within 12% in the independent 60/120 Hz launch matrix.
- Do not use `VehicleBody3D`/`VehicleWheel3D` as the production solver.
- Keep hidden rigid-body damping disabled; aerodynamic and rolling losses must be explicit.
- Do not commit the user-provided 350Z source archive or Blend files.
- High-detail 350Z source is bake/reference only.
- Every behavior change is covered by a failing test before implementation.

---

### Task 1: Typed vehicle data and pure solvers

**Files:** `src/vehicle/data/**`, `src/vehicle/physics/*_solver.gd`, `src/vehicle/validation/**`, `tests/phase1/test_01_*` through `test_25_*`.

**Produces:** suspension/tire/surface/engine/clutch/transmission/differential/brake/assist/damage contracts and a validated deterministic vehicle-definition fingerprint.

- [x] Write red tests for each solver and validation boundary.
- [x] Implement suspension support, damping, bump stops and anti-roll.
- [x] Implement combined-slip tires with relaxation, load sensitivity and typed surfaces.
- [x] Implement engine, clutch, six-speed/reverse gearbox, LSD and brakes.
- [x] Implement bounded ABS, time-based TCS, stability and counter-steer outputs.
- [x] Implement typed damage state, repair and definition validation/fingerprint.
- [x] Verify all 25 pure/data contracts.

### Task 2: Production `RigidBody3D` chassis

**Files:** `src/vehicle/physics/vehicle_controller.gd`, `scenes/vehicle/prototype_rwd_coupe.tscn`, `tests/phase1/test_26_*`, `test_28_*` through `test_36_*`, `test_38_*` through `test_41_*`.

**Produces:** four-wheel custom Jolt chassis with three-ray wheel contacts, fixed-rate wheel dynamics, live powertrain/assists/damage and deterministic reset.

- [x] Put the chassis collision directly under the `RigidBody3D`.
- [x] Replace Godot linear/angular damping with explicit zero damping.
- [x] Solve wheel angular dynamics at ~480 Hz independent of outer physics tick.
- [x] Apply suspension/tire forces at contact positions.
- [x] Keep rolling resistance separate from wheel reaction torque.
- [x] Integrate clutch/manual/automatic/reverse/neutral behavior.
- [x] Integrate ABS/TCS/stability/counter-steer without direct chassis rotation.
- [x] Feed real body-contact impulses into damage.
- [x] Verify acceleration, braking, surfaces, handbrake, reset, damage, stability and ground-contact contracts.
- [x] Verify independent 60/120 Hz matrix stays below 12% relative speed difference.

### Task 3: Vehicle presentation and telemetry

**Files:** `src/vehicle/presentation/**`, `src/vehicle/telemetry/**`, `src/vehicle/recovery/**`, `tests/phase1/test_37_camera_modes.gd`.

**Produces:** chase/hood/bumper/cockpit modes, collision-safe chase camera, visual wheel/steering hooks, live HUD, JSONL/CSV/JSON telemetry and recovery service.

- [x] Add four camera modes and speed-sensitive chase presentation.
- [x] Add chase collision avoidance.
- [x] Animate front visual steering, suspension and wheel spin from physics telemetry.
- [x] Add cockpit steering-wheel pivot hook.
- [x] Record per-wheel slip/load/surface/ABS and vehicle drivetrain/assist/damage state.
- [x] Bind telemetry output to vehicle-definition SHA-256 and Godot version.

### Task 4: Measured Vehicle Lab

**Files:** `src/labs/vehicle_lab_builder.gd`, `scenes/labs/vehicle_lab.tscn`, `tests/phase1/test_27_lab_contract.gd`, handling/surface integration tests.

**Produces:** setup pad, long straight, dry/wet braking, 30/60 m skidpads, slalom, handling loop, bump course, 10%/20% gradients, side slope, gravel/dirt/grass lanes, jump/landing, recovery zone and visual studio.

- [x] Build deterministic tagged surfaces and measurement geometry.
- [x] Spawn the production prototype car and live telemetry overlay.
- [x] Verify 10-second lab stability and persistent wheel contact.

### Task 5: 350Z source pipeline

**Files:** `assets/source/vehicle/prototype_rwd_coupe/source_manifest.json`, `tools/vehicle/prepare_350z.py`, `docs/research/2026-08-07-350z-source-audit.md`.

**Produces:** source fingerprints, runtime budget policy and Blender automation entrypoint without committing the source binary.

- [x] Fingerprint source archive and both primary Blend files.
- [x] Record release-license status as unverified.
- [x] Encode LOD/material/axis/separable-part acceptance budgets.
- [x] Add Blender preparation script with hard runtime-source and budget gates.
- [x] Syntax-check the script without claiming Blender execution.

### Task 6: Cross-phase verification and publication

**Files:** `project.godot`, `src/input/input_router.gd`, `tests/test_manifest.txt`, `tools/verify/verify.sh`, `tools/verify/verify.ps1`, `docs/status/phase-1-vehicle-lab-report.md`.

**Produces:** 53+ shared contracts and separate 60/120 matrix on both verification wrappers.

- [x] Keep all 12 Phase 0 tests in the shared manifest.
- [x] Add all Phase 1 contracts.
- [x] Make wrappers reject nonzero exits, GDScript errors, failed assertions and resource/object leaks.
- [x] Add cross-process tick-rate matrix with 12% hard limit.
- [x] Run final clean Linux gate after repository cleanup.
- [x] Publish one coherent implementation commit to `agent/phase-1-vehicle-lab`.
