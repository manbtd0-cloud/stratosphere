# Phase 2 — Road / World Foundation Design

**Date:** 2026-08-08
**Project:** Open-World Racing Game
**Engine:** Godot 4.7.1 stable, Forward+, Jolt
**Base:** `agent/phase-1-vehicle-lab` at `a61a30d7a1ebc03f4d8d087c073f97d8a76e7806`
**Status:** Approved for implementation

## 1. Purpose

Phase 2 builds the scalable spatial, road, terrain, surface, and streaming substrate that later driving-world, traffic, race, navigation, weather, and career systems consume. It does not attempt to art-finish the final world.

The first proving region is a mixed driving environment containing a fast highway layer, sweeping rural roads, a technical hill section, service roads, off-road cut-throughs, terrain elevation, and a small roadside built-up test zone.

The world architecture must remain useful when the project expands beyond this proving region. Gameplay identity and streaming are owned by game code rather than a terrain plugin.

## 2. Decisions already locked

- Use a hybrid terrain architecture.
- Game-owned world data, cells, road graph, surface semantics, streaming policy, and stable identifiers are authoritative.
- Terrain3D or another proven terrain renderer may be integrated behind an adapter, but Phase 2 must boot and verify without it.
- The development address space is approximately 6.144 km × 6.144 km.
- Use 512 m square world cells: 12 × 12 cells in the address space.
- The Phase 2 authored/high-detail proving footprint is intentionally much smaller than the full address space; it remains compatible with the master-design 4–6 km² vertical-slice content target while still exercising a larger streaming grid.
- Road topology is a layered loop network.
- No pedestrians. Traffic cars come later.
- No paid assets or mandatory paid plugins.
- Linux and Windows remain first-class.
- Preserve the existing 120 Hz vehicle physics and Phase 1 surface model.

## 3. Architecture

```text
WorldRoot
├── WorldStreamManager
│   ├── WorldGrid / stable cell IDs
│   ├── WorldStreamingPolicy
│   └── Cell runtime lifecycle
├── TerrainBackendAdapter
│   ├── BuiltinTerrainBackend (Phase 2 fallback)
│   └── Optional third-party backend later
├── RoadNetwork
│   ├── RoadJunction resources
│   ├── RoadSegment resources
│   ├── RoadProfile resources
│   └── RoadGeometryBuilder
├── Surface metadata
│   └── shared SurfaceResolver contract
└── ProvingRegionBuilder
    ├── terrain cells
    ├── roads and junction patches
    ├── roadside test zone
    └── player spawn / world anchors
```

The logical road network is authoritative. Render meshes, collision, future traffic navigation, race routing, GPS, and minimap data derive from the same road-segment definitions.

## 4. Spatial grid and stable identifiers

### 4.1 Grid

- Cell size: 512.0 m.
- Grid dimensions: 12 × 12.
- Address-space span: 6144 m per axis.
- Centered around world origin for the Phase 2 proving region.
- Valid logical coordinates: x/z from -6 through +5.

### 4.2 IDs

A cell ID uses a stable signed-coordinate format such as:

`world.proving.c-03_p02`

Cell IDs are data/save identifiers and do not depend on scene instance names or load order.

### 4.3 Coordinate API

A pure `WorldGrid` class owns:

- world position → cell coordinate
- cell coordinate → center position
- coordinate → stable ID
- ID parsing/validation
- bounds checks
- neighbor enumeration
- square/radius range queries

All later world systems consume this API instead of implementing their own cell math.

No floating-origin rebasing is implemented in Phase 2. The API boundary intentionally allows rebasing later without rewriting consumers.

## 5. Cell data

`WorldCellDefinition` is a Resource containing:

- stable ID
- integer coordinate
- terrain backend key
- road segment IDs touching the cell
- surface-region IDs
- optional environment/prop group IDs
- runtime priority hint
- persistent-state namespace

