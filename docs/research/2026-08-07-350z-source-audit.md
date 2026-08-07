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

The source archive and derived model binaries are deliberately not committed while release provenance remains unverified.

## Inspection result

- `350z.blend`: ~20.9 MB, ~146k raw visible triangles and ~1.84M evaluated triangles with source subdivision.
- `350zModifiers.blend`: ~146 MB and ~1.87M visible triangles; reference/bake source only.
- runtime dimensions: about 1.98 m wide, 4.35 m long and 1.32 m high.
- cockpit includes dashboard, seats, center console, steering wheel and gauges.
- audited wheel pivots support a 2.66645 m scene wheelbase and 1.56642 m track.

## Runtime preparation result

Blender 5.2.0 LTS generated the textured runtime set twice with byte-identical outputs.

- LOD0: 247,186 triangles, 7,976,076 bytes.
- LOD1: 128,355 triangles, 5,123,824 bytes, 51.93% of LOD0.
- LOD2: 49,414 triangles, 2,979,408 bytes, 19.99% of LOD0.
- LOD3: 18,592 triangles, 2,101,008 bytes, 7.52% of LOD0.
- runtime material families: 14.
- embedded texture payload: 4 images / 4 textures.
- tire and carbon families carry embedded normal maps.
- the decal family carries embedded plate base-color and normal maps.
- paint, glass, lights, metal, brake, leather and interior families use explicit glTF-safe automotive PBR values.
- semantic hierarchy preserves body, cockpit, glass, steering wheel and four independent wheel pivots.
- all four textured GLBs import and bind successfully in Godot 4.7.1.

Geometry generation remains in `tools/vehicle/prepare_350z.py`. The material/texture entrypoint is `tools/vehicle/prepare_350z_textured.py`; it overlays explicit runtime materials, validates the exported GLB payload and records texture provenance in the generated audit.

Exact generator fingerprints and output hashes are recorded in `assets/source/vehicle/prototype_rwd_coupe/runtime_audit.json`.

## Production policy

- `350z.blend` remains the working master.
- `350zModifiers.blend` must never be exported directly into runtime content.
- runtime axes are `-Z` forward and `+Y` up.
- source and derived binaries remain out of GitHub while release licensing is unverified.
- public/commercial use remains blocked until provenance is verified or the mesh is replaced/fictionalized with release-safe source material.
