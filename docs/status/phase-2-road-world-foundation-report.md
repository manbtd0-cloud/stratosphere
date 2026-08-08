# Phase 2 Road / World Foundation — Status Report

**Date:** 2026-08-08
**Branch:** `agent/phase-2-road-world-foundation`
**Base:** Phase 1 head `a61a30d7a1ebc03f4d8d087c073f97d8a76e7806`
**Engine:** Godot 4.7.1 stable (`a13da4feb`)
**Local Linux gate:** PASS
**Native Windows gate:** PASS

## Delivered foundation

- 6144 m × 6144 m logical world address space.
- 12 × 12 deterministic grid of 512 m cells (`144` stable cell definitions).
- Stable save-safe world cell IDs and coordinate parsing.
- Game-owned world cell definitions independent of terrain implementation.
- Authoritative road graph with junction and segment resources.
- Reusable `highway`, `rural_two_lane`, `hill_two_lane`, `service`, and `dirt_trail` profiles.
- Deterministic Curve3D road sampling with stable frames and accumulated distance.
- Generated road/shoulder render geometry plus collision from the same segment data.
- Phase 1-compatible `surface_id` metadata on road, shoulder, terrain, and proving-pad colliders.
- Shared `SurfaceResolver` preserving `asphalt_dry`, `asphalt_wet`, `gravel`, `dirt`, and `grass`.
- Replaceable `TerrainBackendAdapter` plus plugin-free built-in terrain fallback.
- Predictive world streaming policy with gameplay, visual, prediction, and unload-hysteresis sets.
- Runtime stream manager with deterministic load/unload ownership and duplicate protection.
- Mixed proving-region network: outer highway loop, sweeping rural loop, elevated hill branch, service road, dirt cut-through, and roadside test cluster.
- Explicit junction patches for the current proving routes.
- Deterministic sun/sky baseline and simple shared-material environment presentation.
- Standalone proving-region scene launched through the preserved Phase 0 bootstrap entry point.
- Phase 1 prototype RWD coupe integrated into the world with active streaming.
- Dedicated gravel/dirt/grass proving pads used to verify vehicle/world surface integration without retuning Phase 1 physics.
- World validation and deterministic high-speed stream-probe tooling.

No Terrain3D dependency, paid asset, native runtime extension, pedestrian system, traffic AI, race rules, or floating-origin system was introduced.

## Automated evidence — Linux

Full command:

`GODOT_BIN=<Godot 4.7.1 Linux binary> ./tools/verify/verify.sh`

Result:

- Repository tests: **83/83 PASS**
  - Previous Phase 0/1 manifest entries preserved: **67**
  - New Phase 2 contracts: **16**
- 60 Hz vehicle tick probe: **21.002768 m/s**
- 120 Hz vehicle tick probe: **21.683588 m/s**
- Relative speed difference: **3.14%**
- Allowed tick-rate gate: **12%**
- Final verifier result: `PASS: repository verification (83 tests + physics tick matrix)`
- Verifier rejects script errors, failed assertions, leaked ObjectDB instances, and resources left in use at exit.

## Deterministic world stream probe

Command:

`godot --headless --fixed-fps 120 --path . --script res://tools/benchmark/run_world_stream_probe.gd`

Measured logical results:

- Route steps: **15**
- Maximum gameplay cells requested: **9**
- Maximum visual cells requested: **49**
- Maximum predictive cells requested: **9**
- Maximum hysteresis-retained cells: **13**
- Route steps with forward predictive loading: **15/15**
- Deterministic checksum: `b7a2d80c5fcd5814b6b90bb59645506dce1b94de9666c832c36c0b4c350c2f2a`

These are logical streaming-contract measurements only. They are not GPU frame-rate or VRAM claims.

## World content contract

The logical 6.144 km square address space exists to exercise scalable IDs and streaming. Phase 2 deliberately does **not** art-fill all 37.75 km². High-detail authored roads and environment content stay concentrated in a representative subset of cells so later phases can scale quality rather than inherit a giant low-quality map.

The proving region currently includes:

- closed outer high-speed highway loop
- closed sweeping rural loop
- technical hill branch reaching approximately 88 m world elevation
- service-road branch
- dirt cut-through
- grass/off-road terrain
- roadside modular test cluster
- deterministic player spawn on asphalt
- explicit loose-surface vehicle test pads

## Automated evidence — Windows

- Official Godot 4.7.1 native Windows runner: **PASS**
- Repository tests: **83/83 PASS**
- 60/120 Hz physics tick matrix: **PASS**
- Phase 1 vehicle tick-rate difference remains **3.14%**, below the **12%** gate.

## Remaining physical/release checkpoints

- Subjective driving feel and target-GPU visual/performance review remain physical hardware checkpoints.
- Release provenance for the current 350Z development source remains intentionally unresolved.
