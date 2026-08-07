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
- Keyboard driving retains progressive steering/throttle/brake smoothing.
- Controller driving is wired through left-stick steering, analog triggers, A handbrake, X clutch, shoulder-button shifting and Y camera cycling.
- Camera cycling is player-facing on keyboard C and controller Y.
- Live telemetry overlay and versioned JSON/JSONL/CSV telemetry recorder with vehicle-definition SHA-256 provenance.
- Measured Vehicle Lab covering straights, dry/wet braking, skidpads, slalom, handling loop, bump course, gradients, side slope, loose surfaces, jump/landing, recovery and visual inspection.
- Deterministic Blender 5.2.0 starter-car pipeline with four production LODs and 14 runtime material families.
- Runtime 350Z visual adapter with semantic body/cockpit/glass/wheel bindings and an animated greybox fallback for clones without local runtime GLBs.
- Automatic 350Z LOD selection uses 14 m / 32 m / 65 m distance thresholds, 2.5 m hysteresis and a 0.20 s check interval.
- Real GLB wheel animation is driven by physics telemetry: suspension delta, wheel RPM, front steering and cockpit steering-wheel motion.
- Scene-specific wheelbase/track use the audited 350Z pivots while the calibrated 0.306 m effective tire radius and collision proxy remain unchanged.

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

The production scene expects local development GLBs at `res://assets/runtime/vehicle/prototype_rwd_coupe/`. The runtime visual rig corrects the imported model orientation by 180 degrees, applies the audited vertical presentation offset, remaps physical wheel IDs to the rotated semantic hierarchy and automatically selects LOD from the active gameplay camera.

Derived model binaries remain intentionally untracked while source licensing is `unverified_for_release`. The generator, source fingerprints and exact output hashes are committed so the assets can be reproduced deterministically. If the GLBs are absent, the scene remains functional through the animated greybox fallback.

## Verification policy

The shared manifest now contains 58 contracts: the original 12 Phase 0 contracts plus 46 Phase 1 contracts. Windows and Linux wrappers reject non-zero Godot exits, GDScript script errors, failed assertions, leaked objects/resources, and a 60/120 Hz speed difference above 12%.

Focused Godot 4.7.1 verification additionally exercised the real generated GLBs and covered runtime LOD loading/switching, semantic wheel remapping, suspension/steering/spin animation, cockpit steering animation, animated greybox fallback, controller action bindings, analog input shaping, keyboard-input regression and player camera cycling.

## Remaining checkpoints

- Verify release-safe licensing or replace/fictionalize the source before public/commercial distribution.
- Perform subjective keyboard/controller handling tuning on physical Windows/Linux hardware and record telemetry runs.
- Run native GPU visual/performance review with the generated LOD0-L3 assets on target-class hardware.
