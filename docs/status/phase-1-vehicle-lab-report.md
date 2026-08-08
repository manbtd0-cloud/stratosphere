# Phase 1 Vehicle Laboratory Status

**Date:** 2026-08-08  
**Engine:** Godot 4.7.1 stable `a13da4feb`  
**Physics:** Jolt, custom `RigidBody3D` vehicle solver  
**Platforms:** Windows x86_64 and Linux x86_64 contracts

## Implemented foundation

- Custom four-wheel Jolt chassis with three contact rays per wheel, suspension, anti-roll, combined-slip tires, relaxation and typed surfaces.
- Engine, clutch, six-speed transmission, neutral/reverse, LSD, ABS, time-based TCS, stability control, counter-steer, handbrake, damage and recovery.
- Chase, hood, bumper and cockpit cameras; keyboard and controller driving; player-facing camera cycling.
- Structured Vehicle Lab HUD plus versioned JSON/JSONL/CSV telemetry recording.
- Measured Vehicle Lab with readable dry/wet/gravel/dirt/grass presentation, deterministic sun/environment, measurement markings and a dedicated inspection studio while preserving physics surface IDs/colliders.
- Audited 350Z runtime hierarchy with real wheel/cockpit animation, greybox fallback and automatic LOD selection at 14/32/65 m with 2.5 m hysteresis.
- Deterministic Blender 5.2.0 runtime pipeline with four LODs, 14 PBR material families and embedded tire/carbon/decal texture detail.
- Telemetry-only audio/effects bridges expose RPM/load/gear/surface/slip/impact/exhaust/skid/damage state without coupling presentation back into physics.
- Runtime brake-light emission follows brake telemetry on the real `runtime_light_red` material and automatically rebinds after LOD replacement when local development GLBs are present; clean clones verify the greybox fallback path instead of requiring untracked binaries.
- Reusable `VehicleAssetValidator` enforces LOD/material/texture/import/semantic/scene contracts for future cars and keeps release licensing as a separate explicit gate.
- `VehicleTelemetryEnricher` derives suspension velocity and surface wetness per wheel plus frame/physics cadence and enrichment cost without modifying the vehicle force path.
- `VehicleRecoveryCoordinator` maintains a last-known-safe upright/grounded reset transform and provides delayed automatic recovery only for settled inverted vehicles.

## Measured headless baseline

- 0–100 km/h: approximately 7.48 s in the established Phase 1 Linux handling baseline.
- 100–0 km/h: approximately 41.56 m after a natural acceleration run in the established Phase 1 Linux handling baseline.
- closure-matrix 60 Hz five-second launch: 21.002768 m/s.
- closure-matrix 120 Hz five-second launch: 21.683588 m/s.
- closure-matrix relative 60/120 difference: 3.14%, below the 12% hard gate.

## Starter-car asset pipeline

Final deterministic textured development outputs:

- LOD0: 247,186 triangles / 7,976,076 bytes.
- LOD1: 128,355 triangles / 5,123,824 bytes.
- LOD2: 49,414 triangles / 2,979,408 bytes.
- LOD3: 18,592 triangles / 2,101,008 bytes.
- 14 runtime materials.
- 4 embedded images / 4 glTF textures.
- tire and carbon normal detail plus plate base-color/normal detail.
- all four textured GLBs import in Godot 4.7.1 and preserve semantic wheel/cockpit/LOD bindings.

`tools/vehicle/prepare_350z.py` remains the stable geometry/LOD generator. `tools/vehicle/prepare_350z_textured.py` is the production development entrypoint for materialized exports and validates the embedded GLB texture payload before success.

Derived GLBs remain intentionally untracked while source licensing is `unverified_for_release`; source fingerprints, deterministic generators and exact output hashes are committed so development assets are reproducible.

## Cross-platform automated closure gate

The shared manifest contains 67 contracts: 12 Phase 0 plus 55 Phase 1. The 350Z source contract requires matching geometry/material generator fingerprints and an audited embedded texture payload.

On 2026-08-08, the exact implementation/test tree at `8251b85f308c84f91e1e18b08346a0d7a73cc48b` was checked out from GitHub and run with official Godot 4.7.1 on both hosted operating systems:

- Ubuntu 24.04: **67/67 contracts passed**, project import passed, leak/error gate passed, and the independent 60/120 matrix passed at 3.14% relative difference.
- Windows Server 2025: **67/67 contracts passed**, project import passed, leak/error gate passed, and the independent 60/120 matrix passed at the same 3.14% relative difference.
- 60 Hz probe: 21.002768 m/s.
- 120 Hz probe: 21.683588 m/s.
- hard allowed difference: 12%.

The first closure attempt exposed two verification defects and they were corrected before the successful run: the shared brake-light contract had incorrectly required intentionally untracked development GLBs, and the Windows wrapper depended on `$LASTEXITCODE` under strict mode. The successful run used the clean-clone-aware presentation contract and an explicit native-process exit-code path on Windows.

This closes the automated cross-platform Phase 1 repository gate. Hosted headless runners are not evidence for subjective driving feel or target-GPU frame-time budgets.

## Remaining physical/release checkpoints

- Perform subjective keyboard/controller handling review on physical Windows/Linux hardware and record representative telemetry runs.
- Run native GPU visual/performance review with LOD0–LOD3 on target-class hardware; confirm the player-vehicle physics/presentation budgets using real frame-time profiling.
- Verify release-safe licensing or replace/fictionalize the selected source before public/commercial distribution.
