# Phase 0–1 Flight-Room Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Windows-first Godot prototype where one transformable VTOL can take off, hover, transition into forward flight, fly an ordered route, land, switch between cockpit and chase cameras, restart reliably, and pass automated headless verification.

**Architecture:** Deterministic flight math lives in pure `RefCounted` classes. A single `RigidBody3D` adapter applies forces and exposes telemetry. Input, cameras, mission flow, HUD, generated art, environment feedback, and validation remain separate modules with narrow interfaces.

**Tech Stack:** Godot 4.7.1, GDScript 2.0, Blender 5.2-compatible Python, Python 3.12, PowerShell 7, Windows 10/11.

## Global Constraints

- Target Windows PC using the Godot GL Compatibility renderer for this milestone.
- Primary controls are keyboard and mouse.
- Cockpit and chase cameras are both first-class.
- Player never leaves the craft.
- Physics runs at 120 Hz.
- Flight preserves mass, momentum, gravity, thrust direction, drag, lift approximation, and limited control authority.
- Beginner defaults must permit takeoff and route completion without reading a manual.
- No multiplayer, on-foot gameplay, progression economy, combat, open-world streaming, horror focus, or additional player vehicles in Phase 0–1.
- No third-party test add-on; the repository owns a small headless runner.
- Every task follows red → green → refactor and ends in one focused commit.

## File Map

```text
project.godot
export_presets.cfg
.github/workflows/verify.yml
assets/generated/vtol_blockout.glb
assets/generated/vtol_blockout.asset.json
assets/source/vtol_blockout.blend
scenes/craft/frontier_vtol.tscn
scenes/craft/flight_camera_rig.tscn
scenes/flight_room/flight_room.tscn
scenes/flight_room/flight_room_environment.tscn
scenes/ui/flight_hud.tscn
scripts/camera/flight_camera_rig.gd
scripts/environment/flight_room_environment.gd
scripts/flight/atmosphere_model.gd
scripts/flight/flight_force_result.gd
scripts/flight/flight_model.gd
scripts/flight/flight_parameters.gd
scripts/flight/frontier_vtol_controller.gd
scripts/flight/pilot_command.gd
scripts/game/flight_room_controller.gd
scripts/game/landing_zone.gd
scripts/game/route_gate.gd
scripts/input/pilot_input_adapter.gd
scripts/ui/flight_hud.gd
scripts/validation/asset_manifest_validator.gd
scripts/validation/project_contract_validator.gd
tests/test_runner.gd
tests/support/test_assert.gd
tests/support/test_case.gd
tests/unit/*.gd
tests/integration/*.gd
tools/blender/generate_vtol_blockout.py
tools/verify/verify.py
tools/verify/verify.ps1
```

## Stable Interfaces

```gdscript
class_name PilotCommand
extends RefCounted
var pitch := 0.0
var yaw := 0.0
var roll := 0.0
var collective := 0.0
var strafe := Vector3.ZERO
var transition := 0.0
var brake := 0.0
func sanitized() -> PilotCommand

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

class_name FlightCameraRig
extends Node3D
const MODE_COCKPIT := 0
const MODE_CHASE := 1
func bind_to_craft(craft: FrontierVtolController) -> void
func toggle_mode() -> void
func set_mode(mode: int) -> void

class_name FlightRoomController
extends Node3D
const STATE_FLYING := 0
const STATE_CRASHED := 1
const STATE_COMPLETE := 2
func restart_run() -> void
func register_gate(gate_index: int) -> void
func register_landing() -> void
```

---

### Task 1: Bootstrap the Godot Project and Test Harness

**Files:**
- Create: `.gitignore`
- Create: `.gitattributes`
- Create: `README.md`
- Create: `project.godot`
- Create: `scenes/flight_room/flight_room.tscn`
- Create: `tests/support/test_assert.gd`
- Create: `tests/support/test_case.gd`
- Create: `tests/test_runner.gd`
- Create: `tests/unit/test_project_bootstrap.gd`
- Create: `tools/verify/verify.py`
- Create: `tools/verify/verify.ps1`

