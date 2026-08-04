# STRATOSPHERE Control Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace abrupt raw-torque mouse handling with a deterministic angular-rate controller and improve chase-camera comfort, control feedback, collective handling, and transition response without adding autopilot or weakening the simulation.

**Architecture:** A shared `FlightControlProfile` resource becomes the single source of tuning for input, angular-rate physics, and chase-camera response. `PilotInputAdapter` emits smoothed normalized rate demand; `FlightModel` converts that demand and actual local angular velocity into bounded torque; the camera and HUD consume state without modifying physics.

**Tech Stack:** Godot 4.6.3 stable, GDScript, Godot `Resource` tuning assets, `RigidBody3D` custom integration, the repository's existing headless test framework, Python 3.12 verifier, Windows export through Godot.

## Global Constraints

- Base implementation branch: `agent/phase-0-1-flight-room` at `6dea1a4f60b522b365732a5ca5045c28cce9b3b4`.
- Approved design: `docs/superpowers/specs/2026-08-04-control-polish-design.md` on `design/control-polish`.
- Work in a local isolated worktree created from the base implementation branch.
- Do not push, open a pull request, modify GitHub settings, or trigger GitHub Actions.
- Local recovery commits are allowed; squash the complete milestone into one final local commit before handoff.
- Do not touch Blender assets, generated GLB files, asset workflows, combat, progression, world content, or the route layout.
- Preserve Godot 4.6.3 and the 120 Hz physics baseline.
- Preserve `PilotCommand.pitch`, `yaw`, and `roll` as normalized `[-1, 1]` values; reinterpret them as angular-rate demand rather than raw torque percentage.
- Do not implement auto-level, attitude hold, altitude hold, autopilot, gamepad support, HOTAS support, or a control-rebinding UI.
- Rotational demand must not directly alter linear force or erase linear velocity.
- All production behavior changes follow test-first red-green-refactor development.
- Run local verification after every task; run the full clean verifier and Windows export only after the whole batch is complete.

---

## File Map

### Create

- `scripts/flight/flight_control_profile.gd` — sanitized shared control and camera tuning resource.
- `resources/flight/default_flight_control_profile.tres` — canonical keyboard-and-mouse defaults.
- `tests/unit/test_flight_control_profile.gd` — profile clamping, shaping, and mode-blending tests.

### Modify

- `scripts/input/pilot_input_adapter.gd` — physics-rate-independent mouse velocity, response shaping, smoothing, roll ramp, collective detent, and transition target/follower.
- `scripts/flight/flight_model.gd` — local angular-rate error controller and bounded torque.
- `scripts/flight/frontier_vtol_controller.gd` — shared profile ownership, fallback, reset, telemetry, and updated model call.
- `scripts/camera/flight_camera_rig.gd` — independent position/rotation response, bounded velocity look-ahead, roll attenuation, and dynamic FOV.
- `scripts/game/flight_room_controller.gd` — route camera-toggle handling through the room controller and forward smoothed demand to the HUD.
- `scripts/ui/flight_hud.gd` — bounded control-demand cue API.
- `scenes/craft/frontier_vtol.tscn` — assign the canonical profile to the physical craft.
- `scenes/craft/flight_camera_rig.tscn` — assign the canonical profile to the camera rig.
- `scenes/flight_room/flight_room.tscn` — assign the canonical profile to the input adapter.
- `scenes/ui/flight_hud.tscn` — replace the crosshair-like centre label with a restrained demand cue.
- `tests/unit/test_pilot_input_adapter.gd` — rate independence, shaping, smoothing, detent, transition, and reset tests.
- `tests/unit/test_flight_model.gd` — rate-controller direction, limits, continuity, finite safety, and linear-force independence.
- `tests/integration/test_frontier_vtol_controller.gd` — shared-profile wiring, deterministic reset, and telemetry contract.
- `tests/unit/test_flight_camera_rig.gd` — independent follow response, FOV, look-ahead, roll attenuation, and cockpit rigidity.
- `tests/unit/test_flight_hud.gd` — demand clamping and marker placement.
- `tests/integration/test_flight_room_loop.gd` — command neutralization, camera-mode HUD state, and restart cleanup.
- `tests/test_runner.gd` — register `TestFlightControlProfile`.
- `scripts/validation/project_contract_validator.gd` — require the profile script and default resource.
- `tools/verify/verify.py` — require the profile script and default resource in the clean-checkout contract.
- `README.md` — document the new control behavior and final accepted tuning values.

---

### Task 1: Shared Flight-Control Profile

**Files:**
- Create: `scripts/flight/flight_control_profile.gd`
- Create: `resources/flight/default_flight_control_profile.tres`
- Create: `tests/unit/test_flight_control_profile.gd`
- Modify: `tests/test_runner.gd`

**Interfaces:**
- Produces: `FlightControlProfile`.
- Produces: `func shaped_axis(value: float) -> float`.
- Produces: `func blended_max_rate_radians(transition: float) -> Vector3` where components are pitch, yaw, roll.
- Produces: `func safe_rate_gain() -> Vector3`.
- Produces: `func safe_max_torque() -> Vector3`.
- Produces resource: `res://resources/flight/default_flight_control_profile.tres`.

- [ ] **Step 1: Register a failing profile test suite**

Add this preload to `tests/test_runner.gd` immediately after `test_pilot_command.gd`:

```gdscript
preload("res://tests/unit/test_flight_control_profile.gd"),
```

Create `tests/unit/test_flight_control_profile.gd`:

