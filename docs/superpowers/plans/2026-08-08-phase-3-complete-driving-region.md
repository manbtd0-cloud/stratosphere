# Phase 3 Complete Driving Region Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Phase 2 proving region into a coherent 4–6 km² free-roam driving slice with deterministic world dressing, production-oriented road presentation, routable navigation data, and basic scalable civilian traffic while preserving the existing player-vehicle physics and Phase 0–2 contracts.

**Architecture:** Keep the Phase 2 world grid, road graph, surfaces, terrain adapter, and stream manager authoritative. Derive environment placement, road furniture, navigation, and traffic-lane data from stable world/road resources; keep civilian traffic on a cheaper replaceable controller with simulation LOD rather than duplicating the Phase 1 player-vehicle solver.

**Tech Stack:** Godot 4.7.1 stable, GDScript, Forward+, Jolt Physics, Resource-based data, MultiMesh for repeated visuals, existing repository verification wrappers and shared test manifest.

## Global Constraints

- Godot 4.7.1 stable (`a13da4feb`).
- Forward+ and Jolt remain canonical.
- Windows x86_64 and Linux x86_64 remain first-class.
- Preserve the 6.144 km × 6.144 km / 12 × 12 Phase 2 logical address space.
- Author approximately 4–6 km² of connected high-detail territory; do not art-fill all 37.75 km².
- No pedestrians.
- No dynamic day/night, rain, weather transitions, or automatic wet-road transitions in Phase 3.
- One polished static daytime condition only.
- No mandatory paid assets or plugins.
- Terrain3D remains optional and cannot own gameplay/world identity.
- Preserve Phase 1 player physics; traffic uses a separate cheaper controller.
- Existing 83 Phase 0–2 tests remain regression gates.
- No final GPU/FPS claims from headless verification.

---

## File Structure

Create focused modules under `src/world/environment`, `src/world/navigation`, `src/world/roads/presentation`, and `src/traffic`. Extend `src/world/proving` only for composition/orchestration. Keep world-data classes pure where possible so headless unit tests do not require a running scene tree.

Key new files:

- `src/world/environment/environment_zone_definition.gd` — stable zone identity and placement policy.
- `src/world/environment/deterministic_placement_service.gd` — seeded candidate placement with exclusions/spacing.
- `src/world/environment/environment_cluster_builder.gd` — batched visual cluster creation.
- `src/world/roads/presentation/road_presentation_builder.gd` — markings, guardrails, chevrons, signs, delineators.
- `src/world/navigation/navigation_graph.gd` — directed road/lane nodes and edges.
- `src/world/navigation/navigation_service.gd` — nearest-road and route queries.
- `src/traffic/traffic_lane.gd`, `traffic_lane_graph.gd`, `traffic_lane_graph_builder.gd` — derived lane topology.
- `src/traffic/traffic_simulation_policy.gd` — near/mid/far simulation LOD.
- `src/traffic/traffic_agent.gd` — cheap lane-following traffic controller.
- `src/traffic/traffic_spawner.gd` — visibility/distance/occupancy-safe spawn selection.
- `src/traffic/traffic_manager.gd` — budgets, ownership, update cadence, spawn/despawn.
- `src/world/proving/driving_region_builder.gd` — compose Phase 3 authored world from Phase 2 data.

Tests are added as sequential `tests/phase3/test_XX_*.gd` entries and appended to `tests/test_manifest.txt` only after each contract is green individually.

---

### Task 1: Environment Zones and Deterministic Placement

**Files:**
- Create: `src/world/environment/environment_zone_definition.gd`
- Create: `src/world/environment/deterministic_placement_service.gd`
- Test: `tests/phase3/test_01_environment_zones.gd`
- Test: `tests/phase3/test_02_deterministic_placement.gd`

**Interfaces:**
- Consumes: `WorldGrid`, stable Phase 2 cell IDs.
- Produces: `EnvironmentZoneDefinition.validate() -> PackedStringArray`; `DeterministicPlacementService.generate(zone, cell_id, layer_id, bounds, count, min_spacing) -> Array[Transform3D]`.

- [ ] **Step 1: Write the zone validation test**

```gdscript
var zone := EnvironmentZoneDefinition.new()
zone.id = &"forest.north_hill"
zone.zone_class = &"forest"
zone.cell_ids = [&"world.proving.c-01_p02"]
assert(zone.validate().is_empty())
```

Also assert rejection of an empty ID, unsupported class, and empty cell ownership.

- [ ] **Step 2: Run the test and confirm RED**

