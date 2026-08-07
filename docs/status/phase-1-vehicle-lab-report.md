# Phase 1 Vehicle Laboratory Status

**Date:** 2026-08-07  
**Engine:** Godot 4.7.1 stable `a13da4feb`  
**Physics:** Jolt, custom `RigidBody3D` vehicle solver  
**Platforms:** Windows x86_64 and Linux x86_64 contracts

## Implemented foundation

- Custom four-wheel Jolt chassis with three contact rays per wheel, suspension, anti-roll, combined-slip tires, relaxation and typed surfaces.
- Engine, clutch, six-speed transmission, neutral/reverse, LSD, ABS, time-based TCS, stability control, counter-steer, handbrake, damage and recovery.
- Chase, hood, bumper and cockpit cameras; keyboard and controller driving; player-facing camera cycling.
- Live telemetry recording plus a structured Vehicle Lab instrument HUD with speed, gear, RPM, assists, damage and four-wheel slip/load/surface readouts.
- Measured Vehicle Lab covering straight-line, braking, skidpad, slalom, bumps, gradients, loose surfaces and recovery.
- Vehicle Lab presentation layer with distinct dry/wet/gravel/dirt/grass materials, deterministic environment/sun, distance/braking markers, slalom cones and a dedicated key/fill-lit visual studio while preserving the original physics surface IDs and collision geometry.
- Audited 350Z runtime hierarchy with real wheel/cockpit animation, greybox fallback and automatic LOD selection at 14/32/65 m with 2.5 m hysteresis.
- Deterministic Blender 5.2.0 runtime pipeline with four LODs, 14 PBR material families and embedded tire/carbon/decal texture detail.

## Measured Linux headless baseline

- 0–100 km/h: approximately 7.48 s.
- 100–0 km/h: approximately 41.56 m after a natural acceleration run.
- independent 60 Hz five-second launch: 20.084654 m/s.
- independent 120 Hz five-second launch: 20.942167 m/s.
- relative 60/120 difference: approximately 4.09%, below the 12% hard gate.

## Starter-car asset pipeline

Final deterministic textured development outputs:

- LOD0: 247,186 triangles / 7,976,076 bytes.
- LOD1: 128,355 triangles / 5,123,824 bytes.
- LOD2: 49,414 triangles / 2,979,408 bytes.
- LOD3: 18,592 triangles / 2,101,008 bytes.
- 14 runtime materials.
- 4 embedded images / 4 glTF textures.
- tire and carbon normal detail plus plate base-color/normal detail.
- glTF-safe metallic paint, transparent glass/lenses, metals, brakes, leather and interior materials.
- all four textured GLBs import in Godot 4.7.1 and preserve the existing semantic wheel/cockpit/LOD bindings.

`tools/vehicle/prepare_350z.py` remains the stable geometry/LOD generator. `tools/vehicle/prepare_350z_textured.py` is the production development entrypoint for materialized exports and validates the embedded GLB texture payload before success.

Derived GLBs remain intentionally untracked while source licensing is `unverified_for_release`; the source fingerprints, deterministic generators and exact output hashes are committed so the development assets are reproducible.

## Verification policy

The shared manifest contains 60 contracts: 12 Phase 0 plus 48 Phase 1. The strengthened 350Z source contract requires matching geometry/material generator fingerprints and an audited embedded texture payload.

Focused Godot 4.7.1 verification on the exact textured GLBs passed source metadata, runtime LOD loading/switching, semantic wheel mapping, real wheel/cockpit animation, greybox fallback, controller input, camera input, automatic LOD and keyboard-input regression. The new lab-presentation contract verifies explicit surface materials, deterministic lighting, measurement markers, visual-studio lighting, preserved physics surface IDs and preserved colliders. The telemetry-HUD contract verifies the structured speed/gear/RPM/assist and wheel readouts from a real telemetry snapshot.

## Remaining checkpoints

- Run the complete shared 60-contract repository gate on a fully reconstructed exact branch tree before Phase 1 closure.
- Perform subjective keyboard/controller handling tuning on physical Windows/Linux hardware and record telemetry runs.
- Run native GPU visual/performance review with the generated LOD0-L3 assets on target-class hardware.
- Verify release-safe licensing or replace/fictionalize the source before public/commercial distribution.
