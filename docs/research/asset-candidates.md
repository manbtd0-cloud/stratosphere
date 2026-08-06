# Phase 0 Asset and Tool Reconnaissance

**Date:** 2026-08-06  
**Status:** Shortlist for controlled compatibility and performance spikes; nothing is approved for production integration yet.

## Selection rules

A candidate is not adopted merely because it looks useful. It must pass:

- Godot 4.7.1 import and editor stability
- Linux and Windows portability
- license/source recording in the asset registry
- exact scale and axis validation
- triangle, material, texture, collision, LOD, and shadow-mesh audit
- representative benchmark comparison
- no hard dependency on undocumented runtime behavior
- clean removal path if the plugin is rejected

## Road authoring

### Road Generator v0.9.3 — first road-tool spike

- Godot Asset Store package by TheDuckCow
- MIT license
- Minimum Godot version 4.4
- Updated 2026-07-17
- Creates procedural roads, lanes, intersections, collision, and AI lane paths
- Includes Terrain3D connector support

Why it is promising: its lane and collision data could reduce drift between visible roads, traffic routes, and later race paths.

Spike gate:

1. Install on an isolated branch.
2. Build one 2 km mountain road with intersections and banking.
3. Test collision continuity at high speed.
4. Measure editor responsiveness, generated triangle count, material count, and runtime draw calls.
5. Confirm generated lane data can be consumed without coupling gameplay code to plugin internals.
6. Reject it if generated geometry or data ownership prevents deterministic export.

Source: https://store.godotengine.org/asset/theduckcow/road-generator/

## Terrain

### Terrain3D — compatibility spike only

Terrain3D is a serious terrain candidate, but its exact Godot 4.7.1 compatibility must be verified before adoption. The project must not commit its world pipeline to a plugin whose supported engine range is unclear.

Spike gate:

1. Install the latest stable release in isolation.
2. Import a representative 4–6 km² heightmap.
3. Test sculpting, texture blending, collision, holes, road deformation, and runtime streaming behavior.
4. Confirm Linux and Windows editor support.
5. Compare memory, draw calls, and maximum-speed traversal against a native Godot terrain prototype.
6. Adopt only if plugin upgrade risk is acceptable and exported projects remain stable.

Project source: https://github.com/TokisanGames/Terrain3D

## Vegetation and prop scattering

### Scatter v0.0.1-alpha — experimental candidate

- Godot Asset Store package by xiaowangxu
- MIT license
- Minimum Godot version 4.7
- Editor-only graph tool that writes directly into native `MultiMesh` buffers
- Alpha maturity means it cannot be treated as production-safe without a destructive-edit and upgrade test

Source: https://store.godotengine.org/asset/xiaowangxu/scatter/

### ProtonScatter — fallback comparison

ProtonScatter is a more established open-source scattering option. A comparison spike should evaluate authoring speed, generated scene complexity, deterministic output, MultiMesh efficiency, and long-term Godot 4.7 maintenance.

Project source: https://github.com/HungryProton/scatter

Adoption gate for either tool:

- Scatter 100,000 representative vegetation instances.
- Verify editor save/reload and clean source control diffs.
- Measure draw calls, memory, culling, shadows, and high-speed traversal.
- Confirm generated output can be baked or retained without requiring the editor plugin at runtime.

## Environment materials and HDRIs

### Poly Haven — preferred initial CC0 source

Poly Haven provides CC0 HDRIs, textures, and models. It is suitable for lighting references, sky tests, PBR terrain/road material prototypes, and environment dressing, but every downloaded item still receives an asset-registry record and runtime-budget review.

Source: https://polyhaven.com/

Initial use:

- daylight, overcast, sunset, and night HDRI reference tests
- asphalt, dirt, rock, concrete, metal, and vegetation material prototypes
- source-quality comparison before texture packing and runtime compression

## Vehicle model sourcing

Downloaded vehicle models must be treated as source assets, not game-ready content.

Reject or rework models with:

- fused wheels or incorrect wheel pivots
- no usable interior when cockpit view is required
- uncontrolled material count
- missing normals or broken smoothing
- nonportable texture paths
- no practical LOD path
- unclear scale or forward axis
- excessive geometry without visible benefit

Triage guidance:

- A roughly 150k–250k triangle model can be a plausible hero-vehicle LOD0 source after inspection.
- A model around 1.2 million triangles is not accepted directly into runtime; it requires retopology or substantial decimation and an authored LOD chain.
- Low-poly cars with separate wheels and doors are useful traffic or pipeline prototypes even when they are unsuitable as hero vehicles.
- Brand, license, and source are always recorded, even though release licensing is not currently a constraint.

Potential browsing source: https://sketchfab.com/search?features=downloadable&type=models&q=car

## Decision

The first controlled spikes should be:

1. Road Generator for a mountain-road prototype.
2. Terrain3D versus a native terrain baseline.
3. Scatter versus ProtonScatter for vegetation.
4. Poly Haven for HDRI and PBR reference materials.
5. A separate-part RWD coupe model for the Phase 1 vehicle import pipeline.

No plugin or model is approved until its spike report and asset-registry record pass.