```gdscript
class_name TestFlightControlProfile
extends TestCase


func test_response_curve_is_signed_monotonic_and_bounded() -> void:
	var profile := FlightControlProfile.new()
	profile.mouse_response_exponent = 1.4

	var small := profile.shaped_axis(0.25)
	var large := profile.shaped_axis(0.75)

	TestAssert.is_true(small > 0.0)
	TestAssert.is_true(large > small)
	TestAssert.is_near(profile.shaped_axis(-0.75), -large, 0.000001)
	TestAssert.is_equal(profile.shaped_axis(2.0), 1.0)


func test_rate_limits_blend_continuously_between_modes() -> void:
	var profile := FlightControlProfile.new()
	profile.hover_max_rate_degrees = Vector3(60.0, 50.0, 70.0)
	profile.forward_max_rate_degrees = Vector3(100.0, 30.0, 130.0)

	var hover := profile.blended_max_rate_radians(0.0)
	var middle := profile.blended_max_rate_radians(0.5)
	var forward := profile.blended_max_rate_radians(1.0)

	TestAssert.is_near(hover.x, deg_to_rad(60.0), 0.000001)
	TestAssert.is_near(middle.x, deg_to_rad(80.0), 0.000001)
	TestAssert.is_near(forward.y, deg_to_rad(30.0), 0.000001)
	TestAssert.is_true(middle.z > hover.z)
	TestAssert.is_true(middle.z < forward.z)


func test_invalid_tuning_is_sanitized() -> void:
	var profile := FlightControlProfile.new()
	profile.rate_gain_newton_meters_per_rad_s = Vector3(-1.0, INF, 100.0)
	profile.max_torque_newton_meters = Vector3(-50.0, 200.0, NAN)

	var gain := profile.safe_rate_gain()
	var limit := profile.safe_max_torque()

	TestAssert.is_true(gain.x >= 0.0)
	TestAssert.is_true(is_finite(gain.y))
	TestAssert.is_true(limit.x >= 0.0)
	TestAssert.is_true(is_finite(limit.z))


func test_default_resource_loads() -> void:
	var profile := load(
		"res://resources/flight/default_flight_control_profile.tres"
	) as FlightControlProfile

	TestAssert.is_true(profile != null)
	TestAssert.is_true(profile.full_pitch_mouse_speed_px_s > 0.0)
	TestAssert.is_true(profile.max_chase_fov_degrees >= profile.min_chase_fov_degrees)
```

- [ ] **Step 2: Run the suite and verify RED**

Run:

```powershell
python tools/verify/verify.py
```

Expected: failure because `FlightControlProfile` and the `.tres` resource do not exist.

- [ ] **Step 3: Implement the profile**

Create `scripts/flight/flight_control_profile.gd` with these exact fields and methods:

```gdscript
class_name FlightControlProfile
extends Resource

@export_range(100.0, 4000.0, 1.0) var full_pitch_mouse_speed_px_s: float = 950.0
@export_range(100.0, 4000.0, 1.0) var full_yaw_mouse_speed_px_s: float = 1050.0
@export var invert_pitch: bool = false
@export var invert_yaw: bool = false
@export_range(0.25, 3.0, 0.05) var mouse_response_exponent: float = 1.35
@export_range(0.1, 40.0, 0.1) var pitch_attack_response: float = 11.0
@export_range(0.1, 40.0, 0.1) var pitch_release_response: float = 7.5
@export_range(0.1, 40.0, 0.1) var yaw_attack_response: float = 10.0
@export_range(0.1, 40.0, 0.1) var yaw_release_response: float = 7.0
@export_range(0.1, 40.0, 0.1) var roll_attack_response: float = 6.5
@export_range(0.1, 40.0, 0.1) var roll_release_response: float = 8.0

@export var hover_max_rate_degrees := Vector3(65.0, 52.0, 78.0)
@export var forward_max_rate_degrees := Vector3(95.0, 28.0, 125.0)
@export var rate_gain_newton_meters_per_rad_s := Vector3(210000.0, 160000.0, 240000.0)
@export var max_torque_newton_meters := Vector3(220000.0, 180000.0, 260000.0)

@export_range(0.0, 1.0, 0.001) var nominal_hover_collective: float = 0.74
@export_range(0.0, 0.2, 0.001) var hover_detent_window: float = 0.035
@export_range(0.0, 2.0, 0.01) var hover_detent_pull_per_second: float = 0.18
@export_range(0.0, 2.0, 0.01) var collective_rate_per_second: float = 0.48
@export_range(0.0, 2.0, 0.01) var transition_input_rate_per_second: float = 0.55
@export_range(0.1, 40.0, 0.1) var transition_follow_response: float = 10.0

@export_range(0.1, 40.0, 0.1) var chase_position_response: float = 7.0
@export_range(0.1, 40.0, 0.1) var chase_rotation_response: float = 9.0
@export_range(0.0, 1.0, 0.01) var chase_roll_follow_amount: float = 0.38
@export_range(0.0, 2.0, 0.01) var chase_lookahead_seconds: float = 0.28
@export_range(0.0, 80.0, 0.1) var chase_max_lookahead_meters: float = 28.0
@export_range(50.0, 120.0, 0.1) var min_chase_fov_degrees: float = 76.0
@export_range(50.0, 120.0, 0.1) var max_chase_fov_degrees: float = 92.0
@export_range(1.0, 500.0, 1.0) var chase_fov_full_speed_mps: float = 210.0
@export_range(0.1, 40.0, 0.1) var chase_fov_response: float = 5.0


func shaped_axis(value: float) -> float:
	var bounded := clampf(_finite_or(value, 0.0), -1.0, 1.0)
	var exponent := clampf(_finite_or(mouse_response_exponent, 1.0), 0.25, 3.0)
	return signf(bounded) * pow(absf(bounded), exponent)


func blended_max_rate_radians(transition: float) -> Vector3:
	var weight := clampf(_finite_or(transition, 0.0), 0.0, 1.0)
	var hover := _safe_positive_vector(hover_max_rate_degrees, Vector3(65.0, 52.0, 78.0))
	var forward := _safe_positive_vector(forward_max_rate_degrees, Vector3(95.0, 28.0, 125.0))
	var degrees := hover.lerp(forward, weight)
	return Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z))


func safe_rate_gain() -> Vector3:
	return _safe_positive_vector(
		rate_gain_newton_meters_per_rad_s,
		Vector3(210000.0, 160000.0, 240000.0)
	)


func safe_max_torque() -> Vector3:
	return _safe_positive_vector(
		max_torque_newton_meters,
		Vector3(220000.0, 180000.0, 260000.0)
	)


func _safe_positive_vector(value: Vector3, fallback: Vector3) -> Vector3:
	return Vector3(
		maxf(_finite_or(value.x, fallback.x), 0.0),
		maxf(_finite_or(value.y, fallback.y), 0.0),
		maxf(_finite_or(value.z, fallback.z), 0.0)
	)


func _finite_or(value: float, fallback: float) -> float:
	return value if is_finite(value) else fallback
```

