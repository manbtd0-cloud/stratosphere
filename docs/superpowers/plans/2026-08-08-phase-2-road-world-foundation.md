# Phase 2 Road / World Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a scalable 512 m cell world grid, authoritative spline-road graph, surface-aware road/terrain geometry, plugin-independent terrain backend, predictive world streaming, and a mixed proving-region scene that integrates the Phase 1 RWD coupe.

**Architecture:** Phase 2 is data-first. Pure classes own grid math, road definitions, spline sampling, validation, and streaming policy; scene nodes own terrain/road instances and lifecycle. Terrain rendering sits behind an adapter, while road collision uses the existing `surface_id` metadata contract so Phase 1 vehicle physics remains authoritative and unchanged except for shared resolver cleanup if regression-safe.

**Tech Stack:** Godot 4.7.1 stable, GDScript 2.0, Forward+, Jolt, repository-owned headless tests, Bash/PowerShell verification.

## Global Constraints

- Base implementation branch is `agent/phase-2-road-world-foundation`, forked from Phase 1 head `a61a30d7a1ebc03f4d8d087c073f97d8a76e7806`.
- Preserve all 67 existing Phase 0/1 tests.
- Cell size is exactly 512.0 m; address grid is 12 × 12, centered with logical coordinates -6 through +5.
- Development address space is 6144 m × 6144 m; high-detail authored proving footprint remains concentrated rather than art-filling the whole space.
- Hybrid terrain architecture: game systems own identity/streaming/surfaces; no mandatory Terrain3D dependency.
- Road graph is authoritative for geometry and later navigation/race consumers.
- Surface IDs remain `asphalt_dry`, `asphalt_wet`, `gravel`, `dirt`, and `grass`.
- Linux and Windows are both supported; Linux is the main iterative verifier and Windows runs at milestone closure.
- No paid car/environment/plugin dependency.
- No pedestrians.
- TDD is mandatory: new production behavior is preceded by a failing contract.
- Minimize pushes and GitHub Actions; group coherent work and use one remote bootstrap only if local binaries/tree are unavailable.

---

### Task 1: World grid, cell IDs, and cell definitions

**Files:**
- Create: `src/world/grid/world_grid.gd`
- Create: `src/world/grid/world_cell_definition.gd`
- Create: `tests/phase2/test_01_world_grid.gd`
- Create: `tests/phase2/test_02_world_cell_definition.gd`

**Interfaces:**
- Produces: `WorldGrid.new(cell_size: float = 512.0, half_extent_cells: int = 6)`
- Produces: `world_to_coord(position: Vector3) -> Vector2i`
- Produces: `coord_to_center(coord: Vector2i) -> Vector3`
- Produces: `coord_to_id(coord: Vector2i) -> StringName`
- Produces: `id_to_coord(cell_id: StringName) -> Vector2i`
- Produces: `is_valid_coord(coord: Vector2i) -> bool`
- Produces: `neighbors(coord: Vector2i, radius: int = 1) -> Array[Vector2i]`
- Produces: `WorldCellDefinition.validation_errors(grid: WorldGrid) -> PackedStringArray`

- [ ] Write `test_01_world_grid.gd` first. Assert origin maps to `(0,0)`, negative boundaries floor correctly, the address-space edge maps to valid `(-6..5)` coordinates, center conversion round-trips, IDs are deterministic (`world.proving.c-03_p02` style), parsing round-trips, invalid coordinates reject, and neighbor queries clip to bounds.
- [ ] Run the single test and verify RED because `WorldGrid` does not exist.
- [ ] Implement only the grid math/ID behavior required by the test.
- [ ] Run the test and verify GREEN.
- [ ] Write `test_02_world_cell_definition.gd` first. Assert matching ID/coord validates, mismatches fail, road IDs are deduplicated, and persistent namespace must be non-empty.
- [ ] Run RED, implement minimal `WorldCellDefinition`, run GREEN.
- [ ] Run existing 67 tests plus the two new tests.