Run:

```bash
$GODOT_BIN --headless --path . --script res://tests/phase3/test_01_environment_zones.gd
```

Expected: parse/load failure because `EnvironmentZoneDefinition` does not exist.

- [ ] **Step 3: Implement zone data and validation**

Support exactly these initial classes: `countryside_open`, `farmland`, `forest`, `hill_rocky`, `rural_settlement`, `industrial_service`, `highway_corridor`, `dirt_trail_corridor`, `scenic_overlook`.

- [ ] **Step 4: Write deterministic placement RED test**

Generate the same layer twice and assert byte-stable quantized transform fingerprints; change `layer_id` and assert the fingerprint changes. Assert every pair respects `min_spacing` and every transform lies within bounds.

- [ ] **Step 5: Implement deterministic placement**

Use a local `RandomNumberGenerator` seeded from `hash("%s|%s|%s" % [zone.id, cell_id, layer_id])`; do not mutate global RNG. Reject impossible requests with an empty array plus a diagnostic rather than infinite retries.

- [ ] **Step 6: Run both tests GREEN and run the existing 83-test verifier**

```bash
$GODOT_BIN --headless --path . --script res://tests/phase3/test_01_environment_zones.gd
$GODOT_BIN --headless --path . --script res://tests/phase3/test_02_deterministic_placement.gd
GODOT_BIN=$GODOT_BIN ./tools/verify/verify.sh
```

- [ ] **Step 7: Commit the task**

```bash
git add src/world/environment tests/phase3/test_01_environment_zones.gd tests/phase3/test_02_deterministic_placement.gd
git commit -m "feat: add deterministic environment zones"
```

---

### Task 2: Terrain Sampling and Authored Region Composition

**Files:**
- Modify: `src/world/terrain/terrain_backend_adapter.gd`
- Modify: `src/world/terrain/builtin_terrain_backend.gd`
- Create: `src/world/proving/driving_region_definition.gd`
- Test: `tests/phase3/test_03_terrain_sampling.gd`
- Test: `tests/phase3/test_04_driving_region_definition.gd`

**Interfaces:**
- Consumes: Phase 2 grid, proving-region route data, environment zones.
- Produces: `sample_height(world_position: Vector3) -> float`, `sample_normal(world_position: Vector3) -> Vector3`, `DrivingRegionDefinition.validate() -> PackedStringArray`.

- [ ] **Step 1: Write RED terrain sample contract**

Assert deterministic heights at representative highway, countryside, hill, and dirt-route coordinates; assert hill sample exceeds highway sample by at least 40 m; assert normals are normalized.

- [ ] **Step 2: Implement deterministic built-in terrain macro function**

Use low-frequency mathematical height components plus explicit road-corridor flatten/blend hooks. Keep all sampling behind the adapter API.

- [ ] **Step 3: Write RED region-definition contract**

Require connected authored cells, all nine zone classes represented where appropriate, stable garage/dealership hook IDs, and route references resolving into the Phase 2 road network.

- [ ] **Step 4: Implement `DrivingRegionDefinition`**

Define the 4–6 km² authored footprint as a connected subset of Phase 2 cells and assign forest, farmland, settlement, industrial, highway, dirt, hill, and overlook zones.

- [ ] **Step 5: Run both tests GREEN plus verifier**

- [ ] **Step 6: Commit**

```bash
git add src/world/terrain src/world/proving tests/phase3/test_03_terrain_sampling.gd tests/phase3/test_04_driving_region_definition.gd
git commit -m "feat: compose phase three terrain region"
```

---

### Task 3: Road Presentation and Environment Clusters

**Files:**
- Create: `src/world/roads/presentation/road_presentation_builder.gd`
- Create: `src/world/environment/environment_cluster_builder.gd`
- Create: `src/world/environment/roadside_placement_builder.gd`
- Test: `tests/phase3/test_05_road_presentation.gd`
- Test: `tests/phase3/test_06_environment_clusters.gd`

**Interfaces:**
- Consumes: `RoadSegment`, `RoadProfile`, `RoadSplineSampler`, deterministic placements.
- Produces: presentation nodes/meshes carrying stable source IDs and cell ownership; MultiMesh-ready environment clusters.

- [ ] **Step 1: RED road-presentation test**

Build highway/rural/hill/service/dirt sample segments and assert profile-appropriate markings/furniture metadata. Assert no road-presentation node carries physics `surface_id` authority.

- [ ] **Step 2: Implement deterministic road furniture generation**