Create `resources/flight/default_flight_control_profile.tres` and assign the script without overriding the defaults:

```text
[gd_resource type="Resource" script_class="FlightControlProfile" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/flight/flight_control_profile.gd" id="1_profile"]

[resource]
script = ExtResource("1_profile")
```

- [ ] **Step 4: Run the suite and verify GREEN**

Run:

```powershell
python tools/verify/verify.py
```

Expected: all existing tests plus the four new profile tests pass.

- [ ] **Step 5: Create a local recovery commit**

```bash
git add scripts/flight/flight_control_profile.gd resources/flight/default_flight_control_profile.tres tests/unit/test_flight_control_profile.gd tests/test_runner.gd
git commit -m "feat: add shared flight control profile"
```

Do not push.

---

### Task 2: Physics-Rate-Independent Pilot Input

**Files:**
- Modify: `scripts/input/pilot_input_adapter.gd`
- Modify: `tests/unit/test_pilot_input_adapter.gd`

**Interfaces:**
- Consumes: `FlightControlProfile`.
- Preserves: `func compose_command(mouse_delta: Vector2, action_strengths: Dictionary, delta: float) -> PilotCommand`.
- Preserves: `func reset_controls() -> void`.
- Produces: `func get_smoothed_control_demand() -> Vector2`, returning `(yaw, pitch)` in normalized display coordinates.

- [ ] **Step 1: Add failing rate-independence and smoothing tests**

Append these tests to `tests/unit/test_pilot_input_adapter.gd`:

```gdscript
func test_equivalent_mouse_velocity_matches_at_60_and_120_hz() -> void:
	var profile := FlightControlProfile.new()
	profile.mouse_response_exponent = 1.0
	profile.pitch_attack_response = 1000.0
	profile.yaw_attack_response = 1000.0
	var sixty := PilotInputAdapter.new()
	var one_twenty := PilotInputAdapter.new()
	sixty.control_profile = profile
	one_twenty.control_profile = profile

	var command_60 := sixty.compose_command(Vector2(10.0, -10.0), {}, 1.0 / 60.0)
	var command_120 := one_twenty.compose_command(Vector2(5.0, -5.0), {}, 1.0 / 120.0)

	TestAssert.is_near(command_60.pitch, command_120.pitch, 0.0001)
	TestAssert.is_near(command_60.yaw, command_120.yaw, 0.0001)
	sixty.free()
	one_twenty.free()


func test_mouse_demand_attacks_and_releases_without_overshoot() -> void:
	var profile := FlightControlProfile.new()
	profile.mouse_response_exponent = 1.0
	profile.pitch_attack_response = 4.0
	profile.pitch_release_response = 6.0
	var adapter := PilotInputAdapter.new()
	adapter.control_profile = profile

	var attacked := adapter.compose_command(Vector2(0.0, -8.0), {}, 1.0 / 60.0)
	var released := adapter.compose_command(Vector2.ZERO, {}, 1.0 / 60.0)

	TestAssert.is_true(attacked.pitch > 0.0)
	TestAssert.is_true(attacked.pitch < 1.0)
	TestAssert.is_true(released.pitch >= 0.0)
	TestAssert.is_true(released.pitch < attacked.pitch)
	adapter.free()


func test_keyboard_roll_ramps_instead_of_stepping() -> void:
	var profile := FlightControlProfile.new()
	profile.roll_attack_response = 3.0
	var adapter := PilotInputAdapter.new()
	adapter.control_profile = profile

	var command := adapter.compose_command(
		Vector2.ZERO,
		{"roll_right": 1.0},
		1.0 / 60.0
	)

	TestAssert.is_true(command.roll > 0.0)
	TestAssert.is_true(command.roll < 1.0)
	adapter.free()


func test_collective_detent_only_pulls_when_idle_inside_window() -> void:
	var profile := FlightControlProfile.new()
	profile.nominal_hover_collective = 0.74
	profile.hover_detent_window = 0.05
	profile.hover_detent_pull_per_second = 0.1
	var adapter := PilotInputAdapter.new()
	adapter.control_profile = profile
	adapter.set_collective_for_test(0.77)

	var idle := adapter.compose_command(Vector2.ZERO, {}, 0.1)
	var active := adapter.compose_command(
		Vector2.ZERO,
		{"collective_up": 1.0},
		0.1
	)

	TestAssert.is_true(idle.collective < 0.77)
	TestAssert.is_true(active.collective > idle.collective)
	adapter.free()


func test_transition_target_and_output_are_bounded_and_smooth() -> void:
	var profile := FlightControlProfile.new()
	profile.transition_input_rate_per_second = 1.0
	profile.transition_follow_response = 2.0
	var adapter := PilotInputAdapter.new()
	adapter.control_profile = profile

	var first := adapter.compose_command(
		Vector2.ZERO,
		{"transition_forward": 1.0},
		0.25
	)
	var second := adapter.compose_command(
		Vector2.ZERO,
		{"transition_forward": 1.0},
		0.25
	)

	TestAssert.is_true(first.transition > 0.0)
	TestAssert.is_true(first.transition < 0.25)
	TestAssert.is_true(second.transition > first.transition)
	TestAssert.is_true(second.transition <= 1.0)
	adapter.free()


func test_reset_clears_smoothed_demand_and_uses_profile_collective() -> void:
	var profile := FlightControlProfile.new()
	profile.nominal_hover_collective = 0.71
	var adapter := PilotInputAdapter.new()
	adapter.control_profile = profile
	adapter.compose_command(Vector2(20.0, -20.0), {"roll_right": 1.0}, 1.0 / 60.0)

	adapter.reset_controls()
	var reset := adapter.compose_command(Vector2.ZERO, {}, 0.0)

	TestAssert.is_near(reset.pitch, 0.0, 0.000001)
	TestAssert.is_near(reset.yaw, 0.0, 0.000001)
	TestAssert.is_near(reset.roll, 0.0, 0.000001)
	TestAssert.is_near(reset.collective, 0.71, 0.000001)
	adapter.free()
```

`set_collective_for_test()` is a narrowly scoped deterministic test seam. It must only assign the internal collective after clamping; it must not read input or alter physics.

- [ ] **Step 2: Run and verify RED**