### Task 2: Road profiles and authoritative graph

**Files:**
- Create: `src/world/roads/road_profile.gd`
- Create: `src/world/roads/road_junction.gd`
- Create: `src/world/roads/road_segment.gd`
- Create: `src/world/roads/road_network.gd`
- Create: `tests/phase2/test_03_road_profiles.gd`
- Create: `tests/phase2/test_04_road_network.gd`

**Interfaces:**
- Produces: `RoadProfile.for_id(profile_id: StringName) -> RoadProfile`
- Produces: `RoadProfile.validation_errors() -> PackedStringArray`
- Produces: `RoadNetwork.add_junction(junction: RoadJunction) -> Error`
- Produces: `RoadNetwork.add_segment(segment: RoadSegment) -> Error`
- Produces: `RoadNetwork.validation_errors() -> PackedStringArray`
- Produces: `RoadNetwork.connected_segments(junction_id: StringName) -> Array[RoadSegment]`

- [ ] Write profile test first for `highway`, `rural_two_lane`, `hill_two_lane`, `service`, and `dirt_trail`, including positive widths/sample spacing and expected surface defaults.
- [ ] Run RED; implement profile resources/presets; run GREEN.
- [ ] Write graph test first: stable unique IDs, start/end junction existence, curve minimum control geometry, duplicate rejection, connected-segment lookup, disconnected declared connection rejection.
- [ ] Run RED; implement junction, segment and network classes; run GREEN.
- [ ] Run all Phase 2 tests plus existing regressions.

### Task 3: Deterministic spline sampling and road geometry

**Files:**
- Create: `src/world/roads/road_sample.gd`
- Create: `src/world/roads/road_spline_sampler.gd`
- Create: `src/world/roads/road_geometry_builder.gd`
- Create: `tests/phase2/test_05_road_spline_sampler.gd`
- Create: `tests/phase2/test_06_road_geometry.gd`

**Interfaces:**
- Produces: `RoadSplineSampler.sample(segment: RoadSegment, spacing_m: float = -1.0) -> Array[RoadSample]`
- Produces: `RoadGeometryBuilder.build_surface_arrays(segment: RoadSegment, profile: RoadProfile) -> Dictionary`
- Produces: `RoadGeometryBuilder.create_segment_node(segment: RoadSegment, profile: RoadProfile) -> Node3D`

- [ ] Write sampler test first: endpoint inclusion, monotonic accumulated distance, approximately bounded sample spacing, normalized frame vectors, consistent handedness, deterministic samples.
- [ ] Run RED; implement sampler using `Curve3D.get_baked_length()` and `sample_baked_with_rotation()`/tangent fallback; run GREEN.
- [ ] Write geometry test first: expected vertex/index counts, normals/UV arrays same size as vertices, finite values, road width within tolerance, shoulder vertices outside road vertices, collision body exists, collider `surface_id` equals segment surface.
- [ ] Run RED; implement minimal ArrayMesh + StaticBody3D/CollisionShape3D road strip and shoulders; run GREEN.
- [ ] Add explicit seam test for two segments sharing a junction; require endpoint center mismatch below 0.05 m.
- [ ] Run all tests.

### Task 4: Shared surface resolver and terrain backend contract

**Files:**
- Create: `src/surface/surface_resolver.gd`
- Create: `src/world/terrain/terrain_backend_adapter.gd`
- Create: `src/world/terrain/builtin_terrain_backend.gd`
- Create: `tests/phase2/test_07_surface_resolver.gd`
- Create: `tests/phase2/test_08_terrain_backend.gd`

