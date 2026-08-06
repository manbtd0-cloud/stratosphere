# Open-World Racing Game — Master Design Specification

**Date:** 2026-08-06  
**Engine:** Godot 4, Forward+ renderer  
**Primary platform:** Windows PC  
**Development strategy:** Polished vertical slice first, backed by production-grade modular systems

## Product vision

Build a large single-player open-world driving and racing game with the broad freedom of modern open-world racers but a more grounded, realistic presentation. Vehicles are normal automobiles without faces, eyes, dialogue, or anthropomorphic behavior.

The experience combines seamless free roam, serious simcade handling, structured motorsport, sandbox career progression, vehicle ownership, upgrades, tuning, repair, named rivals, believable vehicle-only traffic, light police activity, dynamic time, and weather.

## Core decisions

- Windows PC only for the first major version.
- Godot 4 Forward+.
- Single-player only.
- Keyboard-first input with controller support.
- Automatic and manual transmission.
- No rewind.
- Manual vehicle reset plus automatic stuck recovery.
- Chase, hood, bumper, and cockpit cameras.
- Realistic modern visual target scaled to GTX 1660 / RX 580-class hardware.
- Any useful development asset may be used regardless of final-release licensing.

## Design pillars

### Driving comes first

Handling must feel weighty, predictable, and skillful without becoming a hardcore simulator. Suspension, tire grip, braking, weight transfer, drivetrain, gearing, tuning, surfaces, assists, and damage must produce meaningful differences.

### Complete slice before expansion

The first major milestone is a polished 4–6 km² mountain-and-countryside region. It must be enjoyable on its own and become part of the final world rather than a disposable demonstration.

### Production-grade core systems

Vehicle, world, race, AI, career, save, input, audio, damage, weather, and asset systems must be modular, data-driven, independently testable, and expandable.

### Grounded world

The atmosphere is serious and restrained rather than a nonstop festival. The world uses believable roads, traffic, terrain, garages, dealerships, rural settlements, and motorsport facilities.

## Initial vertical slice

The first region contains:

- Mountain ascent and descent roads
- Countryside and farmland
- Forest routes
- A highway segment
- A small rural town
- Garage and dealership
- Quarry or industrial area
- Dirt rally trails
- Scenic overlooks
- Traffic routes
- A light police patrol area
- Physical event locations

Initial content:

- One polished rear-wheel-drive sports coupe
- Three to five traffic vehicle models
- One named rival
- Circuit, sprint, rally, drift, and time-trial events
- Money and reputation
- Basic upgrades and meaningful tuning
- Damage and repair
- Dynamic day/night and basic weather
- Save/load progression
- Four camera views

## Long-term world

The complete world targets approximately 15–25 km² and emphasizes mountains, countryside, forests, long highways, desert, coast, rural settlements, and industrial areas. Dense city space is limited because it is expensive to build and optimize well.

Regions must transition naturally. Every major road should support racing, cruising, drifting, rallying, shortcuts, exploration, traffic, police encounters, or scenic driving.

## Vehicle physics

Each vehicle configuration supports:

- Mass and center of gravity
- Per-wheel suspension travel, spring force, and damping
- Longitudinal and lateral tire slip
- Surface-dependent grip
- Weight transfer
- Front-, rear-, and all-wheel drive
- Engine torque curve
- Gear ratios and final drive
- Differential behavior
- Drivetrain losses
- Brake force and balance
- Aerodynamic drag and downforce
- Damage-dependent handling and performance

Keyboard driving uses progressive steering, speed-sensitive steering, throttle and brake ramping, counter-steer assistance, and optional traction control, ABS, and stability control. Analog controller input uses less smoothing.

Player tuning includes tire pressure, gearing, final drive, suspension stiffness, damping, ride height, brake force, brake balance, differential locking, steering sensitivity, and assists. Values remain within validated ranges.

The first car must demonstrate stable straight-line travel, predictable braking, recoverable oversteer, wet/dry differences, reliable automatic/manual transmission, frame-rate consistency, and no jitter, wheel explosions, random flipping, or unexplained energy gain.

## Damage

Damage has visual and mechanical consequences without simulating every individual component. Supported effects include scratches, dents, body deformation, alignment drift, suspension degradation, tire grip loss, engine power loss, and increased drag. Garages and post-event service restore the vehicle.

## Architecture

### Vehicle system

Owns physics, input, assists, transmission, drivetrain, tuning, damage hooks, cameras, and telemetry. Vehicle-specific values live in dedicated resources.

### World system

Owns region streaming, terrain, roads, props, vegetation, collisions, traffic zones, event locations, audio zones, weather, time, and surface state.

### Race system

One configurable framework supports circuit, sprint, rally, off-road, drift, drag, time trial, and endurance through event resources containing route, checkpoints, laps, eligibility, opponents, weather, time, rewards, penalties, traffic, police, and difficulty.

### AI system

Racer, traffic, and police AI are separate modules. Racer AI uses authored racing lines plus braking, overtaking, defense, recovery, surface awareness, vehicle capability, aggression, consistency, reaction, and awareness. Named rivals use distinct parameter profiles without impossible power boosts.

