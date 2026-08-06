# Graphics and Asset Production Standard

This document is the acceptance checklist for every production asset and graphics feature.

## Rendering

- Renderer: Forward+
- Working color pipeline: linear HDR with measured tonemapping
- User profiles: Low, Medium, High, Ultra
- Developer profile: Cinematic
- Primary gameplay target: 1920×1080 at 60 FPS on GTX 1660 / RX 580-class hardware using an appropriate profile
- Performance claims require physical-hardware evidence

## Materials

- Metallic-roughness PBR
- Albedo in sRGB
- Normal maps imported as normal maps
- ORM packed where practical
- Mipmaps enabled for 3D textures
- VRAM compression enabled for runtime 3D textures
- Backface culling enabled unless explicitly justified
- Material reuse preferred over unique shader variants
- Decals preferred for local wear, road markings, dirt, and damage variation

## Hero vehicle budget

- LOD0: 150k–250k triangles including visible cockpit
- LOD1: 45–60% of LOD0
- LOD2: 15–25% of LOD0
- LOD3: 5–10% of LOD0 where applicable
- Exterior source maps: up to 4K
- Interior source maps: 2K–4K
- Materials after consolidation: 8–14
- Wheels, steering wheel, brake components, glass, lights, and damage-relevant panels must be separable

## Traffic vehicle budget

- LOD0: 35k–80k triangles
- Source maps: normally 2K
- Materials: 3–7
- Simplified interior accepted
- At least three usable LOD states or an approved automatic LOD result

## Environment budget

- Default texture size: 2K tileables or trim sheets
- 4K reserved for hero surfaces and shared atlases
- Automatic LOD enabled on suitable meshes
- HLOD required for compound buildings, forest clusters, and large prop groups
- Shadow meshes enabled where they reduce cost
- MultiMesh used for repeated vegetation and props

## Import checks

Every asset record must contain:

- Stable lowercase namespaced ID
- Asset kind
- Source and license note
- Runtime path
- Scale and forward/up axes
- Triangle count
- Material count
- Texture resolution
- Collision status
- LOD status
- Shadow-mesh status
- Rig/movable-part status
- Cockpit suitability
- Cleanup notes
- Runtime status

## Lighting and weather

- Physically coherent sun/moon direction and intensity
- SDFGI reserved for profiles that can afford it
- Reflection probes placed at visually critical reflective spaces
- SSR used as a local complement, not the only reflection source
- Volumetric fog density and length scaled by profile
- Wet weather changes roughness, reflection, grip presentation, and visibility
- Glow only for legitimately bright HDR sources

## Shader acceptance

A custom shader requires:

- Named material family
- Visual comparison against `BaseMaterial3D`
- Performance comparison
- Pipeline permutation review
- Lower-profile fallback if expensive
- Inclusion in the pipeline warm-up scene

## Frame and memory targets

- Frame: 16.67 ms target at 60 FPS
- Representative GPU target: no more than 14.5 ms
- Representative main-thread target: no more than 8 ms
- Medium VRAM target: no more than 4 GB sustained
- High VRAM target: no more than 6 GB sustained
- No recurring pipeline compilation spikes after warm-up
- No visible high-speed streaming pauses
