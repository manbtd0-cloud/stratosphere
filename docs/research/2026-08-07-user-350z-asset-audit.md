# User-Provided 350Z Starter Asset Audit

**Date:** 2026-08-07  
**Archive:** `350z.zip`  
**Role:** Selected Phase 1 starter/hero-source candidate  
**Source status:** User-provided; release licensing not verified

## Decision

Use this asset for Phase 1.

The editable low-cage source `350z/350z.blend` is the working master. The much heavier `350z/350zModifiers.blend` is retained only as a high-detail reference/baking source and must not be exported directly as the runtime vehicle.

## Archive contents

Primary sources:

- `350z/350z.blend` — 20,873,124 bytes, Blender 3.04 file
- `350z/350zModifiers.blend` — 146,179,233 bytes, Blender 3.05 file
- `.blend1` backups for both source variants
- tire/car normal maps
- plate/logo textures
- `parking_garage_8k.exr` look-development environment

## Low-cage source audit

`350z.blend` contains:

- 156 Blender objects
- 134 mesh datablocks
- 44 materials
- 14 image datablocks
- approximately 146,338 visible raw triangles for the vehicle when studio geometry and hidden backup objects are excluded
- raw vehicle bounds of approximately 1.92 m × 4.35 m × 1.32 m before evaluated modifier cleanup

The raw triangle figure does **not** include the full evaluated subdivision/mirror cost. Many surfaces retain Mirror and Subdivision Surface modifiers.

## High-detail source audit

`350zModifiers.blend` contains:

- 226 objects
- 170 mesh datablocks
- 49 materials
- 25 image datablocks
- approximately 1.87 million visible raw triangles

This version exceeds the Phase 0 hero-vehicle runtime budget by a large margin. It is useful for close-detail reference, normal baking, and selective geometry transfer only.

## Structural quality

Although many individual object names are generic Blender defaults, the source is organized into useful semantic collections:

- `Car`
- `BrakeL`
- `InterDash`
- `InterDoor`
- `Interier`
- `InterMidPanel`
- `InterSeats`
- `Steering`
- `jr11Wheels`
- `TireVol2`
- `Jr11Brake`
- `Windshield`
- `RearWindshield`
- `LightsRedux`

Separate wheel, tire, brake, steering, glass, lighting, body, and cockpit structures are therefore recoverable without remodelling the entire vehicle.

The active source includes four separately placed wheel/rim assemblies and four active tire objects, plus hidden backup geometry.

## Interior suitability

Material and collection structure confirms a modeled cockpit rather than an exterior-only shell. Dedicated materials include:

- seat leather
- steering leather
- steering carbon
- steering buttons
- dashboard rough plastic
- interior carpet
- interior roof
- dashboard/dial chrome
- windows/glass
- door/interior plastics

This is sufficient to justify building the Phase 1 cockpit camera around this source, subject to visual inspection after Blender/Godot conversion.

## Material cleanup

The source currently has 44 materials. Phase 0 allows 8–14 materials for the final hero LOD0, so the runtime preparation pass must consolidate aggressively.

Target runtime material families:

1. body paint
2. exterior dark trim
3. exterior metal/chrome
4. glass
5. lights/emissives
6. tires
7. wheels/brakes
8. interior plastic/carpet
9. interior leather/fabric
10. cockpit metal/carbon
11. gauges/screens/decals
12. optional damage/decal family

Additional families require measured justification.

## Geometry cleanup

The source cannot be exported with its existing high render-level subdivision settings.

Required preparation:

- preserve the low-cage file as immutable source
- create a production working copy
- remove studio floor/lights/cameras from exported vehicle data
- remove hidden backup objects from runtime exports
- apply/replace Mirror modifiers deterministically
- selectively use subdivision only where silhouette quality needs it
- reduce tire geometry substantially and move tread/logo detail into normal maps
- simplify wheel/brake geometry where close-up quality is preserved
- target 150k–250k triangles for LOD0 including cockpit
- create LOD1 at 45–60% of LOD0
- create LOD2 at 15–25% of LOD0
- create LOD3 at 5–10% of LOD0 where useful
- create lightweight shadow/collision meshes

## Texture/dependency audit

Several image datablocks point to machine-specific or missing external paths. Examples include:

- `C:\Users\...\IMG_0937__05946.jpg`
- `C:\Users\...\pilotsupersport_white_top3.webp`
- `C:\Users\...\Rectangle 1.png`
- missing external machine-shop HDRI
- missing external tire normal path

The archive does include useful alternate/source textures such as the tire normal maps and an 8K parking-garage EXR. Missing author-machine dependencies must be replaced or rebuilt rather than copied as broken paths.

Runtime textures will be repacked into project-owned metallic-roughness PBR sets with normal maps, ORM packing where practical, mipmaps, and VRAM compression.

## Branding and licensing

The source includes Nissan/350Z branding and JR wheel/logo references. For private Phase 1 development this can remain temporarily, but production preparation must isolate branding so it can be removed or fictionalized cleanly.

No legal license text was found in the archive. `License.png` is a license-plate texture, not a usage license. The asset registry must therefore record this source as user-provided with release rights unverified until separately established.

## Phase 1 use

The asset is accepted for:

- vehicle-physics integration
- wheel/suspension anchoring
- chase/hood/bumper/cockpit camera development
- material and reflection development
- LOD pipeline development
- collision/shadow-mesh preparation
- hero-car prototype presentation

The visual mesh remains decoupled from the physical solver so later replacement or fictionalization does not require rewriting vehicle physics.