Traffic supports lane following, speed limits, intersections, simplified right-of-way, safe overtaking, crash response, blocked-road response, temperaments, invisible spawning, and reduced distant simulation. There are no pedestrians.

Police support patrol, detection, basic pursuit, line-of-sight loss, search, escape, and small fines. Helicopters, deep heat systems, impounding, and advanced roadblocks are excluded initially.

### Career system

Owns money, reputation, licenses, championships, vehicle ownership, named rivals, event eligibility, and region/facility unlocks. The game has no full story campaign. The player begins with an inexpensive RWD coupe and limited funds.

### Save system

Stores versioned player progress, money, reputation, licenses, championships, owned vehicles, upgrades, tuning, damage, event results, discovered locations, unlocked regions, settings, and current vehicle. Purchases and rewards must be atomic and recoverable.

### Boundaries

Vehicles report state but do not grant rewards. Races report results but do not directly modify ownership. Career logic owns progression. Save logic serializes state but does not define gameplay rules. UI is not the source of truth.

## World streaming and roads

The world is divided into spatial cells. Nearby cells use full detail, collision, audio, traffic, and AI. Distant cells use simplified terrain, meshes, vegetation, shadows, proxies, and reduced or disabled simulation.

Road data should define centerline, lanes, width, shoulders, surface, speed limit, traffic direction, AI paths, racing hints, spawn zones, guardrails, roadside props, wetness, and grip. Road mesh, traffic navigation, and race routes should derive from shared or closely linked data.

Required optimization includes LODs, occlusion culling, mesh/material reuse, instancing, adjustable shadows, vegetation and traffic density, separate visual/physics ranges, distant proxies, and profiling at maximum vehicle speed.

## Racing and events

Core disciplines are road, street, rally, off-road, drift, drag, time trial, and endurance. The vertical slice begins with circuit, sprint, rally, drift, and time trial.

Events are discovered by driving to their physical locations. Discovered or completed events may later be launched from the map or garage. The framework supports checkpoints, laps, wrong-way detection, timing, position, penalties, opponents, traffic, weather, police rules, rewards, vehicle restrictions, and difficulty.

## Career and economy

The loop is: explore, discover events, compete, earn money and reputation, upgrade and tune, purchase vehicles, earn licenses, qualify for championships, defeat rivals, and unlock facilities and regions.

Money funds vehicles, performance parts, cosmetic changes, repairs, and occasional entry fees. The game excludes fuel costs, insurance, mandatory daily upkeep, loot boxes, randomized upgrade parts, and real-time waiting.

## Difficulty

The player chooses fixed difficulty presets with optional mild adaptation to AI consistency, mistakes, aggression, braking precision, and overtaking confidence. AI cannot teleport, gain impossible power, ignore collisions, or use extreme rubber-banding.

## UI and garage

The HUD shows speed, RPM, gear, minimap, route guidance, damage, position, laps, time, and checkpoints. Menus cover garage, dealership, tuning, upgrades, repairs, owned cars, event map, career, input, graphics, audio, and accessibility. The garage is menu-based with a visible rotatable 3D vehicle.

## Time, weather, and audio

Initial weather includes clear conditions, cloud variation, rain, wet roads, and appropriate fog. Weather affects grip, braking, visibility, lighting, reflections, AI speeds, and traffic where suitable.

Audio priority is engine, tires, transmission, suspension, collisions, wind, traffic, weather, environment, then radio. Vehicle audio supports RPM, load, throttle transitions, drivetrain, forced induction, exhaust character, and surface-dependent tire sound.

## Asset pipeline

Every asset receives a record of source, known license, format, scale, orientation, polygon count, materials, textures, collision, LODs, rigging, cleanup, cockpit suitability, and runtime status.

Vehicle preparation validates scale and axes, separates wheels, verifies pivots and suspension points, consolidates materials, creates collisions and LODs, assesses the interior, adds camera anchors and damage hooks, imports into the standard vehicle scene, and passes automated plus driving checks.

## Testing and failure handling

Automated checks cover vehicle stability, braking, acceleration, gearing, drivetrain, suspension, frame-rate behavior, tuning persistence, wet/dry handling, damage, reset, race checkpoints, lap counting, wrong-way detection, rewards, AI completion, streaming, collision continuity, traffic spawning, navigation, time/weather transitions, memory stability, purchases, locks, save migration, and ownership restore.

Missing assets use safe placeholders. Invalid event data fails validation. Corrupted saves retain backups. Streaming failures identify the affected region without blocking the entire game. Unrecoverable AI respawns outside view. Failed purchases and rewards cannot partially apply.

## Delivery phases

0. Project and technical foundation
1. Vehicle laboratory
2. Road and world foundation
3. Complete driving region
4. Motorsport framework and AI
5. Career and economy
6. Police, radio, expanded damage, UI, and settings
7. Vertical-slice quality gate
8. Full-world expansion

Expansion begins only after the vertical slice is stable, performant, enjoyable, save-safe, and complete across its core systems.