Generate lane/edge marking strips, guardrail anchor runs, hill chevron anchors, delineator anchors, and sign anchors from sampled road distance. Keep geometry/furniture cell-addressable.

- [ ] **Step 3: RED environment-cluster test**

Assert repeated vegetation is grouped into batched clusters, deterministic transforms are preserved after rebuild, and quality-density multipliers never create duplicate instance IDs.

- [ ] **Step 4: Implement cluster builder**

Use `MultiMeshInstance3D` where meshes are available; support primitive development stand-ins through the same cluster metadata so the architecture does not depend on final art.

- [ ] **Step 5: GREEN tests + existing verifier**

- [ ] **Step 6: Commit**

```bash
git add src/world/roads/presentation src/world/environment tests/phase3/test_05_road_presentation.gd tests/phase3/test_06_environment_clusters.gd
git commit -m "feat: add road and environment presentation"
```

---

### Task 4: Navigation Graph and Route Queries

**Files:**
- Create: `src/world/navigation/navigation_edge.gd`
- Create: `src/world/navigation/navigation_graph.gd`
- Create: `src/world/navigation/navigation_graph_builder.gd`
- Create: `src/world/navigation/navigation_service.gd`
- Test: `tests/phase3/test_07_navigation_graph.gd`
- Test: `tests/phase3/test_08_navigation_routes.gd`

**Interfaces:**
- Consumes: Phase 2 road segments/junctions and profile travel direction.
- Produces: stable directed navigation nodes/edges; `find_route(start_id: StringName, goal_id: StringName) -> Array[StringName]`; `nearest_edge(world_position: Vector3) -> StringName`.

- [ ] **Step 1: RED graph derivation test**

Assert every eligible road segment creates directed graph connectivity, dirt/service rules are preserved, and no edge references a nonexistent junction.

- [ ] **Step 2: Implement graph builder**

Use stable IDs derived from source road/junction IDs. Edge cost is physical sampled length; no traffic or race-specific weighting yet.

- [ ] **Step 3: RED route-query test**

Assert route search across highway → rural → hill returns a legal directed path, reverse traversal rejects when direction is one-way, and nearest-edge lookup picks the expected road within tolerance.

- [ ] **Step 4: Implement deterministic Dijkstra route service**

Tie-break equal-cost nodes by stable ID so routes reproduce across platforms.

- [ ] **Step 5: GREEN + verifier**

- [ ] **Step 6: Commit**

```bash
git add src/world/navigation tests/phase3/test_07_navigation_graph.gd tests/phase3/test_08_navigation_routes.gd
git commit -m "feat: derive routable world navigation"
```

---

### Task 5: Traffic Lane Graph

**Files:**
- Create: `src/traffic/traffic_lane.gd`
- Create: `src/traffic/traffic_lane_connector.gd`
- Create: `src/traffic/traffic_lane_graph.gd`
- Create: `src/traffic/traffic_lane_graph_builder.gd`
- Test: `tests/phase3/test_09_traffic_lane_graph.gd`
- Test: `tests/phase3/test_10_traffic_connectors.gd`

**Interfaces:**
- Consumes: road graph, road profiles, spline samples.
- Produces: stable per-direction lane centerlines, speed limits, cell ownership, and valid junction connectors.

- [ ] **Step 1: RED lane derivation test**

For highway and rural samples assert lane count, lateral offset, travel direction, stable lane IDs, speed metadata, and source road ID.

- [ ] **Step 2: Implement lane derivation**

Derive lane centerlines from road sample right vectors and profile lane widths. Dirt trail defaults to civilian traffic disabled.

- [ ] **Step 3: RED connector validation test**

Assert legal incoming→outgoing junction transitions exist; wrong-way and dangling connectors fail validation.

- [ ] **Step 4: Implement deterministic connector generation**

Prefer straight/low-angle legal exits when multiple connectors exist but keep all legal transitions available.

- [ ] **Step 5: GREEN + verifier**

- [ ] **Step 6: Commit**

```bash
git add src/traffic tests/phase3/test_09_traffic_lane_graph.gd tests/phase3/test_10_traffic_connectors.gd
git commit -m "feat: derive civilian traffic lanes"
```

---

### Task 6: Traffic Simulation Policy and Agent Controller

**Files:**
- Create: `src/traffic/traffic_simulation_policy.gd`
- Create: `src/traffic/traffic_agent.gd`
- Create: `src/traffic/traffic_vehicle_definition.gd`
- Test: `tests/phase3/test_11_traffic_simulation_policy.gd`
- Test: `tests/phase3/test_12_traffic_agent.gd`