**Produces:** A clean-checkout project that imports headlessly and runs repository-owned tests.

- [ ] **Step 1: Write the failing bootstrap test**

```gdscript
extends TestCase

func test_project_name() -> void:
    TestAssert.is_equal(
        ProjectSettings.get_setting("application/config/name"),
        "STRATOSPHERE: Frontier Vector"
    )

func test_physics_tick_rate() -> void:
    TestAssert.is_equal(
        ProjectSettings.get_setting("physics/common/physics_ticks_per_second"),
        120
    )
```

- [ ] **Step 2: Run verification and confirm failure**

Run:

```powershell
pwsh ./tools/verify/verify.ps1
```

Expected: failure because the verification scripts and Godot project do not exist.

- [ ] **Step 3: Implement the minimal project settings**

```ini
[application]
config/name="STRATOSPHERE: Frontier Vector"
run/main_scene="res://scenes/flight_room/flight_room.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"

[physics]
common/physics_ticks_per_second=120
common/max_physics_steps_per_frame=8

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

- [ ] **Step 4: Implement the test utilities**

```gdscript
# tests/support/test_assert.gd
class_name TestAssert
extends RefCounted

static func is_true(value: bool, message := "Expected true") -> void:
    if not value:
        push_error(message)
        assert(value, message)

static func is_equal(actual: Variant, expected: Variant, message := "") -> void:
    var resolved := message if not message.is_empty() else "Expected %s, got %s" % [expected, actual]
    assert(actual == expected, resolved)

static func is_near(actual: float, expected: float, tolerance: float, message := "") -> void:
    var resolved := message if not message.is_empty() else "Expected %f ± %f, got %f" % [expected, tolerance, actual]
    assert(absf(actual - expected) <= tolerance, resolved)
```

```gdscript
# tests/support/test_case.gd
class_name TestCase
extends RefCounted

func run() -> int:
    var count := 0
    for method in get_method_list():
        var name: String = method.name
        if name.begins_with("test_"):
            call(name)
            count += 1
    return count
```

- [ ] **Step 5: Implement the runner and verification commands**

`tests/test_runner.gd` must instantiate `TestProjectBootstrap`, print `PASS: 2 tests`, and quit with code `0`. `verify.py` must resolve Godot from `GODOT_BIN`, `godot`, `godot4`, or `C:\Tools\Godot\godot.exe`, run `--headless --editor --quit-after 2`, then run `--headless --script res://tests/test_runner.gd`. `verify.ps1` delegates to Python and returns its exit code.

- [ ] **Step 6: Create the minimal scene**

Create a `Node3D` root with one `Camera3D`, one `DirectionalLight3D`, and a `WorldEnvironment` using a generated sky color. No gameplay code yet.

- [ ] **Step 7: Run verification**

Expected: `PASS: 2 tests` and exit code `0`.

- [ ] **Step 8: Commit**

```bash
git add .
git commit -m "chore: bootstrap Godot project and verification harness"
```

---

### Task 2: Define Pilot Commands, Parameters, Atmosphere, and Pure Flight Math

**Files:**
- Create: `scripts/flight/pilot_command.gd`
- Create: `scripts/flight/flight_parameters.gd`
- Create: `scripts/flight/atmosphere_model.gd`
- Create: `scripts/flight/flight_force_result.gd`
- Create: `scripts/flight/flight_model.gd`
- Create: `tests/unit/test_pilot_command.gd`
- Create: `tests/unit/test_atmosphere_model.gd`
- Create: `tests/unit/test_flight_model.gd`
- Modify: `tests/test_runner.gd`

**Consumes:** `TestCase`, `TestAssert`.

**Produces:** Deterministic force and torque calculation independent of the scene tree.

- [ ] **Step 1: Write input-sanitization tests**