Run:

```powershell
python tools/verify/verify.py
```

Expected: failures because `control_profile`, the new stateful smoothing behavior, `get_smoothed_control_demand()`, and `set_collective_for_test()` do not exist.

- [ ] **Step 3: Implement the input adapter**

Replace raw `mouse_sensitivity`, `collective_rate_per_second`, `transition_rate_per_second`, and `initial_collective` exports with:

```gdscript
@export var control_profile: FlightControlProfile
```

Add state:

```gdscript
var _smoothed_pitch: float = 0.0
var _smoothed_yaw: float = 0.0
var _smoothed_roll: float = 0.0
var _collective: float = 0.74
var _transition_target: float = 0.0
var _transition: float = 0.0
```

Use a fallback helper:

```gdscript
func _profile() -> FlightControlProfile:
	if control_profile == null:
		control_profile = FlightControlProfile.new()
	return control_profile
```

Inside `compose_command()`:

1. Treat negative or non-finite delta as zero.
2. Convert accumulated pixels into pixels per second only when delta is positive.
3. Divide pitch and yaw mouse speed by their configured full-demand speeds.
4. Apply inversion, `shaped_axis()`, and exponential attack/release smoothing.
5. Smooth keyboard roll toward its target.
6. Update collective manually, then apply the detent only with no active collective key and only inside the configured window.
7. Update `_transition_target`, then exponentially follow it with `_transition`.

Use these helpers exactly:

```gdscript
func _safe_delta(delta: float) -> float:
	return maxf(delta, 0.0) if is_finite(delta) else 0.0


func _exp_follow(current: float, target: float, response: float, delta: float) -> float:
	if delta <= 0.0:
		return current
	var safe_response := clampf(response if is_finite(response) else 0.0, 0.0, 40.0)
	var weight := 1.0 - exp(-safe_response * delta)
	return lerpf(current, target, weight)


func _smooth_axis(
	current: float,
	target: float,
	attack_response: float,
	release_response: float,
	delta: float
) -> float:
	var response := attack_response if absf(target) > absf(current) else release_response
	return clampf(_exp_follow(current, target, response, delta), -1.0, 1.0)
```

Provide:

```gdscript
func get_smoothed_control_demand() -> Vector2:
	return Vector2(_smoothed_yaw, _smoothed_pitch)


func set_collective_for_test(value: float) -> void:
	_collective = clampf(value if is_finite(value) else _profile().nominal_hover_collective, 0.0, 1.0)
```

`reset_controls()` must clear mouse accumulation, pitch/yaw/roll smoothing, transition target/output, and restore `_collective` from `nominal_hover_collective`.

- [ ] **Step 4: Run and verify GREEN**

Run:

```powershell
python tools/verify/verify.py
```

Expected: all input tests pass with no engine errors.

- [ ] **Step 5: Create a local recovery commit**

```bash
git add scripts/input/pilot_input_adapter.gd tests/unit/test_pilot_input_adapter.gd
git commit -m "feat: smooth physics-rate-independent pilot input"
```

Do not push.

---

### Task 3: Closed-Loop Angular-Rate Physics

**Files:**
- Modify: `scripts/flight/flight_model.gd`
- Modify: `tests/unit/test_flight_model.gd`

**Interfaces:**
- Consumes: `FlightControlProfile`.
- Changes signature to:

```gdscript
func calculate(
	parameters: FlightParameters,
	control_profile: FlightControlProfile,
	command: PilotCommand,
	basis: Basis,
	linear_velocity_world: Vector3,
	angular_velocity_world: Vector3,
	air_density_kg_m3: float,
	gravity_world: Vector3
) -> FlightForceResult
```

- Produces helper: `func calculate_rate_torque_world(profile, command, basis, angular_velocity_world) -> Vector3` for deterministic direct testing.

- [ ] **Step 1: Add failing rate-controller tests**

Update every existing `FlightModel.calculate()` call in `tests/unit/test_flight_model.gd` to pass `FlightControlProfile.new()` after `FlightParameters.new()`.

Append:

```gdscript
func test_zero_rate_error_produces_zero_command_torque() -> void:
	var profile := FlightControlProfile.new()
	var command := PilotCommand.new()
	var torque := FlightModel.new().calculate_rate_torque_world(
		profile,
		command,
		Basis.IDENTITY,
		Vector3.ZERO
	)
	TestAssert.is_near(torque.length(), 0.0, 0.000001)


func test_rate_error_torque_points_toward_target() -> void:
	var profile := FlightControlProfile.new()
	var command := PilotCommand.new()
	command.pitch = 1.0
	command.yaw = -1.0
	command.roll = 1.0
	var torque := FlightModel.new().calculate_rate_torque_world(
		profile,
		command,
		Basis.IDENTITY,
		Vector3.ZERO
	)
	TestAssert.is_true(torque.x > 0.0)
	TestAssert.is_true(torque.y < 0.0)
	TestAssert.is_true(torque.z < 0.0)


func test_rate_torque_is_bounded_per_axis() -> void:
	var profile := FlightControlProfile.new()
	profile.max_torque_newton_meters = Vector3(10.0, 20.0, 30.0)
	profile.rate_gain_newton_meters_per_rad_s = Vector3(1000000.0, 1000000.0, 1000000.0)
	var command := PilotCommand.new()
	command.pitch = 1.0
	command.yaw = 1.0
	command.roll = 1.0
	var torque := FlightModel.new().calculate_rate_torque_world(
		profile,
		command,
		Basis.IDENTITY,
		Vector3.ZERO
	)
	TestAssert.is_true(absf(torque.x) <= 10.0)
	TestAssert.is_true(absf(torque.y) <= 20.0)
	TestAssert.is_true(absf(torque.z) <= 30.0)


func test_zero_demand_brakes_rotation_without_auto_levelling() -> void:
	var profile := FlightControlProfile.new()
	var banked_basis := Basis.from_euler(Vector3(0.0, 0.0, deg_to_rad(45.0)))
	var torque := FlightModel.new().calculate_rate_torque_world(
		profile,
		PilotCommand.new(),
		banked_basis,
		Vector3.ZERO
	)
	TestAssert.is_near(torque.length(), 0.0, 0.000001)


func test_rotation_demand_does_not_change_linear_force() -> void:
	var model := FlightModel.new()
	var parameters := FlightParameters.new()
	var profile := FlightControlProfile.new()
	var neutral := model.calculate(
		parameters, profile, PilotCommand.new(), Basis.IDENTITY,
		Vector3(0.0, 0.0, -80.0), Vector3.ZERO, AIR_DENSITY, GRAVITY
	)
	var command := PilotCommand.new()
	command.pitch = 1.0
	command.yaw = -0.5
	command.roll = 0.75
	var demanded := model.calculate(
		parameters, profile, command, Basis.IDENTITY,
		Vector3(0.0, 0.0, -80.0), Vector3.ZERO, AIR_DENSITY, GRAVITY
	)
	TestAssert.is_near(
		demanded.force_world.distance_to(neutral.force_world),
		0.0,
		0.001
	)


func test_non_finite_rate_input_cannot_produce_non_finite_torque() -> void:
	var torque := FlightModel.new().calculate_rate_torque_world(
		FlightControlProfile.new(),
		PilotCommand.new(),
		Basis.IDENTITY,
		Vector3(NAN, INF, -INF)
	)
	TestAssert.is_true(is_finite(torque.x))
	TestAssert.is_true(is_finite(torque.y))
	TestAssert.is_true(is_finite(torque.z))
```