**Interfaces:**
- Produces: `SurfaceResolver.surface_id_from_collider(collider: Object, fallback: StringName = &"asphalt_dry") -> StringName`
- Produces: `TerrainBackendAdapter.backend_id() -> StringName`
- Produces: `TerrainBackendAdapter.create_cell(cell: WorldCellDefinition, grid: WorldGrid) -> Node3D`
- Produces: `TerrainBackendAdapter.release_cell(cell_node: Node3D) -> void`
- Produces: `TerrainBackendAdapter.supports(feature: StringName) -> bool`

- [ ] Write surface test first: known metadata passes through, missing metadata returns explicit fallback, invalid ID returns fallback, and all Phase 1 IDs are recognized.
- [ ] Run RED; implement resolver; run GREEN.
- [ ] Write terrain backend test first: built-in backend reports stable ID, creates a 512 m cell at correct center, creates collision, tags default terrain as grass, and releases safely.
- [ ] Run RED; implement abstract/default adapter methods and deterministic built-in terrain chunk with simple elevation-capable mesh interface; run GREEN.
- [ ] Do not add Terrain3D dependency.

### Task 5: Streaming policy and runtime manager

**Files:**
- Create: `src/world/streaming/world_streaming_config.gd`
- Create: `src/world/streaming/world_streaming_policy.gd`
- Create: `src/world/streaming/world_stream_manager.gd`
- Create: `tests/phase2/test_09_streaming_policy.gd`
- Create: `tests/phase2/test_10_stream_manager.gd`

**Interfaces:**
- Produces: `WorldStreamingConfig` with gameplay radius 1, visual radius 3, predictive lookahead seconds 2.25, unload hysteresis cells 1.
- Produces: `WorldStreamingPolicy.desired_cells(grid, config, observer_position, observer_velocity, resident_cells = {}) -> Dictionary`
- Dictionary keys: `gameplay`, `predictive`, `visual`, `keep_resident` as sorted `Array[Vector2i]`.
- Produces: `WorldStreamManager.configure(grid, backend, definitions, config) -> PackedStringArray`
- Produces: `WorldStreamManager.update_observer(position, velocity) -> void`
- Produces: `loaded_cell_ids() -> PackedStringArray`

- [ ] Write policy test first: stationary observer gets bounded concentric sets; 80 m/s forward motion adds cells ahead; prediction never leaves grid bounds; sets are deterministic/sorted; keep-resident hysteresis retains a recently loaded boundary cell for one extra band.
- [ ] Run RED; implement pure policy; run GREEN.
- [ ] Write manager test first using built-in backend: configure, load expected cells, no duplicate instances, move across boundary, unload obsolete cells, return to start without duplicate/stale ownership.
- [ ] Run RED; implement manager lifecycle and signals; run GREEN.
- [ ] Run repeated-traversal loop test to catch ownership leaks at the logical level.

### Task 6: Proving-region road network and deterministic builder

**Files:**
- Create: `src/world/proving/proving_region_definition.gd`
- Create: `src/world/proving/proving_region_factory.gd`
- Create: `src/world/proving/proving_region_builder.gd`
- Create: `tests/phase2/test_11_proving_region_definition.gd`
- Create: `tests/phase2/test_12_proving_region_builder.gd`

**Interfaces:**
- Produces: `ProvingRegionFactory.create() -> ProvingRegionDefinition`
- Definition contains `WorldGrid`, cell definitions, `RoadNetwork`, spawn transform, and roadside-test-zone transform.
- Produces: `ProvingRegionBuilder.build(definition: ProvingRegionDefinition) -> Node3D`

- [ ] Write definition test first. Require all five road profiles to be represented, at least one closed high-speed/rural loop, one hill branch with elevation delta, one dirt/service branch, valid segment/junction references, and a spawn point on asphalt.
- [ ] Run RED; implement deterministic factory with explicit Curve3D control points; run GREEN.
- [ ] Write builder test first. Require WorldStreamManager, TerrainRoot, RoadsRoot, EnvironmentRoot, spawn marker, roadside test-zone marker, and generated road nodes with collision/surface metadata.
- [ ] Run RED; implement builder; run GREEN.
- [ ] Keep authored geometry concentrated in a representative subset of cells; do not populate all 144 cells with dense art.