```gdscript
func test_command_is_clamped_without_mutating_source() -> void:
    var source := PilotCommand.new()
    source.pitch = 4.0
    source.collective = -2.0
    source.strafe = Vector3(3.0, 0.0, 4.0)
    var clean := source.sanitized()
    TestAssert.is_equal(clean.pitch, 1.0)
    TestAssert.is_equal(clean.collective, 0.0)
    TestAssert.is_near(clean.strafe.length(), 1.0, 0.000001)
    TestAssert.is_equal(source.pitch, 4.0)
```

- [ ] **Step 2: Write atmosphere tests**

```gdscript
func test_air_density_falls_with_altitude() -> void:
    var atmosphere := AtmosphereModel.new()
    TestAssert.is_near(atmosphere.density_at_altitude(0.0), 1.225, 0.0001)
    TestAssert.is_true(atmosphere.density_at_altitude(5000.0) < 1.225)
    TestAssert.is_equal(atmosphere.density_at_altitude(-100.0), 1.225)
```

- [ ] **Step 3: Write flight-model tests**

```gdscript
func test_drag_opposes_velocity() -> void:
    var result := FlightModel.new().calculate(
        FlightParameters.new(),
        PilotCommand.new(),
        Basis.IDENTITY,
        Vector3(0.0, 0.0, -100.0),
        Vector3.ZERO,
        1.225,
        Vector3(0.0, -9.81, 0.0)
    )
    TestAssert.is_true(result.drag_force_world.z > 0.0)

func test_transition_rotates_thrust_forward() -> void:
    var command := PilotCommand.new()
    command.collective = 1.0
    command.transition = 1.0
    var result := FlightModel.new().calculate(
        FlightParameters.new(), command, Basis.IDENTITY,
        Vector3.ZERO, Vector3.ZERO, 1.225, Vector3(0.0, -9.81, 0.0)
    )
    TestAssert.is_true(result.thrust_force_world.z < -70000.0)
```

- [ ] **Step 4: Run tests and confirm missing-class failures**

- [ ] **Step 5: Implement the value objects**

`PilotCommand.sanitized()` clamps axes to `[-1, 1]`, scalar controls to `[0, 1]`, and normalizes `strafe` only when its length exceeds one. `FlightForceResult` stores `total_force_world`, `total_torque_world`, `thrust_force_world`, `drag_force_world`, and `lift_force_world`.

- [ ] **Step 6: Implement default tuning**

```gdscript
class_name FlightParameters
extends Resource

@export var mass_kg := 4200.0
@export var hover_thrust_newtons := 56000.0
@export var forward_thrust_newtons := 72000.0
@export var lateral_thrust_newtons := 16000.0
@export var pitch_torque_nm := 180000.0
@export var yaw_torque_nm := 140000.0
@export var roll_torque_nm := 200000.0
@export var reference_area_m2 := 34.0
@export var drag_coefficient := 0.34
@export var lift_coefficient := 0.85
@export var stability_strength := 3.0
```

- [ ] **Step 7: Implement atmosphere and flight formulas**

```gdscript
func density_at_altitude(altitude_m: float) -> float:
    return 1.225 * exp(-maxf(altitude_m, 0.0) / 8500.0)
```

Flight model rules:

```text
forward = -basis.z
up = basis.y
hover thrust = up × hover_thrust × collective × (1 - transition)
forward thrust = forward × forward_thrust × collective × transition
lateral thrust = basis × strafe × lateral_thrust
drag = -velocity.normalized × 0.5 × density × speed² × Cd × reference_area
lift = up × 0.5 × density × forward_speed² × Cl × reference_area × transition
gravity = gravity_world × mass
stability torque = -angular_velocity × stability_strength × mass
```

- [ ] **Step 8: Add a 120-step repeatability test**

Integrate velocity using `dt = 1.0 / 120.0` twice and assert both runs differ by no more than `0.000001 m/s`.

- [ ] **Step 9: Run verification and commit**

```bash
git add scripts/flight tests
git commit -m "feat: add deterministic VTOL flight model"
```

---

### Task 3: Add the Physical Craft Controller and Blockout Scene