- [ ] **Step 2: Run and verify RED**

Run:

```powershell
python tools/verify/verify.py
```

Expected: signature and missing-helper failures.

- [ ] **Step 3: Implement bounded angular-rate control**

Replace the raw torque and stability-torque block with:

```gdscript
var command_torque_world := calculate_rate_torque_world(
	control_profile,
	clean,
	orientation,
	angular_velocity_world
)
```

Set:

```gdscript
result.torque_world = command_torque_world
```

Implement:

```gdscript
func calculate_rate_torque_world(
	profile: FlightControlProfile,
	command: PilotCommand,
	basis: Basis,
	angular_velocity_world: Vector3
) -> Vector3:
	var safe_profile := profile if profile != null else FlightControlProfile.new()
	var clean := command.sanitized() if command != null else PilotCommand.new()
	var orientation := basis.orthonormalized()
	var safe_angular_velocity := _finite_vector_or_zero(angular_velocity_world)
	var local_angular_velocity := orientation.transposed() * safe_angular_velocity
	var max_rate := safe_profile.blended_max_rate_radians(clean.transition)
	var target_rate := Vector3(
		clean.pitch * max_rate.x,
		clean.yaw * max_rate.y,
		-clean.roll * max_rate.z
	)
	var rate_error := target_rate - local_angular_velocity
	var gain := safe_profile.safe_rate_gain()
	var limit := safe_profile.safe_max_torque()
	var local_torque := Vector3(
		clampf(rate_error.x * gain.x, -limit.x, limit.x),
		clampf(rate_error.y * gain.y, -limit.y, limit.y),
		clampf(rate_error.z * gain.z, -limit.z, limit.z)
	)
	return _finite_vector_or_zero(orientation * local_torque)


func _finite_vector_or_zero(value: Vector3) -> Vector3:
	return Vector3(
		value.x if is_finite(value.x) else 0.0,
		value.y if is_finite(value.y) else 0.0,
		value.z if is_finite(value.z) else 0.0
	)
```

Do not use orientation error, world up, or Euler-angle levelling.

- [ ] **Step 4: Run and verify GREEN**

Run:

```powershell
python tools/verify/verify.py
```

Expected: all flight-model tests pass, including unchanged linear-force behavior.

- [ ] **Step 5: Create a local recovery commit**

```bash
git add scripts/flight/flight_model.gd tests/unit/test_flight_model.gd
git commit -m "feat: add bounded angular rate flight controller"
```

Do not push.

---

### Task 4: Runtime Profile Wiring and Deterministic Reset

**Files:**
- Modify: `scripts/flight/frontier_vtol_controller.gd`
- Modify: `scenes/craft/frontier_vtol.tscn`
- Modify: `scenes/flight_room/flight_room.tscn`
- Modify: `tests/integration/test_frontier_vtol_controller.gd`
- Modify: `tests/integration/test_flight_room_loop.gd`

**Interfaces:**
- `FrontierVtolController` owns `@export var control_profile: FlightControlProfile`.
- `PilotInputAdapter`, `FrontierVtolController`, and later `FlightCameraRig` use the same `.tres` resource path.
- `get_telemetry()` adds `angular_velocity_local_rad_s: Vector3`.

- [ ] **Step 1: Add failing runtime-wiring tests**

Append to `tests/integration/test_frontier_vtol_controller.gd`:

```gdscript
func test_craft_scene_uses_default_control_profile() -> void:
	var packed: PackedScene = load("res://scenes/craft/frontier_vtol.tscn")
	var craft := packed.instantiate() as FrontierVtolController

	TestAssert.is_true(craft.control_profile != null)
	TestAssert.is_true(
		craft.control_profile.resource_path.ends_with(
			"resources/flight/default_flight_control_profile.tres"
		)
	)
	craft.free()


func test_telemetry_reports_local_angular_velocity() -> void:
	var craft := FrontierVtolController.new()
	craft.angular_velocity = Vector3(1.0, 2.0, 3.0)
	var telemetry := craft.get_telemetry()

	TestAssert.is_true(telemetry.has("angular_velocity_local_rad_s"))
	var local_rate: Vector3 = telemetry["angular_velocity_local_rad_s"]
	TestAssert.is_true(is_finite(local_rate.x))
	craft.free()
```

Add `"angular_velocity_local_rad_s"` to `REQUIRED_TELEMETRY_KEYS`.

Append to `tests/integration/test_flight_room_loop.gd`:

```gdscript
func test_flight_room_shares_default_control_profile() -> void:
	var packed: PackedScene = load("res://scenes/flight_room/flight_room.tscn")
	var room := packed.instantiate()
	var craft := room.get_node("FrontierVTOL") as FrontierVtolController
	var input := room.get_node("PilotInputAdapter") as PilotInputAdapter

	TestAssert.is_true(craft.control_profile != null)
	TestAssert.is_true(input.control_profile != null)
	TestAssert.is_equal(craft.control_profile.resource_path, input.control_profile.resource_path)
	room.free()
```