A cell is a unit of streaming ownership, not a promise that every asset is physically cut exactly at the cell boundary. Cross-cell assets must declare the cells that own/reference them.

## 6. Streaming model

The streaming system has three conceptual ranges:

### Gameplay range

- current cell plus nearby cells
- full terrain collision
- full road collision
- gameplay surface metadata
- high-detail gameplay props when present

### Predictive range

- cells ahead of the observer based on velocity direction and speed
- prevents a fast car from outrunning ordinary neighbor loading
- deterministic pure-policy calculation, independent from asynchronous loading implementation

### Visual range

- broader reduced-detail cells/proxies
- preserves distant terrain/horizon continuity
- may use lower terrain/road detail and no active gameplay simulation

`WorldStreamingPolicy` is a pure class. Given observer position, velocity, grid, and range configuration it returns desired gameplay, predictive, and visual cell sets.

Hysteresis keeps recently loaded cells resident until the observer has cleared the unload boundary. This prevents boundary thrashing.

`WorldStreamManager` owns runtime instances and emits load/unload signals. Phase 2 may load lightweight fallback cell scenes synchronously because the authored footprint is small, but lifecycle and APIs must already be compatible with deferred/background resource loading later.

## 7. Terrain backend boundary

`TerrainBackendAdapter` defines a narrow interface:

- configure world grid
- create/load a cell visual/collider
- release a cell
- query whether a backend supports a feature
- expose backend ID for diagnostics

The default Phase 2 backend is built entirely from Godot primitives/meshes and creates deterministic terrain chunks with collision. It exists for testing, fallback operation, and plugin independence.

A future Terrain3D adapter may implement the same boundary. No gameplay system may directly call Terrain3D APIs.

## 8. Road data model

### 8.1 RoadJunction

Stable junction resource:

- ID
- world position
- connected road IDs
- junction class

Initial junction classes:

- simple endpoint
- T junction
- crossroad
- highway merge/diverge

### 8.2 RoadSegment

Stable segment resource:

- ID
- start/end junction IDs
- Curve3D centerline
- RoadProfile ID/reference
- lane count
- travel-direction policy
- surface ID
- speed-limit metadata
- banking/camber source
- shoulder configuration
- future navigation/race metadata hooks

### 8.3 RoadProfile

Profiles define reusable physical/visual dimensions rather than bespoke code paths.

Initial profiles:

- `highway`
- `rural_two_lane`
- `hill_two_lane`
- `service`
- `dirt_trail`

Profiles control lane width, lane count, shoulder width, marking policy, base surface, geometry tessellation target, and coarse LOD spacing.

## 9. Spline sampling and geometry

Road geometry derives deterministically from `Curve3D` samples.

The sampler produces frames containing:

- world position
- forward tangent
- up vector
- right vector
- accumulated distance
- half road width
- shoulder width
- banking angle

The geometry builder generates:

- road surface strip
- left/right shoulders
- continuous UV distance
- stable normals
- collision triangles
- surface metadata

Road collision bodies carry `surface_id` metadata compatible with the existing Phase 1 vehicle contact contract.

Intersections use explicit deterministic junction patches in Phase 2. A universal procedural intersection solver is deliberately out of scope.

## 10. Surface bridge

The vehicle already recognizes collider metadata named `surface_id`. Phase 2 formalizes this into a shared `SurfaceResolver` helper used by world tests/tools and by the vehicle contact path where safe.

Supported Phase 2 IDs remain aligned with Phase 1:

- `asphalt_dry`
- `asphalt_wet`
- `gravel`
- `dirt`
- `grass`

Unknown/missing metadata resolves to a deliberate fallback rather than silently inventing a new surface.

## 11. Proving-region route

The initial logical layout contains:

1. highway spine/loop for sustained speed
2. sweeping rural connector loop
3. hill/technical road with elevation and tighter radii
4. service-road branch
5. dirt/gravel cut-through
6. grass/off-road transition area
7. small modular roadside test cluster
8. vehicle spawn/recovery areas