**Files:**
- Create: `scripts/flight/frontier_vtol_controller.gd`
- Create: `scenes/craft/frontier_vtol.tscn`
- Create: `tests/integration/test_frontier_vtol_controller.gd`
- Modify: `scenes/flight_room/flight_room.tscn`
- Modify: `tests/test_runner.gd`

**Consumes:** `PilotCommand`, `FlightParameters`, `AtmosphereModel`, `FlightModel`.

**Produces:** A physical craft with telemetry, crash detection, landing detection, and deterministic reset.

- [ ] **Step 1: Write controller tests**

```gdscript
func test_reset_clears_motion() -> void:
    var craft := FrontierVtolController.new()
    craft.linear_velocity = Vector3(10.0, 5.0, -2.0)
    craft.angular_velocity = Vector3.ONE
    var spawn := Transform3D(Basis.IDENTITY, Vector3(0.0, 3.0, 0.0))
    craft.reset_to(spawn)
    TestAssert.is_equal(craft.transform, spawn)
    TestAssert.is_equal(craft.linear_velocity, Vector3.ZERO)
    TestAssert.is_equal(craft.angular_velocity, Vector3.ZERO)

func test_telemetry_contract() -> void:
    var telemetry := FrontierVtolController.new().get_telemetry()
    for key in ["speed_mps", "altitude_m", "vertical_speed_mps", "collective", "transition", "is_grounded", "lift_newtons", "drag_newtons", "thrust_newtons"]:
        TestAssert.is_true(telemetry.has(key), "Missing telemetry key: " + key)
```

- [ ] **Step 2: Run tests and confirm failure**

- [ ] **Step 3: Implement the controller**

Use `RigidBody3D`, `gravity_scale = 0`, `continuous_cd = true`, `contact_monitor = true`, and `max_contacts_reported = 8`. In `_integrate_forces`, calculate altitude from global Y, obtain density, call `FlightModel.calculate`, and apply central force plus torque.

- [ ] **Step 4: Implement impact-state rules**

Emit `crashed` when a newly detected ground contact has relative speed `>= 32 m/s`. Emit `landed` after remaining grounded for `0.35 s` while total speed is `<= 6 m/s` and absolute vertical speed is `<= 3.5 m/s`.

- [ ] **Step 5: Build the craft scene**

Create an 11 m-wide primitive craft with one box-based convex collision approximation and named nodes:

```text
FrontierVtolController
├── VisualRoot
├── CollisionShape3D
├── CockpitAnchor
├── ChaseAnchor
└── ForwardMarker
```

Godot convention is `-Z` forward and `+Y` up.

- [ ] **Step 6: Add test terrain**

Add a static 400×2×500 m ground body and spawn the craft at `(0, 2.2, 0)`.

- [ ] **Step 7: Run verification, launch the scene, and commit**

```bash
git add scripts/flight scenes tests
git commit -m "feat: add physical VTOL controller and blockout craft"
```

---

### Task 4: Implement Keyboard/Mouse Input and Both Camera Modes

**Files:**
- Create: `scripts/input/pilot_input_adapter.gd`
- Create: `scripts/camera/flight_camera_rig.gd`
- Create: `scenes/craft/flight_camera_rig.tscn`
- Create: `tests/unit/test_pilot_input_adapter.gd`
- Create: `tests/unit/test_flight_camera_rig.gd`
- Modify: `scenes/flight_room/flight_room.tscn`
- Modify: `tests/test_runner.gd`

**Produces:** Playable keyboard/mouse flight, cockpit view, chase view, and camera toggle.

- [ ] **Step 1: Write input tests**

```gdscript
func test_mouse_stick_clamps() -> void:
    var adapter := PilotInputAdapter.new()
    adapter.inject_mouse_delta(Vector2(100000.0, -100000.0))
    var command := adapter.build_command(1.0 / 120.0)
    TestAssert.is_equal(absf(command.pitch), 1.0)
    TestAssert.is_equal(absf(command.yaw), 1.0)

func test_transition_clamps() -> void:
    var adapter := PilotInputAdapter.new()
    adapter.set_transition_for_test(2.0)
    TestAssert.is_equal(adapter.build_command(0.0).transition, 1.0)
```

