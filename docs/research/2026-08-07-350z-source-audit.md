# 350Z Starter-Car Source Audit

**Date:** 2026-08-07  
**Asset ID:** `vehicle.prototype_rwd_coupe`  
**Decision:** Accepted for Phase 1 development; release licensing remains unverified.

## Source archive

User-provided `350z.zip`:

- archive SHA-256: `7cd3cdf04c1e76996fe30260257e83f8438b3990f5c7eb21e653e2ec1c98eea9`
- archive size: 252,547,942 bytes
- working source: `350z/350z.blend`, SHA-256 `cdfd3bb6c7ddb67ad9cbef08e1ebad0234a67ef83f7570a7b657a135200c4ed7`
- high-detail reference: `350z/350zModifiers.blend`, SHA-256 `8bf833e1b25ac24e001f18bc459ececd900a2f877559cffcd72fba37bbc373c7`

The source archive is deliberately not committed to GitHub.

## Inspection result

The source is suitable for the starter car because it includes a real Blender authoring file, a detailed cockpit, and separable body/wheel/brake/interior collections rather than a single fused render mesh.

Approximate source characteristics from the audit:

- `350z.blend`: ~20.9 MB, 156 objects, 134 mesh datablocks, 44 materials, roughly 146k raw visible triangles before evaluated modifiers.
- `350zModifiers.blend`: ~146 MB and roughly 1.87M visible triangles; too heavy for runtime and retained only as bake/reference source.
- approximate dimensions: 1.92 m wide, 4.35 m long, 1.32 m high.
- cockpit data includes dashboard, seats, center console, steering wheel, gauges and interior materials.
- several author-machine texture paths are missing and require relinking/rebuilding during Blender preparation.

## Production policy

- `350z.blend` is the working master.
- `350zModifiers.blend` must never be exported directly into runtime content.
- LOD0 target: 150k–250k triangles including visible cockpit.
- LOD1: <=55% of LOD0.
- LOD2: <=25% of LOD0.
- LOD3: <=10% of LOD0.
- Consolidate 44 source materials to 8–14 runtime material families.
- Preserve separate wheels, brakes, steering wheel, glass, lights and cockpit hooks.
- Runtime axes are `-Z` forward and `+Y` up.
- Final release use is blocked until source licensing is verified or the mesh is replaced/fictionalized with release-safe provenance.

## Current limitation

Blender is not installed in the Linux verification environment. The deterministic preparation script is therefore syntax-checked here, but the final GLB/LOD exports remain a later asset-processing checkpoint rather than a claimed Phase 1 output.
