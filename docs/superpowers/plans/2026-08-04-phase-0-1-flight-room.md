# Phase 0–1 Flight-Room Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this plan task by task. Every task is test-first and ends in a focused commit.

**Goal:** Produce a Windows-first playable Godot prototype in which one blockout transformable VTOL can take off, hover, transition into forward flight, complete a short route, land, switch between cockpit and chase cameras, crash, and restart reliably.

**Architecture:** Keep flight mathematics in deterministic `RefCounted` classes. Apply their output through one `RigidBody3D` controller using `custom_integrator = true`, so gravity and drag are never applied twice. Keep input, camera, HUD, route state, feedback, generated art, validation, and export tooling isolated behind narrow interfaces.

**Tech stack:** Godot 4.6.3 stable, GDScript 2.0, Blender 5.2-compatible Python, Python 3.12, and PowerShell 7.

## Global constraints

- Windows PC is the primary target.
- Keyboard and mouse are the primary input.
- Cockpit and chase cameras are both first-class.
- The player never leaves the craft.
- Flight must preserve momentum, mass, thrust direction, gravity, aerodynamic drag, and limited control authority.
- Beginner assistance may stabilize the craft but may not secretly replace the physical simulation.
- Phase 0–1 contains one craft, one route, one test region, and one landing zone.
- No multiplayer, on-foot mode, open-world streaming, economy, combat campaign, or final art in this milestone.
- No third-party Godot testing add-on; the repository owns a small headless runner.
- Do not upgrade the engine baseline during this milestone.

## Stable interfaces

```gdscript
class_name PilotCommand
extends RefCounted
var pitch: float
var yaw: float
var roll: float
var collective: float
var strafe: Vector3
var transition: float
var brake: float
func sanitized() -> PilotCommand

class_name FlightParameters
extends Resource
@export var mass_kg: float
@export var hover_thrust_newtons: float
@export var forward_thrust_newtons: float
@export var lateral_thrust_newtons: float
@export var pitch_torque_newton_meters: float
@export var yaw_torque_newton_meters: float
@export var roll_torque_newton_meters: float
@export var reference_area_m2: float
@export var drag_coefficient: float
@export var lift_coefficient: float
@export var max_forward_speed_mps: float
@export var stability_strength: float

class_name FlightForceResult
extends RefCounted
var force_world: Vector3
var torque_world: Vector3
var lift_newtons: float
var drag_newtons: float
var thrust_newtons: float

class_name FlightModel
extends RefCounted
func calculate(
    parameters: FlightParameters,
    command: PilotCommand,
    basis: Basis,
    linear_velocity_world: Vector3,
    angular_velocity_world: Vector3,
    air_density_kg_m3: float,
    gravity_world: Vector3
) -> FlightForceResult

class_name FrontierVtolController
extends RigidBody3D
signal telemetry_updated(telemetry: Dictionary)
signal crashed()
signal landed()
func set_pilot_command(command: PilotCommand) -> void
func reset_to(transform_value: Transform3D) -> void
func get_telemetry() -> Dictionary
```

---

### Task 1: Bootstrap a green Godot repository

**Create:** `.gitignore`, `.gitattributes`, `README.md`, `project.godot`, `scenes/flight_room/flight_room.tscn`, `tests/support/test_assert.gd`, `tests/support/test_case.gd`, `tests/test_runner.gd`, `tests/unit/test_project_bootstrap.gd`, `tools/verify/verify.py`, `tools/verify/verify.ps1`.

- [ ] Write bootstrap tests asserting project name and a 120 Hz physics tick rate.
- [ ] Create a minimal valid `Node3D` main scene with a current camera and directional light.
- [ ] Create a `SceneTree` test runner that preloads suites, runs methods beginning with `test_`, prints the count, and exits nonzero on assertion failure.
- [ ] Make `verify.py` locate Godot from `GODOT_BIN`, PATH, or `C:\Tools\Godot\godot.exe`; import the project; then run the test runner.
- [ ] Run `pwsh ./tools/verify/verify.ps1`.

**Expected:** import succeeds and `PASS: 2 tests` is printed.

**Commit:** `chore: bootstrap Godot project and verification harness`

---

### Task 2: Add deterministic timing

**Create:** `scripts/core/simulation_clock.gd`, `tests/unit/test_simulation_clock.gd`.

```gdscript
class_name SimulationClock
extends RefCounted
func _init(ticks_per_second: float) -> void
func advance(real_delta: float) -> int
func get_alpha() -> float
```

- [ ] Test that one 60 Hz frame yields two 120 Hz ticks.
- [ ] Test that partial time remains buffered.
- [ ] Test that negative delta produces zero ticks.
- [ ] Implement an accumulator with a 0.25-second frame clamp.
- [ ] Run the full verification suite.

