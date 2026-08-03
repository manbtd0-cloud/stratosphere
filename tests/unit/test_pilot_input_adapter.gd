class_name TestPilotInputAdapter
extends TestCase


func test_mouse_delta_converts_to_bounded_pitch_and_yaw() -> void:
	var adapter := PilotInputAdapter.new()
	adapter.mouse_sensitivity = 0.01

	var command := adapter.compose_command(
		Vector2(250.0, -250.0),
		{},
		0.0
	)

	TestAssert.is_equal(command.pitch, 1.0)
	TestAssert.is_equal(command.yaw, -1.0)
	adapter.free()


func test_transition_accumulates_and_clamps() -> void:
	var adapter := PilotInputAdapter.new()
	adapter.transition_rate_per_second = 2.0

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

	TestAssert.is_equal(forward.transition, 1.0)
	TestAssert.is_equal(backward.transition, 0.0)
	adapter.free()


func test_collective_accumulates_and_clamps() -> void:
	var adapter := PilotInputAdapter.new()
	adapter.collective_rate_per_second = 2.0

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


func test_new_and_reset_controls_start_near_hover_collective() -> void:
	var adapter := PilotInputAdapter.new()

	var initial := adapter.compose_command(Vector2.ZERO, {}, 0.0)
	TestAssert.is_near(initial.collective, 0.74, 0.000001)

	adapter.compose_command(
		Vector2.ZERO,
		{"collective_down": 1.0},
		1.0
	)
	adapter.reset_controls()
	var reset := adapter.compose_command(Vector2.ZERO, {}, 0.0)
	TestAssert.is_near(reset.collective, 0.74, 0.000001)
	adapter.free()


func test_required_input_actions_are_created() -> void:
	var adapter := PilotInputAdapter.new()
	adapter.ensure_input_actions()

	for action_name in PilotInputAdapter.REQUIRED_ACTIONS:
		TestAssert.is_true(InputMap.has_action(action_name))

	adapter.free()