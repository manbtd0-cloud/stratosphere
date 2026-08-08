# Phase 3 Traffic Asset Reconnaissance

**Date:** 2026-08-08

Phase 3 needs 3–5 civilian traffic archetypes, but should not lower the visual target merely to replace development boxes with weak assets.

## Strong free candidates

### Vehicle Variety Pack — Switchboard Studios

- Source: https://www.fab.com/listings/dc1ada50-2523-44b1-b0e2-a72d14076fb4
- Fab currently marks the pack **Free** and describes it as part of Unreal Engine's “Free For Life” initiative.
- Includes sports car, hatchback, pickup, SUV, and box truck variants.
- Advertised as game-ready with interiors and no more than four material slots per vehicle except the box truck.
- Delivery format exposed by Fab is Unreal Engine rather than a portable GLB/FBX package.
- Phase 3 status: **production candidate, not imported**. Conversion/extraction must be validated before it can replace the Godot development stand-ins.

### Vehicle Variety Pack Volume 2 — Switchboard Studios

- Source: https://www.fab.com/listings/591e3b3f-9d49-4cd2-8e28-d471c1a10cab
- Fab currently marks the pack **Free**.
- Includes sedan, delivery box truck, SUV, and campervan.
- Advertised as game-ready, drivable, with interiors and roughly four material slots on average.
- Delivery format exposed by Fab is Unreal Engine.
- Phase 3 status: **production candidate, not imported**.

## Rejected for the current visual target

- RGSDev Free Low Poly Vehicles Pack: useful CC0 coverage but intentionally low-poly and below the project's near-camera visual target.
- Fab “PS1 Car Free”: intentionally PS1/low-poly and unsuitable as a production traffic visual.
- Fab “Car Free” customized sports car: portable GLB exists, but it does not provide the civilian archetype diversity needed for the traffic roster.
- CARLA content: realistic/open digital vehicle assets exist, but the content package and Unreal-oriented extraction pipeline are too heavy for this Phase 3 milestone.

## Current implementation decision

Keep five explicit Godot development archetypes (`compact`, `sedan`, `crossover`, `utility`, `van`) behind `TrafficRosterFactory`. Their simulation dimensions, collision proxies, provenance, and three runtime simulation/visibility LOD states are valid now. Replace presentation assets independently when a strong free pack can be converted cleanly; traffic navigation and behavior must not depend on a specific mesh pack.
