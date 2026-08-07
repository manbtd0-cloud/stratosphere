# Initial RWD Coupe Asset Reconnaissance

**Date:** 2026-08-07  
**Purpose:** Identify current source assets worth controlled download and inspection for the Phase 1 prototype RWD coupe.  
**Status:** Reconnaissance only. No candidate is approved for production integration.

## 1. Asset strategy

Use two parallel candidates rather than forcing one asset to solve every problem immediately:

1. **Physics mule** — clean hierarchy, separated wheels, correct pivots, low import risk, fast to prepare. Visual quality may be temporary.
2. **Hero-car source** — strong exterior and cockpit detail, suitable topology or enough source quality to justify Blender cleanup and fictionalization.

The physics mule allows the vehicle solver and lab to progress while the hero asset is audited or rebuilt. The final production car may combine a selected base mesh with substantial original Blender work.

## 2. Evaluation criteria

Each downloaded candidate receives a scored inspection covering:

- exterior silhouette and close-up quality;
- cockpit and dashboard usefulness;
- real-world dimensions and proportions;
- separate wheel meshes;
- wheel-center pivots;
- named hierarchy;
- clean transforms and scale;
- topology and normals;
- UV quality;
- metallic/roughness PBR readiness;
- texture resolution and source files;
- material count;
- triangle count;
- LOD potential;
- collision suitability;
- modifiability and licensing record;
- debranding/fictionalization effort;
- Godot 4.7.1 import quality;
- Windows/Linux portability;
- expected cleanup time.

## 3. Priority shortlist

### Candidate A — Generic Sport Coupé Car by MMC Works

**Source:** Fab and Sketchfab  
**Cost:** Free  
**Formats:** FBX; converted GLB/glTF/USDZ also listed on Fab  
**Known features:** Generic sports-coupe design, embedded texture maps, simple interior, basic mechanical detail.

**Why inspect first**

- Generic design reduces debranding work.
- Free and downloadable.
- Interior is present.
- Visual proportions are suitable for a late-1990s/early-2000s-inspired RWD coupe.
- Could become either the physics mule or a base for substantial visual rebuilding.

**Unknowns requiring download inspection**

- Triangle and material counts
- Wheel separation and pivots
- UV quality
- Full cockpit suitability
- Object naming
- Texture resolution
- Topology under reflections

**Initial classification:** Highest-priority free inspection.

### Candidate B — Generic Sports Car 3

**Source:** Fab  
**Known geometry:** 48,220 triangles  
**Known structure:** Body, four wheels, and brake calipers use explicit names; wheel and brake origins are described as correctly placed.  
**Interior:** Low-poly interior intended mainly for exterior visibility.

**Why inspect**

- Strongest documented rigging structure among current generic candidates.
- Appropriate triangle count for a physics mule.
- Correctly placed wheel origins reduce pipeline risk.
- Generic enough for development use.

**Limitations**

- Cockpit is not intended for close-up interior driving.
- Photo-texture workflow may not meet final PBR standards.
- Likely better as physics mule or traffic source than final hero car.

**Initial classification:** Best documented physics-mule candidate.

### Candidate C — Tiara GT '83 by Daniel Zhabotinsky

**Source:** Sketchfab  
**Cost:** Free  
**Known geometry:** 18,800 triangles  
**Known features:** Generic 1980s import coupe, unwrapped UVs, simple interior and engine, broad permission to modify and use.

**Why inspect**

- Fictional/generic styling.
- Clear permission to modify.
- Small and manageable asset.
- Useful for testing the asset pipeline, wheel preparation, vehicle physics, and LOD tooling.

**Limitations**

- Low-poly visual target is below the final hero-car requirement.
- Doors do not open.
- Interior is simple.

**Initial classification:** Excellent backup physics mule and pipeline test asset.

### Candidate D — Nissan 350Z Japanese Sports Coupe with Interior by Bbenedict

**Source:** CGTrader  
**Cost:** Free  
**Format:** Blender source  
**Known geometry:** Approximately 971,702 polygons and 945,526 vertices  
**Known features:** Detailed interior, rigged version, unapplied-modifier version, Blender materials.

**Why inspect**

- Strong cockpit and exterior reference potential.
- Source Blender file and unapplied modifiers may support retopology and cleanup.
- Vehicle proportions closely match the desired front-engine RWD starter archetype.

**Major risks**

- Creator explicitly describes the file as poorly organized.
- Around 100 objects are not properly named.
- Much of the model is not UV unwrapped.
- Polygon count is far above runtime budget.
- Rig depends on Rigacar workflow.
- Requires extensive cleanup, retopology, material rebuilding, and fictionalization.

