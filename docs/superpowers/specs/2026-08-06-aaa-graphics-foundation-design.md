# AAA-Target Graphics Foundation Design

**Date:** 2026-08-06  
**Status:** Approved by the project owner  
**Engine:** Godot 4.7.1, Forward+  
**Desktop targets:** Windows x86_64 and Linux x86_64

## Goal

Establish a graphics and performance foundation that lets the project pursue the highest practical visual quality in Godot without sacrificing scalability, testability, or open-world performance.

“AAA-target” is a production standard, not a promise that a small project will match the budget or content volume of a major studio. The project will pursue AAA qualities where they matter most: physically based materials, lighting coherence, high-quality hero vehicles, strong environment composition, stable frame pacing, disciplined asset budgets, cinematic weather, and deliberate post-processing.

## Approaches considered

### 1. Ultra-only rendering

Author and run every effect at maximum quality. This produces attractive screenshots quickly but creates severe performance risk, hides scaling problems, and makes the GTX 1660 / RX 580 target unrealistic.

### 2. Cinematic authoring with scalable runtime profiles — chosen

Author assets, materials, lighting, and weather against a cinematic reference profile. Ship Low, Medium, High, and Ultra runtime profiles that selectively scale expensive systems while preserving the same art direction.

This approach keeps one visual identity and one asset pipeline while allowing different hardware to trade resolution, GI, reflections, fog, shadows, LOD, vegetation, and traffic density.

### 3. Performance-first visuals

Design exclusively around the minimum hardware and avoid advanced effects. This is safer, but it permanently limits the visual ceiling and conflicts with the project’s main ambition.

## Rendering architecture

### Forward+ only

The project uses Godot Forward+ for desktop. This allows SDFGI, VoxelGI, SSIL, SSR, volumetric fog, clustered decals, reflection probes, and compositor effects.

The Compatibility and Mobile renderers are not supported targets for the first major version.

### Central quality service

A `GraphicsQualityService` owns runtime graphics decisions. Gameplay code and scenes must not directly hard-code quality-dependent settings.

The service consumes a typed `RenderQualityProfile` and applies:

- Internal 3D resolution scale and scaling mode
- Temporal antialiasing policy
- Shadow atlas and directional shadow quality
- Mesh LOD threshold
- Volumetric fog enablement and density quality
- SSAO, SSIL, SSR, SDFGI, glow, and depth-of-field policy
- Reflection-probe update policy
- Decal distance
- Vegetation, prop, and traffic density multipliers
- Anisotropic filtering and texture LOD bias where runtime-safe

### Profiles

- **Low:** Stable fallback for weaker discrete GPUs. No real-time GI, minimal screen-space effects, reduced fog, shadows, reflection range, vegetation, and traffic.
- **Medium:** Primary GTX 1660 / RX 580 target. Strong PBR presentation, SSAO, reflection probes, conservative fog and shadows, automatic LOD, and optional FSR 2.2 quality scaling.
- **High:** Enables SDFGI, SSIL, stronger SSR, denser vegetation, longer shadows, and higher reflection quality.
- **Ultra:** Highest normal gameplay profile with improved GI, fog, reflections, shadows, decals, draw distance, and native or near-native resolution.
- **Cinematic:** Developer-only capture and validation profile. It is not a performance target and may exceed real-time budgets.

Every profile uses the same materials and scene content. Profiles vary quality and density rather than changing art direction.

## Lighting strategy

### Outdoor world

- Physically coherent directional sun and moon lighting
- Procedural or authored HDR sky resources
- SDFGI on High and Ultra for dynamic outdoor indirect lighting
- SSAO on Medium and above for contact depth
- SSIL as a detail complement on High and Ultra
- Reflection probes near garages, tunnels, wet road sections, fuel stations, and other critical reflective spaces
- SSR for contact reflections on wet asphalt and nearby vehicle surfaces where screen coverage allows it
- Scalable volumetric fog for atmosphere, rain, mountain haze, and headlight shafts

### Static interiors and enclosed facilities

LightmapGI is preferred for static garages, showrooms, and interiors where baking is practical. Reflection probes provide stable local reflections. Dynamic vehicles receive direct lighting and probe/GI contribution.

### Weather

Clear, overcast, rain, wet-road, fog, dawn, dusk, and night conditions share one exposure and color-management policy. Weather must change material response, visibility, reflections, road roughness, and lighting—not merely swap sky colors.

## Color and post-processing

- AgX or ACES tonemapping selected through measured scene tests
- Exposure values authored from physical lighting references and held consistent across scenes
- Glow used only for legitimately bright sources
- Color adjustment reserved for subtle final grading, not for repairing incorrect materials or lighting
- Motion blur remains optional and off by default until vehicle-speed testing proves it useful
- Depth of field is used in garage/photo contexts, not during normal high-speed driving
- Chromatic aberration and heavy vignette are excluded from default gameplay

## Material standard

All production 3D materials use a metallic-roughness PBR workflow.

Preferred texture packing:

- Albedo/base color in sRGB
- Normal map using normal-map import mode
- Packed ORM: ambient occlusion, roughness, metallic
- Emission only where physically justified
- Height/parallax only on close hero surfaces with measured cost

