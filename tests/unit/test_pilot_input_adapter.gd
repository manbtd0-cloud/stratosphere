class_name TestPilotInputAdapter
extends TestCase


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


func test_required_input_actions_are_created() -> void:
	var adapter := PilotInputAdapter.new()
	adapter.ensure_input_actions()

	for action_name in PilotInputAdapter.REQUIRED_ACTIONS:
		TestAssert.is_true(InputMap.has_action(action_name))

	adapter.free()


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
	adapter.set("_collective", 0.77)

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
	adapter.compose_command(
		Vector2(20.0, -20.0),
		{"roll_right": 1.0},
		1.0 / 60.0
	)

	adapter.reset_controls()
	var reset := adapter.compose_command(Vector2.ZERO, {}, 0.0)

	TestAssert.is_near(reset.pitch, 0.0, 0.000001)
	TestAssert.is_near(reset.yaw, 0.0, 0.000001)
	TestAssert.is_near(reset.roll, 0.0, 0.000001)
	TestAssert.is_near(reset.collective, 0.71, 0.000001)
	adapter.free()