**Interfaces:**
- Consumes: lane graph, observer position, stable traffic definitions.
- Produces: near/mid/far simulation level; lane-following desired velocity/steering/brake state.

- [ ] **Step 1: RED simulation-LOD test**

Assert deterministic transitions for configured near/mid/far thresholds and hysteresis. Player entity ID must always return `player`, never traffic LOD.

- [ ] **Step 2: Implement policy**

Use squared distance and explicit hysteresis bands; keep policy pure.

- [ ] **Step 3: RED agent behavior test**

On a synthetic lane assert forward progress, target-speed convergence, following-distance braking, stop for blocked lane, and recovery request after sustained path divergence.

- [ ] **Step 4: Implement cheap traffic controller**

Near mode uses a simple `RigidBody3D`/kinematic-style force or velocity controller with world collision; mid mode follows lane at reduced update frequency; far mode is logical only. Do not instantiate `VehicleController` or Phase 1 per-wheel solvers.

- [ ] **Step 5: GREEN + verifier**

- [ ] **Step 6: Commit**

```bash
git add src/traffic tests/phase3/test_11_traffic_simulation_policy.gd tests/phase3/test_12_traffic_agent.gd
git commit -m "feat: add scalable civilian traffic controller"
```

---

### Task 7: Traffic Spawner and Manager

**Files:**
- Create: `src/traffic/traffic_spawn_candidate.gd`
- Create: `src/traffic/traffic_spawner.gd`
- Create: `src/traffic/traffic_manager.gd`
- Test: `tests/phase3/test_13_traffic_spawner.gd`
- Test: `tests/phase3/test_14_traffic_manager.gd`

**Interfaces:**
- Consumes: lane graph, world stream state, environment-zone density, player transform/velocity.
- Produces: bounded active traffic registry and safe spawn/despawn decisions.

- [ ] **Step 1: RED spawn-safety test**

Assert candidates inside close player view cone reject; candidates below minimum distance reject; occupied lane interval rejects; valid behind/side candidate accepts.

- [ ] **Step 2: Implement spawner**

Selection order is deterministic by lane ID + distance score. Never retry indefinitely when no candidate exists.

- [ ] **Step 3: RED manager-budget test**

Assert configured 10–20 global target is bounded, per-zone multipliers affect desired count, duplicate agent IDs reject, unloaded-cell agents transfer/despawn cleanly, repeated traversal does not leak registry entries.

- [ ] **Step 4: Implement manager**

Use stable traffic IDs and explicit cell ownership. Spawn/despawn only through manager APIs.

- [ ] **Step 5: GREEN + verifier**

- [ ] **Step 6: Commit**

```bash
git add src/traffic tests/phase3/test_13_traffic_spawner.gd tests/phase3/test_14_traffic_manager.gd
git commit -m "feat: manage streamed civilian traffic"
```

---

### Task 8: Complete Driving Region Runtime Integration

**Files:**
- Create: `src/world/proving/driving_region_builder.gd`
- Modify: `src/world/proving/proving_region_scene.gd`
- Modify: `scenes/world/proving_region.tscn`
- Test: `tests/phase3/test_15_driving_region_scene.gd`
- Test: `tests/phase3/test_16_player_traffic_integration.gd`
- Test: `tests/phase3/test_17_streaming_environment_integration.gd`

**Interfaces:**
- Consumes: all prior Phase 3 systems plus existing Phase 2 scene/player integration.
- Produces: launchable authored driving region with static daylight, environment zones, road presentation, route graph, traffic manager, and player vehicle.

- [ ] **Step 1: RED scene contract**

Assert region boots, static environment exists, authored zone root exists, road-presentation root exists, navigation service exists, traffic manager exists, and player remains the Phase 1 vehicle controller.

- [ ] **Step 2: Implement world composition**

Compose deterministic development-quality forest/farmland/settlement/industrial/overlook visuals using reusable primitives/materials when final assets are unavailable. Keep all groups cell-addressable and quality-scalable.

- [ ] **Step 3: RED player/traffic integration test**

Assert traffic collision layer interacts with player, traffic cannot replace player controller, player recovery remains callable, and traffic world contacts do not mutate player surface data.

- [ ] **Step 4: RED streaming integration test**

Traverse representative cell path twice and assert environment instance fingerprints repeat, no duplicate clusters appear, traffic registry returns to bounded state, and player persists.

- [ ] **Step 5: Implement integration fixes until GREEN**