- [ ] **Step 2: Run and verify RED**

Run:

```powershell
python tools/verify/verify.py
```

Expected: missing profile field, old `FlightModel.calculate()` signature, missing telemetry key, and missing scene assignment.

- [ ] **Step 3: Wire the profile and controller**

In `frontier_vtol_controller.gd` add:

```gdscript
@export var control_profile: FlightControlProfile
```

Add:

```gdscript
func _profile() -> FlightControlProfile:
	if control_profile == null:
		control_profile = FlightControlProfile.new()
	return control_profile
```

Pass `_profile()` into `FlightModel.calculate()` after `parameters`.

Add this telemetry helper:

```gdscript
func _local_angular_velocity(world_angular_velocity: Vector3, basis: Basis) -> Vector3:
	return basis.orthonormalized().transposed() * world_angular_velocity
```

Include `angular_velocity_local_rad_s` in both telemetry dictionaries.

In `frontier_vtol.tscn`, declare the profile resource and assign it on `FrontierVTOL`:

```text
[ext_resource type="Resource" path="res://resources/flight/default_flight_control_profile.tres" id="5_control_profile"]
```

```text
control_profile = ExtResource("5_control_profile")
```

In `flight_room.tscn`, declare the same resource and assign it to `PilotInputAdapter`.

Do not duplicate the profile as a local sub-resource.

- [ ] **Step 4: Run and verify GREEN**

Run:

```powershell
python tools/verify/verify.py
```

Expected: controller, scene wiring, route loop, reset, and smoke tests pass.

- [ ] **Step 5: Create a local recovery commit**

```bash
git add scripts/flight/frontier_vtol_controller.gd scenes/craft/frontier_vtol.tscn scenes/flight_room/flight_room.tscn tests/integration/test_frontier_vtol_controller.gd tests/integration/test_flight_room_loop.gd
git commit -m "feat: wire shared control profile into runtime"
```

Do not push.

---

### Task 5: Comfortable Craft-Relative Chase Camera

**Files:**
- Modify: `scripts/camera/flight_camera_rig.gd`
- Modify: `scenes/craft/flight_camera_rig.tscn`
- Modify: `scenes/flight_room/flight_room.tscn`
- Modify: `tests/unit/test_flight_camera_rig.gd`

**Interfaces:**
- Consumes: shared `FlightControlProfile`.
- Produces: `func calculate_chase_fov(speed_mps: float) -> float`.
- Produces: `func calculate_velocity_lookahead(velocity_world: Vector3) -> Vector3`.
- Produces: `func attenuate_chase_roll(target_basis: Basis) -> Basis`.
- Preserves exact cockpit-anchor transform in cockpit mode.

- [ ] **Step 1: Add failing camera tests**

Append to `tests/unit/test_flight_camera_rig.gd`:

```gdscript
func test_chase_fov_is_monotonic_and_bounded() -> void:
	var rig := FlightCameraRig.new()
	rig.control_profile = FlightControlProfile.new()
	var slow := rig.calculate_chase_fov(0.0)
	var medium := rig.calculate_chase_fov(100.0)
	var fast := rig.calculate_chase_fov(1000.0)

	TestAssert.is_true(medium > slow)
	TestAssert.is_true(fast >= medium)
	TestAssert.is_near(slow, rig.control_profile.min_chase_fov_degrees, 0.000001)
	TestAssert.is_near(fast, rig.control_profile.max_chase_fov_degrees, 0.000001)
	rig.free()


func test_velocity_lookahead_is_bounded() -> void:
	var rig := FlightCameraRig.new()
	rig.control_profile = FlightControlProfile.new()
	rig.control_profile.chase_max_lookahead_meters = 12.0
	var lookahead := rig.calculate_velocity_lookahead(Vector3(1000.0, 0.0, 0.0))

	TestAssert.is_true(lookahead.length() <= 12.0001)
	TestAssert.is_true(lookahead.x > 0.0)
	rig.free()


func test_roll_attenuation_preserves_forward_direction() -> void:
	var rig := FlightCameraRig.new()
	rig.control_profile = FlightControlProfile.new()
	rig.control_profile.chase_roll_follow_amount = 0.25
	var rolled := Basis.from_euler(Vector3(0.0, 0.0, deg_to_rad(70.0)))
	var attenuated := rig.attenuate_chase_roll(rolled)

	TestAssert.is_true((-attenuated.z).dot(-rolled.z) > 0.999)
	TestAssert.is_true(absf(attenuated.get_euler().z) < absf(rolled.get_euler().z))
	rig.free()


func test_camera_scene_uses_default_control_profile() -> void:
	var packed: PackedScene = load("res://scenes/craft/flight_camera_rig.tscn")
	var rig := packed.instantiate() as FlightCameraRig

	TestAssert.is_true(rig.control_profile != null)
	rig.free()
```

- [ ] **Step 2: Run and verify RED**

Run:

```powershell
python tools/verify/verify.py
```

Expected: missing profile field and helper methods.

- [ ] **Step 3: Implement camera response**

Add:

```gdscript
@export var control_profile: FlightControlProfile
```

Store the bound craft as `Node3D` and read velocity only when it is a `RigidBody3D`.

In chase mode:

1. Target position is the chase anchor position plus bounded world-velocity look-ahead.
2. Position follows using `chase_position_response`.
3. Target basis passes through `attenuate_chase_roll()`.
4. Rotation follows using `chase_rotation_response`.
5. FOV follows `calculate_chase_fov(speed)` using `chase_fov_response`.

Use:

```gdscript
func calculate_chase_fov(speed_mps: float) -> float:
	var profile := _profile()
	var speed := maxf(speed_mps, 0.0) if is_finite(speed_mps) else 0.0
	var full_speed := maxf(profile.chase_fov_full_speed_mps, 1.0)
	var weight := clampf(speed / full_speed, 0.0, 1.0)
	return lerpf(profile.min_chase_fov_degrees, profile.max_chase_fov_degrees, weight)


func calculate_velocity_lookahead(velocity_world: Vector3) -> Vector3:
	var profile := _profile()
	var safe_velocity := Vector3(
		velocity_world.x if is_finite(velocity_world.x) else 0.0,
		velocity_world.y if is_finite(velocity_world.y) else 0.0,
		velocity_world.z if is_finite(velocity_world.z) else 0.0
	)
	return (safe_velocity * maxf(profile.chase_lookahead_seconds, 0.0)).limit_length(
		maxf(profile.chase_max_lookahead_meters, 0.0)
	)
```

