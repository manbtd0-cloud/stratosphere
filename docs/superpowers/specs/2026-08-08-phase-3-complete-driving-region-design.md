# Phase 3 — Complete Driving Region Design

**Date:** 2026-08-08
**Project:** Open-World Racing Game
**Engine:** Godot 4.7.1 stable, Forward+, Jolt
**Base:** `agent/phase-2-road-world-foundation` at `52720f37ef0c177887ccbad522300f89794a279b`
**Branch:** `agent/phase-3-complete-driving-region`
**Status:** Approved design, pending implementation-plan review

## 1. Purpose

Phase 3 turns the Phase 2 road/world substrate into the first genuinely enjoyable free-roam driving region. The goal is not to fill the complete 6.144 km × 6.144 km logical address space with handcrafted content. Instead, approximately 4–6 km² of connected territory becomes a coherent authored slice that demonstrates believable terrain, road presentation, environmental composition, route continuity, scalable vegetation, roadside structures, navigation-ready road metadata, and basic civilian traffic.

The player should be able to launch the game, drive the existing prototype RWD coupe through a region that feels intentionally designed rather than like a systems test map, encounter moving civilian vehicles, explore distinct road and environment types, and transition between highway, countryside, hill, service, and loose-surface routes without the world architecture being replaced later.

Phase 3 is still a foundation milestone. It deliberately excludes motorsport rules, racer AI, police, career, dynamic weather, and day/night so that the driving world and traffic substrate can become stable before higher-level gameplay depends on them.

## 2. Locked decisions

- Phase 3 is a complete-driving-slice phase, not a traffic-only or art-only phase.
- Approximately 4–6 km² of the Phase 2 world becomes the authored high-detail region.
- The existing 6.144 km × 6.144 km / 12 × 12 logical cell address space remains unchanged.
- Phase 2 road graph, world grid, streaming contracts, surfaces, and terrain-adapter boundary remain authoritative.
- Civilian traffic is included.
- Traffic is intentionally basic but production-oriented: lane following, target-speed control, following distance, basic junction transitions, blocked-road handling, spawning/despawning, and simulation LOD.
- No pedestrians.
- No dynamic day/night in Phase 3.
- No rain, fog-weather system, or automatic wet-road transitions in Phase 3.
- Use one polished static daytime lighting condition.
- No mandatory paid assets or plugins.
- Terrain3D remains optional and must not become a gameplay dependency.
- Linux and Windows remain first-class targets.
- Existing Phase 0–2 tests remain regression gates.
- Traffic vehicles do not need to use the expensive player-vehicle physics model at all distances.

## 3. High-level architecture

```text
Phase3DrivingRegion
├── WorldStreamManager                 (Phase 2, extended)
├── TerrainBackendAdapter              (Phase 2, extended)
├── RoadNetwork                        (Phase 2, authoritative)
│   ├── RoadSegment / RoadProfile
│   ├── TrafficLaneGraph               (derived)
│   ├── NavigationGraph                (derived)
│   └── RoadPresentationBuilder
├── EnvironmentRegionSystem
│   ├── EnvironmentZoneDefinition
│   ├── DeterministicPlacementService
│   ├── VegetationClusterBuilder
│   └── RoadsidePlacementBuilder
├── TrafficSystem
│   ├── TrafficLaneGraph
│   ├── TrafficManager
│   ├── TrafficSpawner
│   ├── TrafficAgent
│   └── TrafficSimulationPolicy
├── NavigationService
│   ├── route search
│   ├── nearest-road lookup
│   └── developer route debug
└── DrivingRegionBuilder
    ├── terrain composition
    ├── roads and road furniture
    ├── environment zones
    ├── settlement/service area
    ├── industrial/farm/forest dressing
    └── traffic/world anchors
```

The project keeps one authoritative spatial/road representation. Navigation and traffic data derive from the road network rather than being independently hand-authored copies.

## 4. Authored region scope

The high-detail driving region occupies a connected subset of the existing streamed grid and must include:

1. a sustained-speed highway section/loop
2. sweeping countryside roads
3. a technical elevated hill/mountain road
4. a service/industrial road branch
5. a dirt/gravel cut-through
6. forested sections
7. open farmland/countryside
8. a small rural roadside settlement/service cluster
9. a small industrial/workshop zone
10. at least one scenic overlook or landmark pull-off
11. garage and dealership physical-location hooks for later career phases

