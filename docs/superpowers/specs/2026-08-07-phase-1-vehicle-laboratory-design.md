# Phase 1 Vehicle Laboratory Design Specification

**Date:** 2026-08-07  
**Project:** Open-World Racing Game  
**Engine:** Godot 4.7.1 Forward+  
**Physics backend:** Built-in Jolt Physics  
**Development platforms:** Windows x86_64 and Linux x86_64  
**Status:** Design ready for user review before implementation planning

## 1. Purpose

Phase 1 creates the production vehicle foundation and proves that one inexpensive front-engine, rear-wheel-drive coupe can feel believable, responsive, controllable, and enjoyable before the open world, traffic, racing AI, or career content expands.

The phase is not a disposable prototype. Its physics, data resources, telemetry, tests, camera contracts, asset preparation rules, and tuning workflow must become the basis for every later playable vehicle.

The visual target remains ambitious, but Phase 1 prioritizes the correct order:

1. stable physical behavior;
2. useful driving feel;
3. repeatable tuning and measurement;
4. production-quality vehicle presentation;
5. scalable performance.

## 2. Phase success criteria

Phase 1 is complete only when all of the following are true:

- One RWD coupe is playable with keyboard and controller.
- Automatic and manual transmission both work.
- Chase, hood, bumper, and cockpit cameras work without jitter.
- The vehicle demonstrates believable acceleration, braking, cornering, weight transfer, oversteer, recovery, suspension travel, and surface response.
- Dry asphalt, wet asphalt, gravel, and dirt produce measurably different grip and braking behavior.
- ABS, traction control, stability control, counter-steer assistance, and keyboard smoothing can be independently enabled and tuned.
- The vehicle remains stable across the supported physics/render frame-rate matrix.
- No spontaneous energy gain, random flipping, wheel explosions, chronic jitter, or repeated ground penetration occurs.
- Every tunable value lives in typed resources rather than scene-local magic numbers.
- Automated tests and recorded telemetry catch regressions.
- The first hero-car asset passes scale, orientation, topology, wheel, interior, material, collision, LOD, and performance gates.

## 3. Scope

### Included

- Custom vehicle physics architecture
- Four-wheel suspension and tire contact
- Engine, clutch, transmission, differential, brakes, and aero
- Vehicle assists
- Keyboard and controller input integration
- Vehicle telemetry and debug visualization
- Vehicle reset and recovery
- Four gameplay camera views
- Basic mechanical damage hooks
- Vehicle asset preparation pipeline
- Vehicle laboratory test environment
- Automated physics and integration tests
- One polished RWD coupe

### Excluded

- Traffic AI
- Rival AI
- Police
- Career progression
- Dealership transactions
- Race events
- Full open-world streaming
- Final radio system
- Large vehicle roster
- Detailed soft-body deformation
- Full engine sound production
- Online features

These excluded systems may consume Phase 1 interfaces later but must not be embedded into the vehicle controller.

## 4. Approaches considered

### Approach A — Godot `VehicleBody3D` and `VehicleWheel3D`

**Advantages**

- Fastest route to a moving car
- Minimal custom code
- Useful for simple arcade prototypes

**Disadvantages**

- Limited tire and suspension control
- Poor fit for combined slip, load sensitivity, detailed assists, or realistic tuning
- Difficult to validate and evolve into the intended handling model
- Godot documentation explicitly warns that the vehicle nodes have known issues and are not designed for realistic 3D vehicle physics

**Decision:** Rejected.

### Approach B — Custom `RigidBody3D` chassis with modular wheel-force solver

**Advantages**

- Full control over suspension, tire forces, drivetrain, assists, damage, and telemetry
- Natural collisions and rigid-body interaction through Jolt
- Pure calculation modules can be unit tested separately from scenes
- Supports future FWD, RWD, AWD, road, rally, drift, and off-road vehicles
- GDScript-first implementation remains accessible and editable

**Disadvantages**

- More implementation and tuning work
- Requires disciplined testing to prevent unstable force combinations
- GDScript performance must be measured before scaling to many fully simulated vehicles