- [ ] **Step 2: Write camera tests**

```gdscript
func test_camera_toggle_cycles() -> void:
    var rig := FlightCameraRig.new()
    TestAssert.is_equal(rig.mode, FlightCameraRig.MODE_CHASE)
    rig.toggle_mode()
    TestAssert.is_equal(rig.mode, FlightCameraRig.MODE_COCKPIT)
    rig.toggle_mode()
    TestAssert.is_equal(rig.mode, FlightCameraRig.MODE_CHASE)
```

- [ ] **Step 3: Implement input actions and virtual mouse stick**

Register actions at runtime when missing. Use sensitivity `0.0035` and recenter rate `1.35 units/s`.

Default bindings:

```text
Mouse X/Y: yaw/pitch
Q/E: roll
Space/Ctrl: collective up/down
A/D: lateral strafe
W/S: longitudinal translation assist
Z/X: transition decrease/increase
Shift: brake
C: toggle camera
F5: restart
Esc: release/capture mouse
```

- [ ] **Step 4: Implement the camera rig**

Cockpit mode copies `CockpitAnchor.global_transform`. Chase mode targets `ChaseAnchor`, uses 13 m distance, 4.2 m height, exponential position smoothing `7.0`, rotation smoothing `9.0`, craft-relative up, and FOV `78`.

- [ ] **Step 5: Wire input to craft and camera**

A small room controller may temporarily forward the command each physics frame; Task 5 replaces it with the final mission controller.

- [ ] **Step 6: Verify takeoff and landing in both views**

The craft must remain controllable with default settings and the cockpit view must not clip into primitive geometry.

- [ ] **Step 7: Commit**

```bash
git add scripts/input scripts/camera scenes/craft scenes/flight_room tests
git commit -m "feat: add keyboard mouse flight controls and cameras"
```

---

### Task 5: Build the Ordered Route, Landing Rules, Crash State, and Restart Loop

**Files:**
- Create: `scripts/game/route_gate.gd`
- Create: `scripts/game/landing_zone.gd`
- Create: `scripts/game/flight_room_controller.gd`
- Create: `tests/integration/test_flight_room_loop.gd`
- Modify: `scenes/flight_room/flight_room.tscn`
- Modify: `tests/test_runner.gd`

**Consumes:** `FrontierVtolController`, `PilotInputAdapter`, `FlightCameraRig`.

**Produces:** A complete takeoff → gates → landing → completion/restart game loop.

- [ ] **Step 1: Write route-state tests**

```gdscript
func test_out_of_order_gate_is_ignored() -> void:
    var room := FlightRoomController.new()
    room.register_gate(1)
    TestAssert.is_equal(room.next_gate_index, 0)

func test_landing_requires_all_gates() -> void:
    var room := FlightRoomController.new()
    room.register_landing()
    TestAssert.is_equal(room.state, FlightRoomController.STATE_FLYING)

func test_valid_route_completes() -> void:
    var room := FlightRoomController.new()
    room.register_gate(0)
    room.register_gate(1)
    room.register_gate(2)
    room.register_landing()
    TestAssert.is_equal(room.state, FlightRoomController.STATE_COMPLETE)
```

- [ ] **Step 2: Run tests and confirm failure**

- [ ] **Step 3: Implement ordered gates**

Place gates at:

```text
Gate 0: (0, 18, -80)
Gate 1: (55, 30, -175)
Gate 2: (-35, 16, -270)
```

Only the expected gate accepts the craft. Completed gates dim; the next gate remains emissive.

- [ ] **Step 4: Implement landing-zone acceptance**

Landing pad center is `(0, 0.2, -340)` with a 30×5×30 m trigger. Completion requires all gates, grounded state, total speed `<= 8 m/s`, and absolute vertical speed `<= 3.5 m/s`.

- [ ] **Step 5: Implement room states and restart**

Capture spawn transform on `_ready`. `restart_run()` resets craft transform and velocities, gate progress, gate visuals, landing-zone state, timers, and room state. Crash state disables pilot commands except restart.