Rules:

- Backface culling enabled unless geometry genuinely requires two-sided rendering
- Reuse master materials and parameters to control shader permutations
- Avoid unnecessary custom shader branches
- Use decals for road wear, dirt, tire marks, damage detail, signage, and surface variation
- Use trim sheets, tileables, vertex color, and decals to reduce unique texture count
- Keep source textures at high quality; runtime imports use VRAM compression and mipmaps

## Asset budgets

Budgets are acceptance targets, not automatic rejection thresholds. Exceptions require a measured reason.

### Hero playable vehicle

- LOD0: approximately 150k–250k rendered triangles including interior
- LOD1: 45–60% of LOD0
- LOD2: 15–25% of LOD0
- LOD3/impostor: 5–10% of LOD0 where appropriate
- Exterior source textures: up to 4K per major set
- Interior source textures: 2K–4K based on cockpit visibility
- Target material slots: 8–14 after consolidation
- Separate wheels, steering wheel, brake components, glass, lights, and damage-relevant panels

### Traffic vehicles

- LOD0: approximately 35k–80k triangles
- Aggressive LOD chain for distance
- 2K source texture target
- Target material slots: 3–7
- Simplified interiors unless a vehicle can become playable

### Environment modules

- 1–4 materials per modular prop where practical
- 2K tileables and trim sheets as default
- 4K reserved for large hero surfaces or reusable atlases
- Automatic mesh LOD enabled on suitable imported meshes
- Artist-authored HLOD for building groups, forest clusters, and large compound assets
- Shadow meshes generated where beneficial

## Performance budgets

Primary gameplay target is 60 FPS, or 16.67 ms per frame, at 1920×1080 on the declared target class after appropriate profile and resolution scaling.

Phase 0 records rather than falsely guarantees hardware performance. Authoritative performance gates must run on identified physical hardware.

Budget guidance:

- GPU frame target: no more than 14.5 ms in representative gameplay, retaining margin for spikes
- Main-thread target: no more than 8 ms in representative gameplay
- Medium-profile VRAM target: no more than 4 GB sustained
- High-profile VRAM target: no more than 6 GB sustained
- No recurring gameplay shader/pipeline compilation spikes after warm-up
- No visible streaming stalls during maximum-speed traversal
- Stable memory across extended benchmark loops

## Shader and pipeline policy

Godot pipeline-compilation monitors are recorded during benchmark runs. The project will maintain a shader warm-up scene containing every production material family and particle family used by the current build.

Export presets enable shader baking where supported. Linux exports bake Vulkan shaders. Windows release validation is performed on Windows so both Vulkan and Direct3D 12 paths can be assessed when used.

New custom shader features require:

- A visual need not met by `BaseMaterial3D`
- A material-family owner
- A benchmark comparison
- A pipeline permutation review
- A fallback on lower profiles if expensive

## Benchmark architecture

Phase 0 creates three reproducible workloads:

1. **Graphics laboratory:** PBR materials, wet asphalt, vehicle paint proxy, glass, decals, lights, fog, reflections, and post-processing.
2. **Open-world proxy:** instanced trees, rocks, barriers, road modules, distant geometry, shadow casters, and high-speed camera travel.
3. **Pipeline warm-up:** every current material and shader family rendered before gameplay.

Benchmark reports include:

- Engine version
- Rendering method and device
- Operating system
- Resolution and quality profile
- Average FPS
- Minimum FPS
- Maximum frame time
- Frame count and duration
- Draw calls, objects, primitives, video memory where available
- Pipeline compilations for meshes, surfaces, and draws
- Whether the renderer is authoritative hardware or headless/software

Headless runs validate contracts and report structure. They never claim final GPU performance.

## Asset import automation

The asset registry validates:

- Stable ID and type
- Source and license note
- Runtime path
- Scale and axis convention
- Triangle and material counts
- Texture resolution
- Collision
- LOD chain
- Shadow mesh
- Rigging and movable parts
- Cockpit suitability
- Cleanup status
- Runtime status

Imported glTF is preferred. Blender source files may be retained outside the runtime asset tree, with deterministic `.glb` exports for production.

## Cross-platform policy

Windows and Linux use the same project data, GDScript, resources, and assets.

Platform-specific differences are restricted to:

- Export presets and binary extension
- Verification wrappers (`verify.ps1` and `verify.sh`)
- Graphics driver validation
- Controller/device testing
- File permissions and packaging
- Windows signing at release time

All resource paths use `res://` and `user://`. Filenames are exact-case and portable. `export_presets.cfg` is version-controlled; credentials remain under `.godot/export_credentials.cfg` and are ignored.

## Phase 0 completion gate

Phase 0 is complete only when:

- Settings and input foundations pass tests
- Atomic versioned saves pass corruption and backup tests
- Asset registry validates production metadata
- Graphics profiles apply and round-trip correctly
- Graphics lab and open-world proxy load successfully
- Benchmark reports contain all required fields
- Pipeline compilation counters are captured
- Windows and Linux verification wrappers remain aligned
- Export presets exist for Windows x86_64 and Linux x86_64
- Documentation defines material, texture, LOD, lighting, and performance standards
- No unresolved implementation placeholders remain in production files