For roll attenuation, preserve forward and blend between a stable-up basis and the full target basis. When forward is nearly parallel to world up, return the original target basis to avoid singularity.

Cockpit mode must remain exact: no look-ahead, roll attenuation, smoothing, or dynamic FOV.

Assign `default_flight_control_profile.tres` in `flight_camera_rig.tscn`. The room scene continues to bind the craft path.

- [ ] **Step 4: Run and verify GREEN**

Run:

```powershell
python tools/verify/verify.py
```

Expected: camera tests and gameplay smoke pass.

- [ ] **Step 5: Create a local recovery commit**

```bash
git add scripts/camera/flight_camera_rig.gd scenes/craft/flight_camera_rig.tscn scenes/flight_room/flight_room.tscn tests/unit/test_flight_camera_rig.gd
git commit -m "feat: improve chase camera response"
```

Do not push.

---

### Task 6: Control-Demand HUD Cue and Camera-State Routing

**Files:**
- Modify: `scripts/ui/flight_hud.gd`
- Modify: `scenes/ui/flight_hud.tscn`
- Modify: `scripts/game/flight_room_controller.gd`
- Modify: `tests/unit/test_flight_hud.gd`
- Modify: `tests/integration/test_flight_room_loop.gd`

**Interfaces:**
- Produces: `FlightHud.set_control_demand(demand: Vector2) -> void`.
- Produces: `FlightHud.set_camera_mode(mode: int) -> void`.
- Produces: static `FlightHud.control_marker_offset(demand: Vector2, radius: float) -> Vector2`.
- Changes camera-toggle connection from direct signal-to-rig binding to `FlightRoomController._on_camera_toggle_requested()`.

- [ ] **Step 1: Add failing HUD and room-routing tests**

Append to `tests/unit/test_flight_hud.gd`:

```gdscript
func test_control_marker_offset_is_bounded() -> void:
	var offset := FlightHud.control_marker_offset(Vector2(4.0, 3.0), 32.0)
	TestAssert.is_true(offset.length() <= 32.0001)


func test_control_marker_preserves_direction() -> void:
	var offset := FlightHud.control_marker_offset(Vector2(0.5, -0.25), 32.0)
	TestAssert.is_true(offset.x > 0.0)
	TestAssert.is_true(offset.y < 0.0)
```

Append to `tests/integration/test_flight_room_loop.gd`:

```gdscript
func test_camera_toggle_updates_rig_and_hud_mode() -> void:
	var packed: PackedScene = load("res://scenes/flight_room/flight_room.tscn")
	var room := packed.instantiate() as FlightRoomController
	room.call("_ready")
	var rig := room.get_node("FlightCameraRig") as FlightCameraRig
	var hud := room.get_node("FlightHud") as FlightHud

	room.call("_on_camera_toggle_requested")

	TestAssert.is_equal(rig.get_mode(), FlightCameraRig.MODE_COCKPIT)
	TestAssert.is_equal(hud.get_camera_mode_for_test(), FlightCameraRig.MODE_COCKPIT)
	room.free()
```

- [ ] **Step 2: Run and verify RED**

Run:

```powershell
python tools/verify/verify.py
```

Expected: missing HUD methods and room callback.

- [ ] **Step 3: Implement the restrained cue**

Replace the centre `Reticle` label in `flight_hud.tscn` with:

```text
[node name="ControlDemandCue" type="Control" parent="."]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -42.0
offset_top = -42.0
offset_right = 42.0
offset_bottom = 42.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="ReferenceDot" type="Label" parent="ControlDemandCue"]
offset_left = 34.0
offset_top = 29.0
offset_right = 50.0
offset_bottom = 55.0
theme_override_colors/font_color = Color(0.55, 0.93, 0.9, 0.3)
text = "·"
horizontal_alignment = 1

[node name="DemandMarker" type="Label" parent="ControlDemandCue"]
offset_left = 32.0
offset_top = 27.0
offset_right = 52.0
offset_bottom = 57.0
theme_override_colors/font_color = Color(0.55, 0.93, 0.9, 0.72)
text = "◇"
horizontal_alignment = 1
```

In `flight_hud.gd` add node references, state, and:

```gdscript
const CONTROL_CUE_RADIUS: float = 32.0
var _camera_mode: int = FlightCameraRig.MODE_CHASE


static func control_marker_offset(demand: Vector2, radius: float) -> Vector2:
	var safe := Vector2(
		demand.x if is_finite(demand.x) else 0.0,
		demand.y if is_finite(demand.y) else 0.0
	)
	return safe.limit_length(maxf(radius, 0.0))


func set_control_demand(demand: Vector2) -> void:
	if not is_node_ready():
		return
	var offset := control_marker_offset(demand * CONTROL_CUE_RADIUS, CONTROL_CUE_RADIUS)
	_demand_marker.position = Vector2(32.0, 27.0) + offset
	_demand_marker.modulate.a = 0.35 + clampf(demand.length(), 0.0, 1.0) * 0.65


func set_camera_mode(mode: int) -> void:
	_camera_mode = mode
	if is_node_ready():
		_control_demand_cue.modulate.a = 0.35 if mode == FlightCameraRig.MODE_COCKPIT else 1.0


func get_camera_mode_for_test() -> int:
	return _camera_mode
```

In `flight_room_controller.gd`:

- connect `camera_toggle_requested` to `_on_camera_toggle_requested` instead of directly to `_camera_rig.toggle_mode`;
- call `_hud.set_control_demand(_input_adapter.get_smoothed_control_demand())` from `_on_pilot_command_updated`;
- implement:

```gdscript
func _on_camera_toggle_requested() -> void:
	if _camera_rig == null:
		return
	var mode := _camera_rig.toggle_mode()
	if _hud != null:
		_hud.set_camera_mode(mode)
```

On restart, set HUD camera mode to chase after the rig is reset.

- [ ] **Step 4: Run and verify GREEN**

Run:

```powershell
python tools/verify/verify.py
```