- [ ] **Step 6: Wire signals**

Connect input camera/restart signals, craft crash/land signals, gate entry signals, and landing-zone entry signal.

- [ ] **Step 7: Verify negative cases**

Landing outside the pad, skipping a gate, or hitting the ground above the crash threshold must not complete the run.

- [ ] **Step 8: Commit**

```bash
git add scripts/game scenes/flight_room tests
git commit -m "feat: add flight room route landing and restart loop"
```

---

### Task 6: Add HUD, Environment, Engine Feedback, and Original Blender Blockout

**Files:**
- Create: `scripts/ui/flight_hud.gd`
- Create: `scenes/ui/flight_hud.tscn`
- Create: `scripts/environment/flight_room_environment.gd`
- Create: `scenes/flight_room/flight_room_environment.tscn`
- Create: `scripts/flight/flight_feedback.gd`
- Create: `tools/blender/generate_vtol_blockout.py`
- Create: `assets/generated/vtol_blockout.asset.json`
- Create: `scripts/validation/asset_manifest_validator.gd`
- Create: `tests/unit/test_flight_hud.gd`
- Create: `tests/unit/test_flight_feedback.gd`
- Create: `tests/unit/test_asset_manifest_validator.gd`
- Modify: `scenes/craft/frontier_vtol.tscn`
- Modify: `scenes/flight_room/flight_room.tscn`
- Modify: `tests/test_runner.gd`

**Produces:** Readable telemetry, visual speed reference, generated audio, exhaust response, and an original reproducible craft model.

- [ ] **Step 1: Write HUD formatting tests**

```gdscript
func test_speed_format() -> void:
    TestAssert.is_equal(FlightHud.format_speed(10.0), "036 km/h")

func test_vertical_speed_format() -> void:
    TestAssert.is_equal(FlightHud.format_vertical_speed(2.5), "+2.5 m/s")

func test_transition_format() -> void:
    TestAssert.is_equal(FlightHud.format_transition(0.425), "42%")
```

- [ ] **Step 2: Write feedback tests**

```gdscript
func test_engine_intensity() -> void:
    TestAssert.is_near(FlightFeedback.engine_intensity(0.7, 0.5), 0.8, 0.000001)

func test_wind_intensity() -> void:
    TestAssert.is_near(FlightFeedback.wind_intensity(90.0), 0.5, 0.000001)
```

- [ ] **Step 3: Create the HUD**

Show speed, altitude, vertical speed, collective, transition, gate progress, current camera, and a centered state banner. `CRASHED — F5 TO RESTART` and `ROUTE COMPLETE — F5 TO FLY AGAIN` are the only blocking messages.

- [ ] **Step 4: Create the environment**

Build a 500×900 m ground strip, route pylons, six large silhouette landmarks, runway edge lights, a blue-gray sky, one directional light, and fog density `0.0018`. All geometry is primitive or procedurally generated in-engine.

- [ ] **Step 5: Create generated sound and exhaust response**

Use `AudioStreamGenerator` for a layered 55–145 Hz engine tone. Use deterministic linear-congruential noise for wind. Exhaust mesh length scales from `0.15` to `2.6` based on `clamp(collective + transition * 0.2, 0, 1)`.

- [ ] **Step 6: Create and validate the asset manifest**

```json
{
  "asset_id": "frontier_vtol_blockout_v1",
  "license": "Project original",
  "units": "meters",
  "forward_axis": "-Z",
  "up_axis": "+Y",
  "dimensions_m": [11.0, 2.6, 8.0],
  "required_nodes": [
    "VTOL_Root", "Body", "Wing", "CockpitShell",
    "Engine_Left", "Engine_Right", "CockpitAnchor",
    "ChaseAnchor", "ForwardMarker"
  ],
  "generator": "tools/blender/generate_vtol_blockout.py"
}
```

- [ ] **Step 7: Implement the Blender generator**