**Initial classification:** High-quality source/reference candidate, not direct runtime asset.

### Candidate E — Toyota Supra Mk4 free model by sudhakar2378

**Source:** Sketchfab  
**Cost:** Free  
**Known geometry:** 34,900 triangles  
**Known features:** Detailed interior, exterior, and engine; FBX/OBJ/STL; described as optimized for low-poly use.

**Why inspect**

- Promising middle ground between geometry cost and included detail.
- Interior and engine are claimed at a manageable triangle count.
- Could reveal whether a free asset can satisfy both physics and early visual needs.

**Risks**

- Page description is marketing-style and must be verified directly.
- Material, UV, hierarchy, pivot, and texture quality are unknown.
- Real branding requires fictionalization for production.

**Initial classification:** High-priority quality audit.

### Candidate F — Mazda RX-7 by wallon

**Source:** Sketchfab  
**Cost:** Free  
**Known geometry:** 361,500 triangles  
**Known texture information:** 2K PBR-style maps are listed for lights and wheels; Substance Painter was used for parts.

**Why inspect**

- Strong exterior surface quality and useful 1990s RWD-coupe proportions.
- Moderate high-poly source suitable for retopology rather than the million-polygon class.
- Useful benchmark for paint, glass, lights, wheels, and body reflections.

**Risks**

- Interior quality is not described.
- Full UV/material organization is unknown.
- Modified styling may require substantial fictionalization.
- Still too heavy for direct LOD0 use under the current budget.

**Initial classification:** Hero exterior/reference candidate.

### Candidate G — Toyota Supra MK5 A90 by lbrtwlk

**Source:** Sketchfab  
**Cost:** Free  
**Known geometry:** 857,100 triangles  
**Known features:** Detailed interior and ready-for-rig claim.

**Why inspect**

- Useful visual-quality and cockpit benchmark.
- Could provide material/interior workflow references.

**Limitations**

- Too modern and powerful in character for the inexpensive starter coupe.
- Very high cleanup and optimization requirement.
- Real branding and identifiable design.

**Initial classification:** Visual benchmark only unless inspection is unexpectedly clean.

### Candidate H — Nissan Silvia S13 by Lexyc16

**Source:** Sketchfab  
**Cost:** Free  
**Known geometry:** 31,500 triangles  
**Known features:** Stock RWD sports coupe with interior and miscellaneous detail.

**Why inspect**

- Excellent mechanical and visual archetype for the intended starter vehicle.
- Manageable geometry.
- Existing interior.

**Limitations**

- Attribution-NonCommercial license and NoAI restriction.
- Production use would require careful legal separation or replacement.
- Exact hierarchy, material quality, and wheel separation are unknown.

**Initial classification:** Development reference/spike only, not preferred final production source.

### Candidate I — BMW E36 coupe by RYBY_DLA_DEBILI

**Source:** Sketchfab  
**Cost:** Free  
**Known geometry:** 16,900 triangles  
**Known features:** Simple interior, realistic lights, exhaust, grille and rim textures; described as game-ready.

**Why inspect**

- Light asset with suitable RWD coupe proportions.
- Useful physics mule or scale reference.

**Limitations**

- Low geometry and simple interior are unlikely to support the final visual target.
- Real branding and recognizable body.

**Initial classification:** Secondary physics-mule candidate.

### Candidate J — Generic 80s Coupe with Interior

**Source:** ArtStation Marketplace  
**Known features:** Advertised as a highly detailed generic 1980s coupe with interior.

**Why inspect later**

- Generic shape and complete interior may reduce production rebuild effort.
- Could be a better hero base than free low-poly candidates.

**Unknowns**

- Price and exact license tier
- Triangle count
- texture sets
- hierarchy
- wheel pivots
- source formats
- runtime optimization

**Initial classification:** Paid fallback requiring full listing and file audit.

## 4. Candidates rejected before download

### Nissan Silvia S14 Kouki by marksform

Although it is a suitable RWD archetype and only about 9,200 triangles, its Attribution-NoDerivs license conflicts with the required cleanup, debranding, pivot correction, LOD generation, and fictionalization. It may be viewed as reference but should not enter the editable production pipeline.

### Extremely dense free Supra models without usable interiors

Models in the 700,000–2,700,000 triangle range that lack an interior or organized production source are not efficient starting points. They can be visual references, but rebuilding a clean fictional car from controlled source geometry is likely faster and safer.

### Mobile-level cars below roughly 6,000 triangles

