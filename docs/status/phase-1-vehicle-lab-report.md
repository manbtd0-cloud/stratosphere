# Phase 1 Vehicle Laboratory Status

**Date:** 2026-08-07  
**Engine:** Godot 4.7.1 stable `a13da4feb`  
**Physics:** Jolt, custom `RigidBody3D` vehicle solver  
**Platforms:** Windows x86_64 and Linux x86_64 contracts

## Implemented foundation

- Typed body, wheel, suspension, tire, surface, engine, clutch, gearbox, differential, brake, assist, aero and damage resources.
- Custom four-wheel Jolt chassis using three suspension/contact rays per wheel.
- Fixed-rate ~480 Hz wheel angular dynamics independent of outer physics tick.
- Combined-slip tire forces with load sensitivity, relaxation, aligning torque, rolling resistance and slip-energy telemetry.
- Dry, wet, gravel, dirt and grass surface behavior.
- Six-speed manual/automatic transmission, neutral, reverse, clutch and limited-slip differential.
- ABS, time-based TCS, stability control and bounded counter-steer assistance.
- Mechanical rear handbrake.
- Collision-driven typed damage and repair/reset hooks.
- Chase, hood, bumper and cockpit camera modes with chase collision avoidance.
- Visual wheel steering/suspension/spin and cockpit steering-wheel hook.
- Live telemetry overlay and versioned JSON/JSONL/CSV telemetry recorder with vehicle-definition SHA-256 provenance.
- Measured Vehicle Lab covering straights, dry/wet braking, skidpads, slalom, handling loop, bump course, gradients, side slope, loose surfaces, jump/landing, recovery and visual inspection.
- 350Z source fingerprint policy and deterministic Blender preparation entrypoint.

## Measured Linux headless recovery baseline

The current greybox tune is not the final subjective handling tune, but it is physically bounded and useful for regression testing:

- 0–100 km/h: approximately 7.48 s.
- 100–0 km/h: approximately 41.56 m after a natural acceleration run so wheel RPM and driveline state are consistent.
- independent 60 Hz five-second launch: 20.084654 m/s.
- independent 120 Hz five-second launch: 20.942167 m/s.
- relative 60/120 difference: approximately 4.09%, below the 12% hard gate.
- normal flat-road ride: four wheel contacts retained and no spurious chassis-impact damage.

## Verification policy

The shared manifest contains the original 12 Phase 0 contracts plus all Phase 1 contracts. Windows and Linux wrappers reject:

- non-zero Godot exits;
- GDScript `SCRIPT ERROR` output;
- explicit `ERROR: FAIL` assertions;
- leaked Godot objects/resources;
- a 60/120 Hz speed difference above 12%.

## Remaining non-code checkpoints

- Install Blender in an asset-processing environment and run `tools/vehicle/prepare_350z.py` on the user-provided working source.
- Consolidate the 44 source materials to 8–14 production material families without losing cockpit/exterior quality.
- Produce and inspect LOD0–LOD3 GLBs; the high-detail modifier source remains bake/reference only.
- Replace/rebuild missing author-machine texture dependencies.
- Verify release-safe licensing or replace/fictionalize the source before any public/commercial distribution.
- Perform subjective keyboard/controller handling tuning on physical Windows/Linux hardware and record telemetry runs.