The region should support varied driving without requiring race events. Its road topology remains compatible with future circuit, sprint, rally, drift, and time-trial routes.

The rest of the 6.144 km square address space stays logically valid and streamable but may remain sparse/proxy content.

## 5. Terrain and macro composition

### 5.1 Terrain goals

Phase 2 fallback terrain becomes a believable macro landscape with:

- rolling countryside
- elevated hill/mountain terrain
- shallow valleys and drainage shapes
- forest slopes
- road cuts and embankments
- farmland/open plains
- dirt-route terrain
- roadside shoulders that blend into surrounding ground

The road graph stays authoritative. Terrain generation/composition must accommodate road corridors instead of forcing roads to float above arbitrary terrain.

### 5.2 Terrain backend contract

Extend `TerrainBackendAdapter` with a narrow height/sample boundary suitable for environment placement and road blending. Gameplay systems must still not call third-party terrain APIs directly.

The built-in backend remains capable of booting and verifying the region. A Terrain3D adapter may be added only if Godot 4.7 compatibility is proven during implementation; Phase 3 must not require it.

### 5.3 No floating origin

Phase 3 does not introduce floating-origin rebasing. The current world scale does not justify the complexity.

## 6. Environment zones

The authored region is divided into explicit deterministic environment zones rather than random global scattering.

Initial zone classes:

- `countryside_open`
- `farmland`
- `forest`
- `hill_rocky`
- `rural_settlement`
- `industrial_service`
- `highway_corridor`
- `dirt_trail_corridor`
- `scenic_overlook`

`EnvironmentZoneDefinition` owns:

- stable zone ID
- world/cell ownership
- bounds/polygon or corridor reference
- vegetation palette IDs
- prop palette IDs
- density multipliers
- traffic density multiplier
- roadside-furniture policy
- ambient-audio hook IDs for later use
- future weather/environment tags without implementing weather

Zones are save-safe/data-safe identifiers and do not depend on scene-tree paths.

## 7. Deterministic world dressing

### 7.1 Placement service

A deterministic placement service derives candidate transforms from:

- stable world seed
- zone ID
- cell ID
- placement-layer ID

The same input must produce the same transforms across runs and platforms within defined tolerance.

Placement rules support:

- minimum/maximum road offset
- terrain slope range
- height range
- exclusion zones
- minimum spacing
- orientation alignment
- density multiplier
- asset-palette weighting

### 7.2 Hand-authored versus generated placement

Procedural/deterministic placement is used for repeated vegetation and ordinary roadside props. Hand-authored placement is reserved for hero locations, settlement composition, industrial yards, overlooks, and landmark structures.

Phase 3 does not build a full end-user world editor.

## 8. Vegetation system

Vegetation is layered by scale:

### Large vegetation

- trees
- tree clusters
- large shrubs

### Medium vegetation

- bushes
- hedges
- roadside growth

### Small vegetation

- grass
- weeds
- ground clutter

Repeated vegetation uses MultiMesh or an equivalent batched representation where practical. Quality profiles control:

- instance density
- draw distance
- shadow distance
- small-vegetation enablement
- LOD thresholds

Purely visual vegetation must not become authoritative gameplay collision. Collision is reserved for selected large trunks/obstacles and explicit gameplay-relevant structures.

## 9. Road presentation layer

Phase 2 road geometry and collision remain authoritative. Phase 3 adds a presentation layer driven by road profiles and segment metadata.

Supported additions:

- center lines
- lane divider markings
- edge lines
- shoulder transitions
- curbs where appropriate
- guardrails
- concrete/metal barriers
- chevron signs
- delineator posts
- directional signs
- basic speed/road signs
- utility poles where appropriate
- drainage/ditch dressing
- intersection/merge furniture
- road-edge wear/material variation hooks

Road furniture placement must be deterministic and cell-addressable.

Road presentation must not change the Phase 1/2 physical `surface_id` semantics.

## 10. Road-class visual identity

### Highway

- widest paved section
- clear shoulders
- high-visibility markings
- barriers/guardrails where needed
- larger signs
- high-speed sightlines

### Rural two-lane

- narrower carriageway
- softer shoulders
- vegetation/farms closer to road
- occasional driveways/structures
- restrained markings and wear

### Hill road

- elevation and tighter radii
- guardrails/rock boundaries
- chevrons
- scenic viewpoints
- stronger vertical composition

### Service road

- simpler markings
- workshop/industrial surroundings
- utility infrastructure

### Dirt trail