Use only deterministic beveled boxes and cylinders, one graphite metallic material, identity root transform, named empties, and explicit metric dimensions. Save `assets/source/vtol_blockout.blend`; export `assets/generated/vtol_blockout.glb`.

Run:

```powershell
blender --background --python ./tools/blender/generate_vtol_blockout.py
```

- [ ] **Step 8: Replace primitive visuals without replacing gameplay anchors**

Godot `Marker3D` nodes remain authoritative. Imported asset nodes are visual only; collisions remain owned by `frontier_vtol.tscn`.

- [ ] **Step 9: Inspect six views and both cameras**

Reject wrong scale, orientation, cockpit position, silhouette, clipping, or unreadable exhaust placement.

- [ ] **Step 10: Commit**

```bash
git add assets scenes scripts tools tests
git commit -m "feat: add presentation layer and generated VTOL blockout"
```

---

### Task 7: Add Contract Validation, Windows Export, and CI

**Files:**
- Create: `scripts/validation/project_contract_validator.gd`
- Create: `tests/unit/test_project_contract_validator.gd`
- Create: `export_presets.cfg`
- Create: `.github/workflows/verify.yml`
- Modify: `tools/verify/verify.py`
- Modify: `README.md`
- Modify: `tests/test_runner.gd`

**Produces:** Reproducible validation and Windows export baseline.

- [ ] **Step 1: Write repository-contract tests**

```gdscript
func test_required_phase_one_paths_exist() -> void:
    for path in ProjectContractValidator.required_paths():
        TestAssert.is_true(FileAccess.file_exists(path), "Missing: " + path)

func test_main_scene_and_tick_rate_are_locked() -> void:
    TestAssert.is_equal(
        ProjectSettings.get_setting("application/run/main_scene"),
        "res://scenes/flight_room/flight_room.tscn"
    )
    TestAssert.is_equal(
        ProjectSettings.get_setting("physics/common/physics_ticks_per_second"),
        120
    )
```

- [ ] **Step 2: Add Windows export preset**

Target `build/windows/STRATOSPHERE.exe`, embed the PCK, use 64-bit architecture, and do not require signing for development builds.

- [ ] **Step 3: Add CI**

The workflow must check out the repo, install Godot 4.7.1, and run:

```bash
python tools/verify/verify.py
```

It must not upload builds or consume Actions minutes on Blender generation.

- [ ] **Step 4: Extend verification**

After Godot tests, verify all contract paths, check that no generated file exceeds 100 MB, and print an actionable failure list.

- [ ] **Step 5: Document local commands and controls**

README must contain setup, play, verification, Blender generation, matching Godot export-template requirement, Windows export, controls, project boundaries, and current milestone status.

- [ ] **Step 6: Run final automated gate**

```powershell
pwsh ./tools/verify/verify.ps1
```

Expected: all tests pass, project imports cleanly, and no contract path is missing.

- [ ] **Step 7: Run final manual gate**

From a clean launch: take off, pass all three gates, switch camera twice, land, observe completion, restart, crash deliberately, and restart again. No input lock, stale gate state, camera desynchronization, or physics explosion is acceptable.

- [ ] **Step 8: Export Windows build**

```powershell
godot --headless --path . --export-release "Windows Desktop" build/windows/STRATOSPHERE.exe
```

- [ ] **Step 9: Commit**

```bash
git add .github export_presets.cfg scripts/validation tests tools README.md
git commit -m "chore: lock Phase 1 verification and Windows export"
```

## Definition of Done

Phase 0–1 is complete only when all of the following are true:

- A clean checkout imports in Godot 4.7.1.
- `pwsh ./tools/verify/verify.ps1` exits `0`.
- The craft takes off, hovers, transitions, flies the route, and lands.
- Both cockpit and chase views are usable throughout the route.
- Crash, completion, and restart states are reliable.
- HUD and feedback communicate speed, altitude, vertical speed, thrust, transition, route state, and failure state.
- The VTOL visual is reproducibly generated through Blender and validated by manifest.
- The repository has a working Windows export preset and CI verification.
- No system outside the approved milestone has been added.