**Decision:** Selected.

### Approach C — Native C++/GDExtension tire and chassis solver immediately

**Advantages**

- Highest possible performance ceiling
- Greater control over numerical integration and profiling

**Disadvantages**

- Adds build complexity on Windows and Linux
- Slows iteration during the most tuning-heavy phase
- Premature before GDScript performance is measured

**Decision:** Deferred. The architecture must keep pure solver interfaces narrow enough that a future native implementation could replace individual modules without changing gameplay code.

## 5. Core architecture

The vehicle system is split into data, pure force calculations, scene integration, presentation, and tooling.

```text
src/vehicle/
  data/
    vehicle_definition.gd
    body_config.gd
    wheel_config.gd
    suspension_config.gd
    tire_config.gd
    engine_config.gd
    transmission_config.gd
    differential_config.gd
    brake_config.gd
    aero_config.gd
    assist_config.gd
    damage_config.gd
  physics/
    vehicle_controller.gd
    vehicle_simulation_state.gd
    wheel_contact_solver.gd
    suspension_solver.gd
    tire_force_solver.gd
    engine_solver.gd
    clutch_solver.gd
    transmission_solver.gd
    differential_solver.gd
    brake_solver.gd
    aero_solver.gd
    assist_solver.gd
  presentation/
    wheel_visual_controller.gd
    vehicle_camera_rig.gd
    vehicle_effects_bridge.gd
    vehicle_audio_bridge.gd
  telemetry/
    vehicle_telemetry.gd
    telemetry_recorder.gd
    telemetry_overlay.gd
  recovery/
    vehicle_recovery_service.gd
  validation/
    vehicle_definition_validator.gd
    vehicle_asset_validator.gd
scenes/vehicle/
  prototype_rwd_coupe.tscn
scenes/labs/
  vehicle_lab.tscn
```

### Boundary rules

- `VehicleController` applies forces and owns the live `RigidBody3D` state.
- Pure solver classes receive explicit values and return results; they do not access the scene tree, input singleton, UI, or save data.
- Input routing produces driver intent, not direct forces.
- The transmission requests torque; it does not read keyboard keys.
- The camera reads vehicle telemetry and anchors; it does not modify handling.
- Visual wheel transforms never become the source of physical wheel state.
- Damage modifies validated configuration multipliers; it does not directly overwrite arbitrary physics fields.
- UI and audio consume telemetry and signals only.

## 6. Physics backend and timing

- Explicitly select built-in Jolt Physics in project settings.
- Run Phase 1 at 120 physics ticks per second.
- Enable physics interpolation for visual smoothness.
- Run driving logic and force application in the physics integration path only.
- Use exact-case resource paths and platform-neutral `res://` and `user://` paths.
- Never claim bitwise determinism. Godot rigid-body simulation is not guaranteed deterministic.
- Automated tests use tolerances and repeatability bands rather than exact identical trajectories.

The 120 Hz choice is a Phase 1 quality target. Later phases may compare 60, 90, and 120 Hz on physical hardware, but reducing the tick rate requires evidence that handling remains within approved tolerances.

## 7. Vehicle scene contract

The root is a `RigidBody3D` with uniform scale `(1, 1, 1)`.

Required children and anchors:

```text
VehicleController (RigidBody3D)
  CollisionRoot
    ChassisCollision
  VisualRoot
    BodyExterior
    BodyInterior
    Glass
    Lights
    WheelVisualFL
    WheelVisualFR
    WheelVisualRL
    WheelVisualRR
  WheelAnchors
    WheelFL
    WheelFR
    WheelRL
    WheelRR
  CameraAnchors
    ChaseAnchor
    HoodAnchor
    BumperAnchor
    CockpitAnchor
    LookTarget
  EffectsAnchors
    ExhaustAnchor
    TireFL
    TireFR
    TireRL
    TireRR
  DebugRoot
```

Physical and visual origins must be explicit. The chassis origin represents the modeled center-of-mass reference, while the actual center of mass is configured through validated body data.

## 8. Vehicle data model