### Task 7: Playable Phase 2 world scene and Phase 1 vehicle integration

**Files:**
- Create: `scenes/world/proving_region.tscn`
- Create: `src/world/proving/proving_region_scene.gd`
- Create: `tests/phase2/test_13_world_scene_contract.gd`
- Create: `tests/phase2/test_14_vehicle_world_integration.gd`

**Interfaces:**
- World scene can run standalone and instances `res://scenes/vehicle/prototype_rwd_coupe.tscn`.
- `ProvingRegionScene` exposes `get_player_vehicle() -> VehicleController` and `get_stream_manager() -> WorldStreamManager`.

- [ ] Write scene contract first: scene loads without Terrain3D, required roots exist, deterministic sun/environment exists, player vehicle exists, spawn is above a valid asphalt road collider.
- [ ] Run RED; create scene/controller; run GREEN.
- [ ] Write vehicle integration test first: settle car on Phase 2 road, confirm wheel telemetry surfaces are paved; place car on gravel/dirt/grass test patches and confirm corresponding surface IDs; move the observer across a representative cell boundary and ensure player/road remain present.
- [ ] Run RED; add deterministic test patches/stream pinning required by the integration contract; run GREEN.
- [ ] Do not retune Phase 1 vehicle physics to make world tests pass; fix world geometry/surface contracts instead.

### Task 8: World benchmark contract, documentation, and repository verification

**Files:**
- Create: `src/world/validation/world_validator.gd`
- Create: `tools/benchmark/run_world_stream_probe.gd`
- Create: `tests/phase2/test_15_world_validation.gd`
- Create: `tests/phase2/test_16_world_stream_probe.gd`
- Modify: `tests/test_manifest.txt`
- Modify: `tools/verify/verify.sh`
- Modify: `tools/verify/verify.ps1`
- Create/Update: `docs/status/phase-2-road-world-foundation-report.md`

**Interfaces:**
- Produces: `WorldValidator.validate(definition: ProvingRegionDefinition) -> PackedStringArray`
- Stream probe reports max desired gameplay/visual cell counts and deterministic route checksum; it does not claim GPU FPS.

- [ ] Write validator test first for duplicate IDs, out-of-bounds cells, missing road references, invalid profiles, unsupported surface IDs, and valid proving region.
- [ ] Run RED; implement validator; run GREEN.
- [ ] Write stream-probe contract first: simulate a repeatable high-speed route through the grid, require bounded cell counts, at least one predictive load ahead, and identical checksum on repeat.
- [ ] Run RED; implement probe; run GREEN.
- [ ] Append exactly 16 Phase 2 test paths to `tests/test_manifest.txt`, preserving prior order and all 67 entries.
- [ ] Keep shared verify wrappers compatible with the larger manifest; only change wording/count handling if required.
- [ ] Run full Linux repository verifier with Godot 4.7.1, including all 83 tests and existing 60/120 Hz vehicle matrix.
- [ ] Review output for `SCRIPT ERROR`, failed assertions, leaks, and stale resources.
- [ ] Update Phase 2 status report with measured automated evidence only.
- [ ] Run native Windows verifier once at the Phase 2 closure gate, not repeatedly during development.

## Plan self-review

- Spec coverage: grid, stable IDs, road graph, spline geometry, surface bridge, replaceable terrain, predictive/hysteretic streaming, proving region, player integration, regression verification, and platform gates each have a task.
- Scope: traffic, race rules, full environment art, final weather/day-night, universal intersection generation, and floating origin remain outside this plan.
- Type consistency: task interfaces use the same `WorldGrid`, `WorldCellDefinition`, `RoadNetwork`, `RoadSegment`, `RoadProfile`, and `WorldStreamingConfig` names throughout.
- No placeholder implementation steps remain.