The authored route footprint is concentrated through a subset of the 12 × 12 grid. Distant cells remain valid streamable terrain/proxy cells so Phase 2 can stress cell transitions without requiring 37 km² of handcrafted art.

## 12. Presentation baseline

Phase 2 is architecture-first but not disposable greybox work.

- Forward+ remains enabled.
- Reuse physically plausible PBR-style materials.
- Road material families are shared.
- Terrain colors/materials distinguish grass, exposed soil, gravel, and paved surfaces.
- Deterministic sun/environment establishes readable depth and road visibility.
- Repeated future vegetation/props are expected to use MultiMesh/HLOD but dense vegetation production belongs to Phase 3.
- Road markings and local wear should be compatible with decals later.

## 13. Performance contracts

Phase 2 does not claim real GPU performance from headless execution.

Automated performance contracts cover:

- bounded active gameplay-cell counts
- bounded visual-cell counts
- deterministic streaming decisions
- no duplicate runtime cell instances
- load/unload hysteresis
- predictive loading at representative high vehicle speeds
- stable runtime ownership after repeated traversal
- road generation complexity proportional to sampled length

Target-hardware frame-time and VRAM claims remain physical-hardware gates.

## 14. Testing

### Pure/unit contracts

- grid coordinate conversion
- stable cell IDs and parsing
- bounds and neighbors
- streaming ranges
- predictive cells
- hysteresis
- road-profile validation
- junction/segment graph connectivity
- spline sample spacing and accumulated distance
- surface resolver behavior

### Geometry contracts

- road mesh has valid vertices/indices/normals/UVs
- road width remains within tolerance
- collision generated
- correct surface metadata attached
- adjacent road chunks do not introduce large seam gaps
- explicit junction patch connects expected approaches

### Integration contracts

- fallback terrain backend can create/release cells
- stream manager loads/unloads deterministically
- proving-region definition validates
- world scene boots without Terrain3D
- prototype RWD coupe can spawn on road geometry
- road/terrain surface colliders expose the Phase 1 IDs
- crossing representative cell boundaries does not delete the player or active road under it

All existing Phase 0 and Phase 1 contracts remain regression tests.

## 15. Platform and dependency rules

- Godot 4.7.1 stable is the verification baseline.
- Forward+ and Jolt remain canonical.
- Shared GDScript implementation for Linux and Windows.
- Case-correct `res://` paths only.
- No mandatory native extension.
- No mandatory terrain plugin.
- No runtime Blender dependency.
- No paid asset/plugin dependency.
- Native Windows verification is required at the Phase 2 milestone gate, not on every development commit.

## 16. Explicit non-goals

Phase 2 does not implement:

- production traffic AI
- racer AI
- police AI
- race event rules
- GPS UI/minimap UI
- complete town/forest/farmland/quarry art
- final weather system
- final day/night system
- full 15–25 km² production world
- universal procedural intersections
- floating origin
- user-facing world editor

Data hooks must not block those later systems.

## 17. Completion gate

Phase 2 is complete when:

1. 12 × 12 / 512 m world-grid topology exists and has stable identifiers.
2. Streaming policy and manager operate deterministically with gameplay, predictive, and visual ranges.
3. Terrain backend is replaceable and the built-in fallback boots without plugins.
4. Authoritative road graph exists.
5. Highway, rural, hill, service, and dirt-trail profiles exist.
6. Spline road meshes and collision derive from the same road data.
7. Road and terrain colliders expose correct Phase 1 surface IDs.
8. Layered-loop proving-region data and world scene exist.
9. The prototype RWD coupe can spawn in the streamed region.
10. Representative cell/road seams remain stable under automated integration checks.
11. Phase 2 streaming/geometry contracts pass.
12. All existing Phase 0/1 regression tests remain green.
13. Linux full repository verification passes.
14. Native Windows full repository verification passes at milestone closure.
15. No mandatory paid asset or plugin dependency is introduced.