- irregular visual edge
- loose shoulders
- gravel/dirt transitions
- vegetation intrusion
- no normal civilian traffic by default

## 11. Built environment

The Phase 2 roadside test cluster evolves into a believable small rural/service area.

Initial modular building/prop categories:

- small houses
- roadside shop shells
- service/fuel-style building shell
- workshop/garage buildings
- farm sheds/barns
- industrial storage structures
- fences and walls
- parking areas
- utility poles and roadside utilities
- signs and small roadside props

Physical shells/locations are reserved for a future garage and dealership, but Phase 3 does not implement ownership, purchases, upgrades, or career UI.

No pedestrian navigation or pedestrian assets are introduced.

## 12. Navigation foundation

Phase 3 derives a routable graph from the Phase 2 road network.

`NavigationGraph` / `NavigationService` supports:

- directed road/lane connectivity
- legal traversal direction
- route distance/cost
- nearest-road or nearest-lane query
- path search between road positions
- route reconstruction as segment/lane IDs
- developer-only route debug visualization

No finished GPS/minimap UI is required.

Route data must be reusable later by traffic, police, event routing, and user route guidance.

## 13. Traffic lane graph

Traffic-specific lane topology derives from road geometry/profile data.

Each lane record contains:

- stable lane ID
- source road-segment ID
- travel direction
- sampled centerline/path
- nominal lane width
- speed limit
- start/end junction connectivity
- neighboring lane hooks
- permitted traffic class flags
- cell ownership references

Junction connectors bridge incoming lanes to valid outgoing lanes.

The graph validates against:

- dangling lane IDs
- impossible junction transitions
- wrong-way traversal
- disconnected declared connectors
- malformed sampling

Traffic lanes are not separately hand-authored duplicates of the road network unless a deliberate local override is required for a complex junction.

## 14. Traffic architecture

Traffic remains independent from racer AI and from the player controller.

### 14.1 TrafficManager

Owns:

- active traffic registry
- density targets
- simulation-level assignment
- cell/stream ownership
- spawn/despawn requests
- global traffic budget
- debug statistics

### 14.2 TrafficSpawner

Chooses spawn/despawn locations using lane graph and player visibility constraints.

Spawn rules:

- never intentionally spawn inside the player's immediate view cone at close range
- maintain minimum player distance
- require valid lane occupancy space
- obey zone/road traffic density
- obey total/nearby budgets
- avoid dirt trails unless explicitly enabled

Despawn occurs outside critical player view and only when safe for ownership/state cleanup.

### 14.3 TrafficAgent

Near-player behavior supports:

- lane following
- steering toward path target
- target-speed regulation
- following-distance regulation
- braking for slower/blocked traffic
- basic valid junction transition
- simple local collision avoidance/braking
- recovery after unrecoverable path/block situations

Traffic does not implement racer tactics, police pursuit, complex overtaking, traffic-light simulation, personality modeling, or aggressive rubber-banding.

## 15. Traffic simulation levels

Traffic uses simulation LOD to avoid paying player-vehicle physics cost for every car.

### Near — Full traffic simulation

- physical body/collision
- frequent steering/throttle/brake updates
- local obstacle/following response
- visual wheel/body updates

### Mid — Reduced simulation

- simplified movement/controller
- reduced decision frequency
- lane occupancy maintained
- collision policy may be simplified while preserving believable transitions

### Far — Logical/proxy or absent

- logical occupancy only where useful, or despawn
- no expensive per-wheel physics

The player vehicle always remains on the Phase 1 custom physics stack and is never silently converted to the traffic controller.

## 16. Traffic density and roster

Initial target is approximately 10–20 active civilian vehicles across the populated region, scaled by graphics/gameplay traffic density settings and actual performance findings.

Zone expectations:

- highway: highest density
- countryside: medium
- settlement/service: medium
- hill road: low-medium
- industrial/service: low-medium
- dirt trail: none by default

Initial civilian archetype target:

- compact hatchback
- sedan
- crossover/SUV
- pickup/light utility vehicle
- small van

Phase 3 may ship with 3–5 robust development vehicle archetypes. Free assets are preferred; placeholders remain acceptable when a final-production asset cannot be sourced without compromising implementation quality. Every imported asset remains subject to the existing asset registry/provenance pipeline.

## 17. Traffic vehicle controller boundary

Traffic vehicles use a purpose-built cheaper controller rather than instantiating the entire player-vehicle solver for all agents.

The controller must expose a narrow interface for:

- desired lane/path
- target speed
- steering/brake/throttle intent
- current velocity
- occupancy footprint
- collision/recovery state
- simulation level

This controller must remain replaceable without changing road/navigation data.

Near-player traffic must still collide believably with the player and world. Automated tests validate stability and ownership, not subjective realism.

## 18. Streaming integration

Environment and traffic integrate with the existing `WorldStreamManager`.

Each streamed cell may own/reference:

- terrain visual/collision
- road geometry/presentation
- vegetation groups
- roadside prop groups
- built-environment groups
- traffic spawn zones
- navigation/lane references

Rules:

- unloading a cell cannot delete the player
- traffic ownership must transfer or despawn cleanly when leaving streamed ranges
- deterministic environment instances must not duplicate after unload/reload
- traffic agents must not leak after repeated traversal
- road/navigation identity remains stable across streaming
- visual/HLOD content may remain beyond gameplay range without retaining full simulation

## 19. Static lighting and atmosphere

Phase 3 uses one polished daytime reference condition.

Target characteristics:

- readable slightly warm daylight
- stable directional shadows
- restrained atmospheric haze for depth
- strong road/terrain separation
- believable vehicle paint response
- no dynamic clock progression

The environment may contain static atmospheric fog/haze for visual depth. This is not a weather system and does not dynamically transition.

## 20. Surface behavior

Existing surface IDs remain authoritative:

- `asphalt_dry`
- `asphalt_wet`
- `gravel`
- `dirt`
- `grass`

The authored region primarily uses dry asphalt, gravel, dirt, and grass. `asphalt_wet` remains supported for testing but is not automatically driven by rain/weather in Phase 3.

No Phase 3 environment code may retune Phase 1 vehicle physics constants as a shortcut for world feel.

## 21. Asset and sourcing strategy

Implementation prioritizes:

1. autonomously retrievable free/open assets of sufficient quality
2. reusable procedural/shared materials
3. modular environment sets
4. Blender-generated or cleaned assets when necessary
5. robust placeholders rather than poor-quality final-looking assets

No paid asset is required for milestone closure.

Vehicle traffic assets prioritize exterior quality, consistent scale, separated wheels/pivots, cheap collision, and usable LODs. Full interiors are not required for ordinary civilian traffic.

## 22. Performance and scalability

Phase 3 makes world optimization measurable without claiming physical GPU performance from headless runs.

Architecture requirements:

- MultiMesh/batching for repeated vegetation/props
- shared materials where practical
- LOD metadata for environment meshes
- HLOD/proxy grouping for building/forest clusters where useful
- quality-profile-controlled vegetation density
- traffic simulation LOD
- separate gameplay and visual ranges
- stable cell ownership
- bounded traffic counts
- no unbounded per-frame road/placement generation

The existing 1080p60 GTX 1660 / RX 580-class project target remains. Final frame-rate, GPU-time, and VRAM claims require physical hardware.

## 23. Testing strategy

Phase 3 is implemented through TDD. Existing 83 Phase 0–2 manifest tests remain regression tests.

### 23.1 Environment contracts

- zone IDs validate and are unique
- deterministic placement reproduces transforms
- placement obeys road-offset/slope/exclusion rules
- repeated cell reload does not duplicate instances
- density scales predictably by quality profile
- vegetation/prop groups remain cell-addressable
- gameplay collision is not accidentally attached to all decorative vegetation

### 23.2 Road-presentation contracts

- markings follow source road geometry within tolerance
- guardrail/barrier placement follows valid road edges
- road furniture placement is deterministic
- junction/merge presentation does not break source collision
- Phase 2 road graph still validates
- surface IDs remain unchanged

### 23.3 Navigation contracts

- graph derives from current road network
- directed connectivity is valid
- route search succeeds across representative highway/rural/hill paths
- wrong-way traversal is rejected where direction-restricted
- nearest-road/lane query is deterministic
- route reconstruction contains only existing road/lane IDs

### 23.4 Traffic-lane contracts

- lane IDs are stable and unique
- lane geometry remains within source road bounds
- junction connectors reference valid lanes
- no dangling connectors
- road speed metadata transfers correctly
- prohibited roads do not receive traffic lanes

### 23.5 Traffic-agent contracts

- agent converges toward lane path
- speed controller converges without runaway acceleration
- following-distance logic reduces speed/brakes
- blocked lane triggers safe stopping/recovery behavior
- valid junction transition succeeds
- invalid connector traversal rejects
- recovery does not teleport into player view/occupied space