**Commit:** `feat: add deterministic simulation clock`

---

### Task 3: Define pilot command and parameter contracts

**Create:** `scripts/flight/pilot_command.gd`, `scripts/flight/flight_parameters.gd`, `tests/unit/test_pilot_command.gd`.

- [ ] Test axis clamping, normalized strafe input, zero-to-one collective/transition/brake, and non-mutating sanitization.
- [ ] Implement `PilotCommand.sanitized()`.
- [ ] Define validated defaults for a 4,200 kg craft, hover/forward/lateral thrust, control torques, reference area, drag, lift, speed, and stabilization.
- [ ] Run verification.

**Commit:** `feat: define pilot commands and flight parameters`

---

### Task 4: Implement pure atmosphere and flight-force calculations

**Create:** `scripts/flight/atmosphere_model.gd`, `scripts/flight/flight_force_result.gd`, `scripts/flight/flight_model.gd`, `tests/unit/test_atmosphere_model.gd`, `tests/unit/test_flight_model.gd`.

- [ ] Test sea-level density near `1.225 kg/m³`, monotonic density reduction with altitude, and negative-altitude clamping.
- [ ] Test that full hover thrust exceeds weight.
- [ ] Test that transition continuously rotates thrust from local up toward local forward.
- [ ] Test that drag opposes world velocity.
- [ ] Test that pure rotation commands produce torque without changing linear momentum directly.
- [ ] Implement exponential atmosphere sampling.
- [ ] Implement gravity, thrust, quadratic drag, transition-dependent lift, command torque, and angular stabilization.
- [ ] Keep this layer free of scene-tree or input dependencies.

**Commit:** `feat: add deterministic atmosphere and flight force model`

---

### Task 5: Build the physical craft controller and scene

**Create:** `scripts/flight/frontier_vtol_controller.gd`, `scenes/craft/frontier_vtol.tscn`, `tests/integration/test_frontier_vtol_controller.gd`.

- [ ] Test required telemetry keys: speed, altitude, transition, collective, vertical speed, grounded state, lift, drag, and thrust.
- [ ] Test that reset restores an exact transform and clears linear/angular velocity.
- [ ] Set `custom_integrator = true`, mass from `FlightParameters`, contact monitoring, continuous collision detection, and bounded contact count.
- [ ] In `_integrate_forces`, sample density and apply the exact force/torque returned by `FlightModel`.
- [ ] Distinguish a soft landing from a crash using configurable impact thresholds.
- [ ] Build a primitive collision hull and visual blockout with `CockpitAnchor`, `ChaseAnchor`, and `ForwardMarker` using `-Z` as forward and `+Y` as up.
- [ ] Instance the craft into the flight room above a static ground plane.

**Commit:** `feat: add physical VTOL controller and blockout craft`

---

### Task 6: Add keyboard-and-mouse input

**Create:** `scripts/input/pilot_input_adapter.gd`, `tests/unit/test_pilot_input_adapter.gd`.

- [ ] Test injected mouse delta conversion to bounded pitch/yaw.
- [ ] Test transition accumulation and clamping.
- [ ] Create input actions at runtime with `InputMap` if missing; never rely on brittle handwritten serialized `Object(InputEventKey, ...)` entries.
- [ ] Bind mouse to pitch/yaw; Q/E to roll; Space/Ctrl to collective; Z/X to transition; F/H and R/V to translation; Shift to brake; C to camera; F5 to restart; Escape to release the mouse.
- [ ] Emit camera-toggle and restart signals.
- [ ] Instance the adapter into the flight room.

**Commit:** `feat: add keyboard and mouse flight input`

---

### Task 7: Add cockpit and chase camera systems

**Create:** `scripts/camera/flight_camera_rig.gd`, `scenes/craft/flight_camera_rig.tscn`, `tests/unit/test_flight_camera_rig.gd`.

- [ ] Define stable modes `MODE_COCKPIT = 0` and `MODE_CHASE = 1`.
- [ ] Test toggle order and invalid-mode rejection.
- [ ] Bind to the craft anchors.
- [ ] Make cockpit mode follow the cockpit anchor exactly.
- [ ] Make chase mode smooth position and orientation while preserving craft-local up.
- [ ] Give the chase camera a 78° field of view and collision-safe near plane.
- [ ] Remove the bootstrap debug camera.

**Commit:** `feat: add cockpit and chase camera modes`

---

### Task 8: Add the complete route, landing, crash, and restart loop

**Create:** `scripts/game/route_gate.gd`, `scripts/game/flight_room_controller.gd`, `tools/godot/build_flight_room_route.gd`, `tests/integration/test_flight_room_loop.gd`.