Expected: HUD, route-loop, reset, camera, and gameplay-smoke tests pass.

- [ ] **Step 5: Create a local recovery commit**

```bash
git add scripts/ui/flight_hud.gd scenes/ui/flight_hud.tscn scripts/game/flight_room_controller.gd tests/unit/test_flight_hud.gd tests/integration/test_flight_room_loop.gd
git commit -m "feat: add control demand feedback"
```

Do not push.

---

### Task 7: Contract Hardening, Local Verification, Windows Build, and Handoff

**Files:**
- Modify: `scripts/validation/project_contract_validator.gd`
- Modify: `tools/verify/verify.py`
- Modify: `README.md`
- Review: every file changed in Tasks 1–6

**Interfaces:**
- Clean-checkout verifier requires both control-profile files.
- Final handoff contains one squashed local commit, a Windows ZIP, verification logs, and a concise tuning report.

- [ ] **Step 1: Add the new required paths to both contracts**

Add:

```text
scripts/flight/flight_control_profile.gd
resources/flight/default_flight_control_profile.tres
```

Use `res://` prefixes in `project_contract_validator.gd` and repository-relative paths in `tools/verify/verify.py`.

- [ ] **Step 2: Update README controls and architecture**

Document these facts only after implementation matches them:

- mouse movement commands angular rate rather than raw torque;
- no auto-level or altitude hold exists;
- Q/E roll is smoothed;
- collective has a small idle hover detent;
- vector transition is target-smoothed;
- chase camera uses speed FOV and velocity look-ahead;
- control tuning lives in `resources/flight/default_flight_control_profile.tres`.

Record the final accepted default values from the `.tres` or script defaults. Do not claim final-polish status.

- [ ] **Step 3: Run the complete local verifier from a clean worktree**

Run:

```powershell
python tools/verify/verify.py
```

Required evidence:

- repository contract passes;
- Godot import passes;
- every headless test passes with zero failures;
- gameplay scene smoke test passes and tears down cleanly;
- no parser error, runtime error, leaked-object error, or forbidden engine output.

- [ ] **Step 4: Build the Windows package locally**

With Godot 4.6.3 Windows export templates installed, run:

```powershell
python tools/verify/verify.py --export-windows
```

Confirm these files exist and are non-empty:

```text
build/windows/STRATOSPHERE.exe
build/windows/STRATOSPHERE.pck
```

Create a ZIP containing exactly those two files.

- [ ] **Step 5: Perform the scripted control acceptance checks**

Add no new automation solely to fake subjective polish. Use the real Windows build and record observations for:

1. takeoff with no immediate drop or torque spike;
2. fine hover corrections;
3. controlled 90-degree yaw and predictable stop;
4. pitch-over into forward flight;
5. full roll and release stop;
6. forward-to-hover transition;
7. chase-camera comfort during pitch, yaw, and roll;
8. route completion and landing;
9. crash/restart with no stale input;
10. comparison at stable 60 FPS and an intentionally limited lower frame rate.

Where the environment cannot perform human playtesting, mark the item `NEEDS USER PLAYTEST`; do not falsely mark it passed.

- [ ] **Step 6: Review the complete diff**

Run:

```bash
git diff 6dea1a4f60b522b365732a5ca5045c28cce9b3b4...HEAD --stat
git diff 6dea1a4f60b522b365732a5ca5045c28cce9b3b4...HEAD
```

Reject unrelated edits, Blender changes, binary changes, workflow edits, route edits, or content expansion.

- [ ] **Step 7: Squash local recovery commits into one milestone commit**

```bash
git reset --soft 6dea1a4f60b522b365732a5ca5045c28cce9b3b4
git commit -m "feat: polish keyboard and mouse flight controls"
```

Do not push.

- [ ] **Step 8: Return the review package**

Return:

- final local commit SHA;
- complete changed-file list;
- `git diff --stat`;
- full verifier summary and test count;
- Windows ZIP;
- exact control-profile values;
- acceptance-playtest table with honest PASS/FAIL/NEEDS USER PLAYTEST values;
- remaining known weaknesses;
- confirmation that nothing was pushed and no GitHub Actions run was triggered.

---

## Codex Execution Prompt

Paste the following into Codex after cloning or opening `manbtd0-cloud/stratosphere`:

```text
Use the installed Superpowers workflow.

Repository: manbtd0-cloud/stratosphere
Base branch: agent/phase-0-1-flight-room
Base commit: 6dea1a4f60b522b365732a5ca5045c28cce9b3b4

Read these documents first:

1. docs/superpowers/specs/2026-08-04-control-polish-design.md from branch design/control-polish
2. docs/superpowers/plans/2026-08-05-control-polish-implementation-plan.md from branch design/control-polish
3. README.md

Then execute the implementation plan task-by-task using strict TDD.

Mandatory operating rules:

- Create an isolated local git worktree from the exact base commit.
- Do not push any branch or commit.
- Do not open or update pull requests.
- Do not trigger, edit, or rerun GitHub Actions.
- Do not modify Blender assets, GLB files, .blend files, asset workflows, route content, combat, progression, or world content.
- Local recovery commits are allowed after each green task.
- At completion, squash all local work into exactly one commit named:
  feat: polish keyboard and mouse flight controls
- Run the complete local verifier.
- Run the local Windows export.
- Be honest about subjective playtest items that require the user.
- Do not claim completion unless the final clean verifier and Windows export both pass.

Return the complete review package requested by Task 7. Do not push anything.
```

---

## Plan Self-Review Result

- Spec coverage: input, rate control, mode blending, collective detent, transition smoothing, camera behavior, HUD cue, error handling, reset behavior, tests, manual acceptance, CI-budget policy, and handoff are covered.
- Placeholder scan: no `TBD`, `TODO`, unspecified error handling, or undefined implementation step remains.
- Type consistency: `FlightControlProfile`, `control_profile`, `blended_max_rate_radians()`, `calculate_rate_torque_world()`, `get_smoothed_control_demand()`, `calculate_chase_fov()`, `calculate_velocity_lookahead()`, `attenuate_chase_roll()`, `set_control_demand()`, and `set_camera_mode()` are used consistently across tasks.
- Scope check: the plan changes control feel, camera comfort, and minimal feedback only; model integration and unrelated game systems remain excluded.