### 23.6 Traffic-manager/streaming contracts

- traffic counts respect budgets
- spawn points respect player-distance/visibility rules
- despawn removes ownership cleanly
- no duplicate agent IDs
- repeated traversal does not leak agents
- unloaded-cell ownership cannot retain invalid full-simulation agents
- simulation-level transitions are deterministic

### 23.7 Player integration contracts

- player remains on `VehicleController` custom physics
- player can collide with near traffic
- traffic cannot overwrite player surface state
- player reset/recovery remains operational
- traffic/world updates cannot delete or reparent the player incorrectly

### 23.8 Cross-platform closure

- full Linux repository verification passes
- native Windows repository verification passes at milestone closure
- no platform-specific gameplay divergence is introduced

## 24. Development tooling

Developer-only tooling may include:

- environment-zone debug visualization
- deterministic placement debug markers
- traffic-lane graph overlay
- navigation-route overlay
- traffic density/simulation-level statistics
- cell ownership visualization
- high-speed traversal probe

These tools must not become production UI dependencies.

## 25. Error handling and failure behavior

- Invalid environment-zone data fails validation with stable IDs in the error.
- Missing environment assets fall back to a safe placeholder or skip only that placement layer.
- Invalid traffic lane/connectivity data prevents affected graph sections from spawning traffic rather than crashing the entire world.
- Traffic agents that become irrecoverably blocked may despawn/respawn only outside player view according to policy.
- Streaming release always removes owned traffic/environment instances deterministically.
- Navigation query failure returns an explicit no-route result rather than an empty path that appears valid.
- Missing optional Terrain3D/plugin support falls back to the built-in backend.

## 26. Explicit non-goals

Phase 3 does not implement:

- dynamic day/night
- rain/weather transitions
- production wet-road weather state
- racer AI
- race event framework
- police AI
- pursuit/heat systems
- career/economy
- vehicle purchasing
- upgrades/tuning UI
- garage/dealership interaction UI
- finished minimap/GPS UI
- radio
- advanced traffic overtaking
- traffic personalities
- complex urban traffic lights
- pedestrians
- dense city center
- full 15–25 km² final world
- floating-origin rebasing
- end-user world editor

## 27. Completion gate

Phase 3 is complete only when all of the following are true:

1. Approximately 4–6 km² of connected authored terrain/environment exists inside the Phase 2 address space.
2. Highway, rural, hill, service, and dirt routes are geographically coherent and continuously driveable.
3. Terrain has meaningful elevation, cuts, slopes, and regional composition.
4. Road markings and representative road furniture are data-driven and aligned with the authoritative road geometry.
5. Forest, countryside, farmland, roadside-settlement, industrial/service, and scenic-overlook environment zones exist.
6. Repeated vegetation/props use scalable instancing/batching where practical.
7. Environment placement is deterministic and survives stream reload without duplication.
8. The rural/service built-environment cluster is materially more complete than the Phase 2 test cluster.
9. Garage and dealership physical-location hooks exist without career functionality.
10. A routable navigation graph derives from the road network.
11. Traffic lane data derives from road/network data and validates.
12. Basic civilian traffic can spawn, follow lanes, maintain speed/following distance, traverse basic junctions, and recover/despawn safely.
13. Traffic uses simulation LOD and does not require full player-vehicle physics cost for all agents.
14. Traffic density respects world zones and configurable budgets.
15. At least 3 traffic vehicle archetypes or robust development stand-ins are usable; target is 3–5.
16. Near traffic collides with the player/world without replacing the player physics controller.
17. Traffic integrates with world streaming without duplicate ownership or leaked agents.
18. Static daytime lighting presents the region coherently; no dynamic time/weather is required.
19. All existing Phase 0–2 contracts remain green.
20. New Phase 3 contracts remain green.
21. Linux full repository verification passes.
22. Native Windows full repository verification passes at milestone closure.
23. No mandatory paid dependency is introduced.
24. No temporary verification/bootstrap workflow remains on the delivered feature branch.
25. The resulting region is useful as an actual free-roam driving environment before races/career are added.

## 28. Post-Phase-3 dependency order

Phase 4 may then build motorsport framework and racer AI on top of:

- stable road/navigation data
- a complete driveable region
- working world streaming
- basic traffic occupancy
- stable player physics

Dynamic day/night and weather remain intentionally deferred until a later phase rather than being silently folded into Phase 3.