- [ ] Test that route gates only advance in order.
- [ ] Test that landing completes only after all gates.
- [ ] Test that restart clears route state and returns to `STATE_FLYING`.
- [ ] Connect input, craft, camera, gate, crash, and landing signals in `FlightRoomController`.
- [ ] Capture the spawn transform once and restore it on restart.
- [ ] Author three deterministic gates at `(0,18,-80)`, `(55,30,-175)`, and `(-35,16,-270)`.
- [ ] Author a landing pad centered at `(0,0.25,-340)`.
- [ ] Build the scene nodes through an editor script so ownership, groups, dimensions, and positions are reproducible.
- [ ] Manually verify takeoff, ordered gates, soft landing, crash, and F5 restart.

**Commit:** `feat: add takeoff route landing and restart loop`

---

### Task 9: Add a readable flight HUD

**Create:** `scripts/ui/flight_hud.gd`, `scenes/ui/flight_hud.tscn`, `tests/unit/test_flight_hud.gd`.

- [ ] Test speed formatting in km/h, signed vertical speed, and integer percentages.
- [ ] Display speed, altitude, vertical speed, collective, vector transition, route progress, crash state, and completion state.
- [ ] Wire craft telemetry and flight-room signals to HUD handlers.
- [ ] Verify readability at 1280×720 and 1600×900 in both camera modes.

**Commit:** `feat: add flight telemetry HUD`

---

### Task 10: Generate the first Blender VTOL blockout

**Create:** `tools/blender/generate_vtol_blockout.py`, `assets/generated/vtol_blockout.asset.json`, `scripts/validation/asset_manifest_validator.gd`, `tests/unit/test_asset_manifest_validator.gd`.

**Generate:** `assets/source/vtol_blockout.blend`, `assets/generated/vtol_blockout.glb`.

- [ ] Define an asset manifest with meter units, `-Z` forward, `+Y` up, dimensions, license, generator path, and required node names.
- [ ] Test manifest structure and required anchors.
- [ ] Script a body, wing, cockpit shell, left/right engine pods, and anchor empties in Blender.
- [ ] Save the source `.blend` and export `.glb` deterministically.
- [ ] Replace primitive visual meshes while retaining the tested collision hull.
- [ ] Inspect front, rear, left, right, top, and cockpit views before accepting the asset.

**Commit:** `feat: generate and validate VTOL blockout asset`

---

### Task 11: Add environment and flight feedback

**Create:** `scenes/flight_room/flight_room_environment.tscn`, `scripts/flight/flight_feedback.gd`, `tests/unit/test_flight_feedback.gd`.

- [ ] Test deterministic engine and wind intensity mappings.
- [ ] Add a 400×800 meter test strip, runway lights, route pylons, fog, sun, and six large parallax landmarks.
- [ ] Generate engine hum and wind through `AudioStreamGenerator`; do not add downloaded copyrighted audio.
- [ ] Add two exhaust visuals scaled by engine intensity.
- [ ] Verify speed is readable without the HUD, gates remain visible, and neither camera intersects normal geometry.

**Commit:** `feat: add flight environment audio and visual feedback`

---

### Task 12: Add contract validation, CI, and Windows export

**Create:** `scripts/validation/project_contract_validator.gd`, `tests/unit/test_project_contract_validator.gd`, `.github/workflows/verify.yml`, `export_presets.cfg`.

**Modify:** `tools/verify/verify.py`, `README.md`.

- [ ] Validate every required Phase 0–1 path, main scene, and 120 Hz setting.
- [ ] Extend Python verification with repository path checks.
- [ ] Add a Windows Desktop export preset producing `build/windows/STRATOSPHERE.exe`.
- [ ] Add a GitHub Actions job that downloads Godot 4.6.3 stable and runs import plus tests without uploading build artifacts.
- [ ] Document verification, play, Blender generation, controls, and Windows export.
- [ ] Run local verification from a clean checkout.
- [ ] Export and launch the Windows executable.

**Commit:** `chore: add Phase 1 verification and Windows export baseline`

---

## Phase 0–1 acceptance gate

The milestone is complete only when all statements are true:

1. A new player can take off and understand the basic HUD without external documentation.
2. Hover preserves inertia and never snaps velocity to camera direction.
3. Rotating without translational thrust does not erase linear velocity.
4. Transition continuously reallocates thrust rather than teleporting between modes.
5. Mouse pitch/yaw, Q/E roll, collective, camera toggle, and restart are reliable.
6. Both cameras can complete the route.
7. Crashes and soft landings are distinguishable.
8. Restart restores transform, velocities, gates, and state.
9. Headless tests pass from a clean checkout.
10. The Windows export launches without editor-only dependencies.

## Deliberately deferred

Open-world streaming, economy, progression, combat, dynamic weather, final vehicle art, orbital flight, moons, campaign content, and advanced damage belong to later independent specifications and plans.