- [ ] **Step 6: Run all 17 Phase 3 tests individually and full repository verifier**

- [ ] **Step 7: Commit**

```bash
git add src/world/proving scenes/world tests/phase3
git commit -m "feat: assemble complete driving region"
```

---

### Task 9: Traffic Development Roster and Asset Registry Integration

**Files:**
- Create: `src/traffic/traffic_roster_factory.gd`
- Create or update: `assets/registry/traffic_development_assets.json` if registry pattern supports JSON; otherwise register via existing asset-resource pattern.
- Test: `tests/phase3/test_18_traffic_roster.gd`

**Interfaces:**
- Consumes: existing `AssetRegistry` and `TrafficVehicleDefinition`.
- Produces: 3–5 stable civilian archetypes (`compact`, `sedan`, `crossover`, `utility`, `van`) with scale, collision, LOD/proxy, and provenance metadata.

- [ ] **Step 1: Search current free asset sources and only adopt autonomously retrievable assets with clear enough provenance**

Record source URL/license note/runtime readiness in existing registry conventions. If a suitable asset is unavailable, use a deliberately labeled development stand-in rather than a low-quality pseudo-final asset.

- [ ] **Step 2: RED roster test**

Assert at least 3 distinct archetypes, unique stable IDs, valid dimensions, wheelbase/footprint metadata, collision/proxy availability, and source/provenance note.

- [ ] **Step 3: Implement roster factory and development stand-ins/import adapters**

Traffic definitions reference presentation assets separately from traffic motion/controller data.

- [ ] **Step 4: GREEN + verifier**

- [ ] **Step 5: Commit**

```bash
git add src/traffic assets tests/phase3/test_18_traffic_roster.gd
git commit -m "feat: add civilian traffic development roster"
```

---

### Task 10: Phase 3 Validation, Manifest, Benchmarks, and Closure Evidence

**Files:**
- Create: `src/world/validation/driving_region_validator.gd`
- Create: `tools/benchmark/run_phase3_driving_world_probe.gd`
- Create: `tests/phase3/test_19_driving_region_validation.gd`
- Create: `tests/phase3/test_20_traffic_stream_probe.gd`
- Modify: `tests/test_manifest.txt`
- Create: `docs/status/phase-3-complete-driving-region-report.md`

**Interfaces:**
- Consumes: full Phase 3 runtime/data.
- Produces: deterministic validation/probe evidence and milestone report.

- [ ] **Step 1: RED validator contract**

Validator rejects missing required zone classes, invalid lane connectors, duplicate traffic IDs, missing garage/dealership hooks, non-cell-addressable environment groups, or traffic enabled on dirt routes by default.

- [ ] **Step 2: Implement validator**

Return deterministic sorted diagnostics.

- [ ] **Step 3: RED traffic/world probe**

Run a synthetic high-speed route and assert bounded environment groups, bounded active traffic count, predictive stream loading still exercised, no duplicate traffic ownership, and deterministic route/placement checksum.

- [ ] **Step 4: Implement probe**

Print one machine-readable summary line plus human-readable PASS lines. Do not report GPU FPS/VRAM.

- [ ] **Step 5: Append all 20 Phase 3 tests to manifest and run Linux full verifier**

Expected manifest count after Phase 3: **103 tests** if no pre-existing manifest entries are added concurrently.

```bash
GODOT_BIN=$GODOT_BIN ./tools/verify/verify.sh
$GODOT_BIN --headless --fixed-fps 120 --path . --script res://tools/benchmark/run_phase3_driving_world_probe.gd
```

- [ ] **Step 6: Run native Windows milestone verifier once**

```powershell
$env:GODOT_BIN = "C:\path\to\Godot_v4.7.1-stable_win64.exe"
powershell -ExecutionPolicy Bypass -File .\tools\verify\verify.ps1
```

Record the exact test count, 60/120 Hz result, and Phase 3 deterministic probe output. Do not claim subjective driving feel or GPU performance from CI/headless evidence.

- [ ] **Step 7: Write status report and commit closure**

```bash
git add src/world/validation tools/benchmark tests/test_manifest.txt tests/phase3 docs/status/phase-3-complete-driving-region-report.md
git commit -m "chore: close phase three driving region"
```

- [ ] **Step 8: Final verification-before-completion pass**

Run the full Linux verifier fresh, inspect `git diff --check`, confirm branch is stacked on Phase 2 with 0 behind, confirm no temporary CI/publication files remain, and only then report Phase 3 automated closure.
