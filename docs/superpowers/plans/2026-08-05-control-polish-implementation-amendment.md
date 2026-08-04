# Control Polish Implementation Plan — Authoritative Amendment

**Applies to:** `docs/superpowers/plans/2026-08-05-control-polish-implementation-plan.md`  
**Status:** Mandatory; these corrections override conflicting steps in the main plan.

This amendment fixes issues found during the required plan self-review. Codex must read this file after the main plan and follow these corrections exactly.

## Correction 1: Preserve `FlightModel.calculate()` Compatibility During TDD

The main plan places `control_profile` after `parameters`, which would break the controller and every existing call during Task 3. Do not use that signature.

Preserve all existing positional arguments and add the profile as an optional final argument:

```gdscript
func calculate(
	parameters: FlightParameters,
	command: PilotCommand,
	basis: Basis,
	linear_velocity_world: Vector3,
	angular_velocity_world: Vector3,
	air_density_kg_m3: float,
	gravity_world: Vector3,
	control_profile: FlightControlProfile = null
) -> FlightForceResult:
```

Inside `calculate()` use:

```gdscript
var safe_profile := control_profile if control_profile != null else FlightControlProfile.new()
```

and pass `safe_profile` into `calculate_rate_torque_world()`.

Consequences:

- Existing `FlightModel.calculate()` calls remain valid during Task 3.
- Existing tests do not need argument reordering.
- New tests that need custom tuning pass the profile as the final argument.
- In Task 4, `FrontierVtolController` passes `_profile()` as the final argument after `state.total_gravity`.

The new linear-force independence test must call:

```gdscript
var neutral := model.calculate(
	parameters,
	PilotCommand.new(),
	Basis.IDENTITY,
	Vector3(0.0, 0.0, -80.0),
	Vector3.ZERO,
	AIR_DENSITY,
	GRAVITY,
	profile
)
```

and use the same argument order for the demanded result.

## Correction 2: Update Legacy Input Tests Instead of Only Appending Tests

The existing input tests reference fields removed by the new architecture. Replace the first four tests in `tests/unit/test_pilot_input_adapter.gd` with the versions below.

```gdscript
func test_mouse_velocity_converts_to_bounded_pitch_and_yaw() -> void:
	var profile := FlightControlProfile.new()
	profile.full_pitch_mouse_speed_px_s = 250.0
	profile.full_yaw_mouse_speed_px_s = 250.0
	profile.mouse_response_exponent = 1.0
	profile.pitch_attack_response = 40.0
	profile.yaw_attack_response = 40.0
	var adapter := PilotInputAdapter.new()
	adapter.control_profile = profile

	var command := adapter.compose_command(
		Vector2(250.0, -250.0),
		{},
		1.0
	)

	TestAssert.is_near(command.pitch, 1.0, 0.000001)
	TestAssert.is_near(command.yaw, -1.0, 0.000001)
	adapter.free()


func test_transition_accumulates_follows_and_clamps() -> void:
	var profile := FlightControlProfile.new()
	profile.transition_input_rate_per_second = 2.0
	profile.transition_follow_response = 40.0
	var adapter := PilotInputAdapter.new()
	adapter.control_profile = profile

	var forward := adapter.compose_command(
		Vector2.ZERO,
		{"transition_forward": 1.0},
		1.0
	)
	var backward := adapter.compose_command(
		Vector2.ZERO,
		{"transition_backward": 1.0},
		1.0
	)

	TestAssert.is_near(forward.transition, 1.0, 0.000001)
	TestAssert.is_near(backward.transition, 0.0, 0.000001)
	adapter.free()


func test_collective_accumulates_and_clamps() -> void:
	var profile := FlightControlProfile.new()
	profile.collective_rate_per_second = 2.0
	var adapter := PilotInputAdapter.new()
	adapter.control_profile = profile

	var raised := adapter.compose_command(
		Vector2.ZERO,
		{"collective_up": 1.0},
		1.0
	)
	var lowered := adapter.compose_command(
		Vector2.ZERO,
		{"collective_down": 1.0},
		1.0
	)

	TestAssert.is_equal(raised.collective, 1.0)
	TestAssert.is_equal(lowered.collective, 0.0)
	adapter.free()


func test_new_and_reset_controls_use_profile_hover_collective() -> void:
	var profile := FlightControlProfile.new()
	profile.nominal_hover_collective = 0.72
	var adapter := PilotInputAdapter.new()
	adapter.control_profile = profile

	adapter.reset_controls()
	var initial := adapter.compose_command(Vector2.ZERO, {}, 0.0)
	TestAssert.is_near(initial.collective, 0.72, 0.000001)

	adapter.compose_command(
		Vector2.ZERO,
		{"collective_down": 1.0},
		1.0
	)
	adapter.reset_controls()
	var reset := adapter.compose_command(Vector2.ZERO, {}, 0.0)
	TestAssert.is_near(reset.collective, 0.72, 0.000001)
	adapter.free()
```

Replace the main plan's one-frame 60/120 Hz equivalence test with a same-duration test. Exponential smoothing is rate-independent over equal elapsed time, not over a different number of seconds:

```gdscript
func test_equivalent_mouse_velocity_matches_after_equal_time_at_60_and_120_hz() -> void:
	var profile := FlightControlProfile.new()
	profile.mouse_response_exponent = 1.0
	var sixty := PilotInputAdapter.new()
	var one_twenty := PilotInputAdapter.new()
	sixty.control_profile = profile
	one_twenty.control_profile = profile
	var command_60 := PilotCommand.new()
	var command_120 := PilotCommand.new()

	for _step in range(60):
		command_60 = sixty.compose_command(
			Vector2(10.0, -10.0),
			{},
			1.0 / 60.0
		)
	for _step in range(120):
		command_120 = one_twenty.compose_command(
			Vector2(5.0, -5.0),
			{},
			1.0 / 120.0
		)

	TestAssert.is_near(command_60.pitch, command_120.pitch, 0.0005)
	TestAssert.is_near(command_60.yaw, command_120.yaw, 0.0005)
	sixty.free()
	one_twenty.free()
```

Do not add `set_collective_for_test()` to production code. Replace that test seam with Godot's property access in the detent test:

```gdscript
adapter.set("_collective", 0.77)
```

The detent behavior is public through `compose_command()`; no test-only production API is justified.

## Correction 3: Sanitize Non-Finite `PilotCommand` Values

The design requires non-finite input safety, but the main plan only sanitizes angular velocity and tuning. Add this work to Task 2.

**Files:**

- Modify: `scripts/flight/pilot_command.gd`
- Modify: `tests/unit/test_pilot_command.gd`

Add this failing test first:

```gdscript
func test_sanitized_replaces_non_finite_values() -> void:
	var command := PilotCommand.new()
	command.pitch = NAN
	command.yaw = INF
	command.roll = -INF
	command.collective = NAN
	command.strafe = Vector3(NAN, INF, -INF)
	command.transition = INF
	command.brake = NAN

	var clean := command.sanitized()

	TestAssert.is_near(clean.pitch, 0.0, 0.000001)
	TestAssert.is_near(clean.yaw, 0.0, 0.000001)
	TestAssert.is_near(clean.roll, 0.0, 0.000001)
	TestAssert.is_near(clean.collective, 0.0, 0.000001)
	TestAssert.is_equal(clean.strafe, Vector3.ZERO)
	TestAssert.is_near(clean.transition, 0.0, 0.000001)
	TestAssert.is_near(clean.brake, 0.0, 0.000001)
```

Implement a scalar helper in `pilot_command.gd`:

```gdscript
func _finite_or_zero(value: float) -> float:
	return value if is_finite(value) else 0.0
```

Sanitize each scalar before clamping. Sanitize each strafe component before normalizing:

```gdscript
clean.strafe = Vector3(
	_finite_or_zero(strafe.x),
	_finite_or_zero(strafe.y),
	_finite_or_zero(strafe.z)
)
```

Include these files in Task 2's local recovery commit.

## Correction 4: Do Not Manually Invoke `_ready()` Outside the Scene Tree

The main plan's camera-toggle integration test manually calls `_ready()` on a scene that is not in the tree. `FlightRoomController._ready()` calls `get_tree()`, so that test is invalid.

Replace it with direct dependency injection through Godot properties:

```gdscript
func test_camera_toggle_updates_rig_and_hud_mode() -> void:
	var room := FlightRoomController.new()
	var rig := FlightCameraRig.new()
	var hud_scene: PackedScene = load("res://scenes/ui/flight_hud.tscn")
	var hud := hud_scene.instantiate() as FlightHud
	room.set("_camera_rig", rig)
	room.set("_hud", hud)

	room.call("_on_camera_toggle_requested")

	TestAssert.is_equal(rig.get_mode(), FlightCameraRig.MODE_COCKPIT)
	TestAssert.is_equal(hud.get_camera_mode_for_test(), FlightCameraRig.MODE_COCKPIT)
	hud.free()
	rig.free()
	room.free()
```

`FlightHud.set_camera_mode()` must update its internal `_camera_mode` before checking `is_node_ready()`, so the test remains valid without adding the HUD to the tree.

The actual gameplay scene remains covered by `tests/gameplay_smoke_runner.gd`, which is the correct test for `_ready()` and real scene-tree wiring.

## Correction 5: Updated Task 2 Commit Scope

Task 2's local commit command becomes:

```bash
git add scripts/input/pilot_input_adapter.gd scripts/flight/pilot_command.gd tests/unit/test_pilot_input_adapter.gd tests/unit/test_pilot_command.gd
git commit -m "feat: smooth and sanitize pilot input"
```

Do not push.

## Correction 6: Updated Codex Reading Order

Codex must read documents in this order:

1. `docs/superpowers/specs/2026-08-04-control-polish-design.md`
2. `docs/superpowers/plans/2026-08-05-control-polish-implementation-plan.md`
3. `docs/superpowers/plans/2026-08-05-control-polish-implementation-amendment.md`
4. `README.md`

Where the amendment conflicts with the main plan, the amendment is authoritative.