### `VehicleDefinition`

A single top-level resource references all subsystem resources and presentation metadata.

Required fields:

- stable vehicle ID
- display name
- body configuration
- four wheel configurations
- suspension configuration
- tire configuration
- engine configuration
- transmission configuration
- differential configuration
- brake configuration
- aero configuration
- assist defaults
- damage configuration
- visual scene path
- collision scene path
- camera anchor contract
- sound profile ID
- telemetry validation profile

### Validation policy

A vehicle definition is rejected before play if:

- mass is nonpositive;
- wheelbase or track width is invalid;
- wheel radii differ from asset dimensions beyond tolerance;
- suspension travel is nonpositive;
- spring or damping values are nonphysical;
- torque curves are unsorted or empty;
- gear ratios contain invalid forward ratios;
- final drive is nonpositive;
- tire force curves are incomplete;
- brake bias is outside validated bounds;
- driven wheels conflict with differential type;
- required anchors or visual meshes are missing.

## 9. First vehicle baseline

Internal ID: `vehicle.prototype_rwd_coupe`

The first car is fictional even if a real-world model is temporarily used as a development reference.

### Target physical character

- Front-engine, rear-wheel drive
- Naturally aspirated 2.0-liter inline-four analogue
- 180 hp target peak output
- 200 Nm target peak torque
- 1,180 kg curb mass
- 53:47 front/rear static weight distribution
- 2.45 m wheelbase
- Approximately 1.45 m track width
- 205/50 R16-equivalent tires
- Six-speed manual gearbox
- Optional automatic shift logic using the same gearbox
- Clutch-type limited-slip differential
- No aerodynamic downforce package
- Mild factory ABS and optional traction/stability assistance

This car should be quick enough to expose oversteer and drivetrain behavior but slow enough that weak physics cannot hide behind extreme power.

## 10. Wheel contact model

Each wheel uses authored anchors and three contact probes:

- center probe for primary suspension length;
- inner probe for curb and road-crown awareness;
- outer probe for curb and road-crown awareness.

The solver combines valid hits into one contact patch with:

- contact point;
- averaged normal weighted toward the center probe;
- contacted body and surface ID;
- suspension distance;
- local contact velocity;
- road tangent basis;
- confidence value.

Rules:

- Center probe controls whether the wheel is considered grounded under normal conditions.
- Side probes improve stability on curbs and sharply changing road surfaces but cannot create suspension force alone when the center probe is far from contact.
- Contact normals are filtered over a very short configurable window to reduce mesh-edge noise without delaying real terrain changes.
- Wheel queries exclude the owning vehicle.
- Contact state records the contacted rigid body velocity for moving platforms or later transport systems.

A wheel-shape-cast alternative remains available behind the same interface if ray sampling fails curb or terrain tests.

## 11. Suspension model

Per-wheel suspension force uses:

- spring compression;
- compression and rebound damping;
- suspension velocity;
- bump stop force;
- droop limit;
- wheel unsprung-mass approximation;
- anti-roll coupling per axle.

The suspension applies force at the wheel contact position, not at the chassis center, so pitch and roll emerge from force placement.

Required behavior:

- Compression damping and rebound damping are independently configurable.
- Bump stops ramp progressively rather than creating an instantaneous infinite wall.
- Anti-roll bars transfer force only between wheels on the same axle.
- Airborne wheels produce no road force.
- Suspension travel never becomes negative or exceeds configured limits.
- Visual wheel travel follows physical travel after interpolation.

## 12. Tire model

Phase 1 uses a configurable curve-based brush/Pacejka-inspired model rather than a full empirical tire simulation.

Inputs:

- normal load;
- longitudinal slip ratio;
- lateral slip angle;
- wheel angular velocity;
- contact-patch velocity;
- tire radius;
- surface friction multiplier;
- wetness;
- temperature placeholder fixed at nominal in Phase 1;
- damage multiplier;
- camber placeholder fixed from suspension geometry in Phase 1.

Outputs:

- longitudinal force;
- lateral force;
- aligning torque estimate;
- rolling resistance;
- slip energy for effects and audio;
- normalized grip utilization.

Required characteristics:

- Force rises progressively near zero slip.
- Peak grip occurs at configurable slip.
- Force falls gradually after the peak instead of snapping to zero.
- Combined longitudinal/lateral demand is limited by a friction ellipse.
- Grip varies with load using configurable load sensitivity.
- Wetness reduces peak grip and shifts optimal slip.
- Gravel and dirt use broader, lower peaks and higher rolling resistance.
- Lateral and longitudinal relaxation lengths prevent instantaneous force changes.
- Standing still does not generate numerical explosions from division by near-zero velocity.

## 13. Drivetrain

### Engine

The engine solver provides:

- torque-curve interpolation;
- idle control;
- engine inertia;
- throttle response;
- engine braking;
- soft and hard rev limiting;
- accessory/drivetrain loss hooks;
- stall behavior when assists permit it.

### Clutch

The clutch solver supports:

- manual clutch intent;
- automatic clutch assistance;
- configurable engagement curve;
- slip torque limit;
- launch assistance limits;
- stall protection option.

### Transmission

- Reverse, neutral, and six forward gears
- Validated gear and final-drive ratios
- Shift delay and torque interruption
- Manual and automatic modes
- Automatic logic based on throttle, engine speed, vehicle load, and hysteresis
- No instant oscillation between adjacent gears

### Differential

The first vehicle uses a clutch-type limited-slip model with:

- preload;
- power locking;
- coast locking;
- maximum torque bias;
- wheel-speed difference response.

Torque distribution must conserve input axle torque except for explicitly modeled losses.

## 14. Braking and assists

### Brake system

- Front/rear brake bias
- Service brake
- Handbrake acting on rear wheels
- Speed-independent requested pedal force
- Brake fade hook reserved but disabled in Phase 1

### ABS

ABS reduces brake demand per wheel when slip exceeds a configurable threshold and restores it progressively. It must pulse through controlled modulation rather than toggling full braking on and off every frame.

### Traction control

Traction control reduces requested drive torque when driven-wheel slip exceeds the configured target. It may not create grip or apply hidden forward force.

### Stability control

Stability control compares driver steering intent with measured yaw response and may apply bounded individual-wheel braking plus bounded engine-torque reduction. It cannot directly rotate the chassis.

### Keyboard assistance

Keyboard input uses:

- steering rise and fall rates;
- speed-sensitive maximum steering;
- throttle and brake ramping;
- counter-steer assistance;
- optional stability assistance;
- separate values from analog controller input.

Every assistance layer must expose telemetry showing its intervention amount.

## 15. Aerodynamics and resistance

Phase 1 models:

- frontal drag proportional to velocity squared;
- rolling resistance through tire forces;
- optional lift/downforce coefficients per axle;
- air resistance direction based on local relative air velocity;
- no active aero.

The prototype coupe uses negligible downforce. Aero must not be used to fake low-speed stability.

## 16. Damage hooks

Phase 1 does not implement full deformation, but collision events feed a typed damage state capable of modifying:

- wheel alignment;
- suspension stiffness and damping;
- tire grip;
- steering center;
- engine output;
- drag;
- camera shake and effects intensity.

Damage changes are clamped to validated limits. Repair restores the original definition-derived state.

## 17. Cameras

### Chase

- Vehicle-local up orientation
- Spring-smoothed position and look target
- Speed-based distance and field of view
- Collision avoidance
- Controlled lateral lag
- No horizon roll that causes discomfort during normal cornering

### Hood

- Fixed authored anchor
- Minimal smoothing
- Optional subtle vibration from telemetry

### Bumper

- Low forward anchor
- Collision-safe near plane
- No clipping through the body

### Cockpit

- Authored driver-eye anchor
- Interior visibility and steering-wheel animation
- Limited g-force and suspension movement response
- Adjustable field of view
- Optional camera stabilization

Teleport/reset calls must reset interpolation to prevent visual streaking.

## 18. Presentation hooks

The physics layer emits data for later production systems:

- engine RPM and load;
- throttle and clutch state;
- gear and shift events;
- wheel speed;
- suspension travel and velocity;
- tire slip and slip energy;
- surface type;
- impacts;
- body speed and acceleration;
- assist intervention;
- damage state.

Phase 1 may use temporary sounds and effects, but the interface must already support final engine audio, tire audio, particles, skid marks, exhaust, suspension noises, and dashboard instruments.

## 19. Vehicle Laboratory environment

The lab is one reproducible scene with independently measurable zones.

### Required zones

1. **Setup pad** — spawn, reset, static inspection, wheel alignment markers.
2. **Acceleration straight** — at least 1 km, marked speed and distance intervals.
3. **Braking lanes** — dry and wet parallel surfaces.
4. **Constant-radius skidpads** — multiple radii with center markers.
5. **Slalom** — repeatable cone spacing.
6. **Handling loop** — linked low-, medium-, and high-speed corners.
7. **Bump course** — single bumps, washboard, pothole analogue, curb strikes.
8. **Gradient ramps** — uphill, downhill, crest, and side-slope sections.
9. **Surface lanes** — dry asphalt, wet asphalt, gravel, dirt, and grass.
10. **Jump and landing section** — modest controlled airtime, not stunt-focused.
11. **Recovery zone** — rollover and stuck-state tests.
12. **Visual inspection studio** — neutral HDRI-like lighting, paint reflections, interior inspection, night lights, rain/wet preview.

The lab uses production PBR standards but simple geometry. It must load quickly and remain stable enough for automated runs.

## 20. Telemetry

### Live telemetry

Required fields include:

- world and local velocity;
- speed;
- acceleration;
- yaw, pitch, and roll rates;
- steering input and effective steering angle;
- throttle, brake, clutch, and handbrake;
- gear;
- engine RPM and torque;
- wheel RPM;
- suspension compression and velocity per wheel;
- normal load per wheel;
- slip ratio and slip angle per wheel;
- longitudinal/lateral tire force per wheel;
- grip utilization per wheel;
- surface ID and wetness;
- assist intervention;
- body contact impulses;
- frame and physics timing.

### Recording

`TelemetryRecorder` writes versioned CSV and JSON summaries under `user://telemetry/` for named test runs. Recorded runs include vehicle-definition hash and engine version so stale comparisons are rejected.

## 21. Automated tests

### Unit tests

- Suspension force sign and saturation
- Compression versus rebound damping
- Bump-stop progression
- Tire-force direction
- Grip peak and post-peak falloff
- Combined-slip friction ellipse
- Load sensitivity
- Wet and loose-surface multipliers
- Torque-curve interpolation
- Engine limiting and engine braking
- Clutch slip limits
- Gear-ratio and final-drive multiplication
- Differential torque conservation
- Brake bias
- ABS modulation
- TCS torque reduction
- Stability-control bounds
- Keyboard steering ramps
- Vehicle-definition validation

### Integration tests

- Scene and required-anchor contract
- Static ride height
- Straight-line stability
- 0–100 km/h acceleration band
- 100–0 km/h braking-distance band
- Constant-radius skidpad grip band
- Slalom completion without instability
- Wet braking distance greater than dry
- Gravel grip lower and slip broader than asphalt
- Suspension response over defined bump profiles
- Uphill launch and downhill engine braking
- Manual and automatic shift progression
- Reverse and neutral behavior
- Handbrake rear-wheel lock behavior
- Recoverable power oversteer
- No unexplained energy gain during coasting
- No persistent wheel-ground penetration
- Reset restores transform and clears motion
- Physics tick-rate comparison within approved tolerances

### Manual gates

Automated numbers cannot approve feel alone. Manual evaluation covers:

- steering confidence;
- weight sensation;
- brake modulation;
- throttle adjustability;
- progressive breakaway;
- counter-steer recovery;
- camera comfort;
- cockpit visibility;
- controller and keyboard accessibility;
- visual wheel/suspension coherence.

## 22. Performance budget

For one hero vehicle in the lab at 1080p High on target-class hardware:

- Physics calculation target: below 1.0 ms average for the player vehicle.
- Vehicle presentation scripts target: below 0.5 ms average.
- No runtime shader compilation during repeated lab laps after warm-up.
- LOD0 hero exterior and interior must follow Phase 0 asset budgets.
- Vehicle collisions use simplified convex shapes, never the render mesh.
- Tire contact queries and telemetry can be reduced or disabled for non-player vehicles later without changing the player solver.

If GDScript exceeds the budget after profiling and simplification, only the identified hot solver module is considered for native replacement.

## 23. Asset preparation pipeline

Every candidate passes these stages:

1. Record source, license, file formats, and author.
2. Preserve original source outside runtime folders.
3. Inspect dimensions, axes, object hierarchy, transforms, modifiers, UVs, materials, and textures in Blender.
4. Remove or isolate branding when the asset becomes a fictional production vehicle.
5. Separate four wheel meshes and confirm wheel-center pivots.
6. Separate body, glass, lights, interior, steering wheel, gauges, brakes, and optional doors.
7. Repair normals, nonmanifold geometry, duplicate vertices, and negative scales.
8. Consolidate materials and convert to metallic/roughness PBR.
9. Create production texture sets and atlases where appropriate.
10. Create LOD0–LOD3 and shadow meshes.
11. Create convex collision shapes and damage zones.
12. Add camera, wheel, effects, and light anchors.
13. Export deterministic GLB.
14. Register the runtime asset and validation report.
15. Test in the visual studio and vehicle lab.

No downloaded candidate is committed as the final hero vehicle merely because it imports successfully.

## 24. Failure handling

- Invalid vehicle definitions fail before scene start with actionable field names.
- A lost wheel contact produces an airborne state, not a retained last-known road force.
- NaN or infinite solver output triggers a fatal diagnostic, zeroes the affected force, and records telemetry.
- Reset uses the last validated recovery transform and clears linear/angular velocity, wheel spin, clutch state, and integrator history.
- Corrupt tuning data falls back to definition defaults without modifying the source resource.
- Missing presentation assets use explicit debug meshes while physics remains testable.
- Asset-validation failure marks the model as rejected or spike-only in the registry.

## 25. Delivery sequence

### Milestone 1 — Mathematical foundation

Pure data resources, suspension, tire, drivetrain, brake, and assist solvers with unit tests.

### Milestone 2 — Physical chassis

RigidBody chassis, wheel probes, force application, debug visualization, reset, and telemetry.

### Milestone 3 — Drivable greybox

Temporary coupe mesh, keyboard/controller driving, transmission, assists, four cameras, and core lab zones.

### Milestone 4 — Handling quality

Dry/wet/loose-surface tuning, measured test bands, stability fixes, and manual feel review.

### Milestone 5 — Hero asset

Selected model cleanup, fictionalization, materials, interior, LODs, collisions, anchors, and visual integration.

### Milestone 6 — Phase quality gate

All automated tests, telemetry baselines, Windows/Linux verification, physical-hardware performance, documentation, and approval to begin road/world foundation work.

## 26. Design conclusion

Phase 1 will use a custom modular RigidBody3D vehicle architecture on Jolt. The first car is a modest fictional RWD coupe chosen to reveal handling quality rather than conceal weaknesses. A measurable vehicle lab, strict asset pipeline, telemetry, and test suite are first-class deliverables, not cleanup work deferred until later.

## 27. Technical references

- Godot 4.7 physics documentation: https://docs.godotengine.org/en/4.7/tutorials/physics/index.html
- Godot VehicleBody3D documentation and realism warning: https://docs.godotengine.org/en/4.7/classes/class_vehiclebody3d.html
- Godot VehicleWheel3D documentation and realism warning: https://docs.godotengine.org/en/4.7/classes/class_vehiclewheel3d.html
- Godot Jolt Physics guidance: https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html
- Godot physics interpolation guidance: https://docs.godotengine.org/en/4.7/tutorials/physics/interpolation/physics_interpolation_quick_start_guide.html