These may be useful as distant traffic placeholders, but they cannot judge the Phase 1 AAA vehicle-material and cockpit pipeline.

## 5. Recommended download order

1. Generic Sport Coupé Car by MMC Works
2. Generic Sports Car 3
3. Tiara GT '83
4. Toyota Supra Mk4 by sudhakar2378
5. Nissan 350Z by Bbenedict
6. Mazda RX-7 by wallon
7. Nissan Silvia S13
8. BMW E36 coupe

Only the first four need immediate inspection. The 350Z and RX-7 are source-quality comparisons to determine whether cleanup is preferable to a custom Blender build.

## 6. Inspection procedure

For each candidate:

1. Download the original author-provided source format when possible.
2. Compute checksums and preserve the untouched archive.
3. Record source and license in the asset registry.
4. Open in Blender without applying transforms.
5. Capture front, rear, side, top, underside, cockpit, and wireframe screenshots.
6. Record dimensions, object count, triangle count, material count, texture memory, UV sets, and modifiers.
7. Test wheel separation and pivots.
8. Test door, steering-wheel, gauge, brake, glass, and light separation.
9. Check normals, nonmanifold edges, duplicate geometry, and negative scale.
10. Export an untouched GLB and import into Godot 4.7.1.
11. Record import warnings and generated resource size.
12. Place the asset in the Phase 0 visual inspection scene.
13. Score exterior, cockpit, structure, optimization, and cleanup effort.
14. Mark it `rejected`, `reference`, `physics_mule`, `hero_source`, or `production_candidate`.

## 7. Current recommendation

### Physics mule

Start with **Generic Sports Car 3** if its downloadable package matches the documented hierarchy and pivots. Use **Tiara GT '83** as the fallback because its permission and geometry are straightforward.

### Hero source

Inspect **Generic Sport Coupé Car by MMC Works** first because it is generic, free, and visually close to the intended class. Compare it against the **350Z** and **RX-7** source models to estimate the cleanup gap.

### Likely production outcome

The most probable high-quality route is:

- use a clean generic candidate as the mechanical proportions and hierarchy base;
- rebuild or heavily refine exterior surfaces in Blender;
- create a purpose-built fictional cockpit;
- author original PBR materials, lights, badges, wheels, and trim;
- create controlled LODs and collision meshes;
- keep all real branded models as temporary references only.

If no downloaded candidate passes the first inspection round, generate a custom Blender production brief for Codex rather than lowering the asset standard.

## 8. Next reconnaissance deliverable

After the first four downloads are available, produce a contact sheet and an audit table containing:

- rendered exterior and interior views;
- wireframe views;
- asset dimensions;
- triangle/material/texture counts;
- hierarchy and pivot verdict;
- estimated cleanup hours;
- Godot import verdict;
- role recommendation;
- final ranked selection.

## 9. Source pages reviewed

- Generic Sport Coupé Car: https://www.fab.com/listings/ccfbacb3-49dd-4719-b5ce-457753739068
- Generic Sports Car 3: https://www.fab.com/listings/a7792ea2-1b86-4960-ad81-612cf2af488a
- Tiara GT '83: https://sketchfab.com/3d-models/tiara-gt-83-low-poly-model-8918b07a427443cd8d1b334d9ad213a5
- Nissan 350Z with interior: https://www.cgtrader.com/free-3d-models/car/sport-car/nissan-350z-japanese-sports-coupe-with-interior-model
- Toyota Supra Mk4 by sudhakar2378: https://sketchfab.com/3d-models/toyota-supra-mk4-free-fast-and-furious-172e4b0b890a463e80e4dc483fffe7a6
- Mazda RX-7 by wallon: https://sketchfab.com/3d-models/mazda-rx-7-45cb02e634ed477a9a04bb19813443f2
- Toyota Supra MK5 A90: https://sketchfab.com/3d-models/toyota-supra-mk5-a90-30528ef37af844919074498f979b9515
- Nissan Silvia S13: https://sketchfab.com/3d-models/nissan-silvia-s13-updated-e398ad20e83d42e581ab43438d5b6e49
- BMW E36 coupe: https://sketchfab.com/3d-models/bmw-e36-7a16309e9d104000a5ab76f288d7b07e
- Nissan Silvia S14 Kouki: https://sketchfab.com/3d-models/nissan-silvia-s14-kouki-aca1fef31a804a09a181c9218a94d759
- Generic 80s Coupe with Interior: https://www.artstation.com/marketplace/p/ey8RD/generic-80s-coupe-with-interior
