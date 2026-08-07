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
- Deterministic Blender 5.2.0 starter-car pipeline with four production LODs and 14 runtime material families.

## Measured Linux headless baseline

- 0–100 km/h: approximately 7.48 s.
- 100–0 km/h: approximately 41.56 m after a natural acceleration run.
- independent 60 Hz five-second launch: 20.084654 m/s.
- independent 120 Hz five-second launch: 20.942167 m/s.
- relative 60/120 difference: approximately 4.09%, below the 12% hard gate.
- normal flat-road ride: four wheel contacts retained and no spurious chassis-impact damage.

## Starter-car asset pipeline result

Blender 5.2.0 LTS processed the selected `350z.blend` working master twice with byte-identical output hashes.

- LOD0: 247,186 triangles.
- LOD1: 128,355 triangles.
- LOD2: 49,414 triangles.
- LOD3: 18,592 triangles.
- runtime materials: 14.
- independent FL/FR/RL/RR wheel pivots and a separate steering-wheel node.
- glTF-safe transparent window and light-lens materials.
- all four GLBs import successfully in Godot 4.7.1.

Derived model binaries remain intentionally untracked while source licensing is `unverified_for_release`. The generator, source fingerprints and exact output hashes are committed so the assets can be reproduced deterministically.

## Verification policy

The shared manifest contains the original 12 Phase 0 contracts plus all Phase 1 contracts. Windows and Linux wrappers reject non-zero Godot exits, GDScript script errors, failed assertions, leaked objects/resources, and a 60/120 Hz speed difference above 12%.

## Remaining checkpoints

- Verify release-safe licensing or replace/fictionalize the source before public/commercial distribution.
- Perform subjective keyboard/controller handling tuning on physical Windows/Linux hardware and record telemetry runs.
- Run native GPU visual/performance review with the generated LOD0–LOD3 assets on target-class hardware.
