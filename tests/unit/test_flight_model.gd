class_name TestFlightModel
extends TestCase

const GRAVITY := Vector3(0.0, -9.81, 0.0)
const AIR_DENSITY := 1.225


func test_full_hover_collective_produces_net_upward_force() -> void:
	var command := PilotCommand.new()
	command.collective = 1.0
	var result := FlightModel.new().calculate(
		FlightParameters.new(),
		command,
		Basis.IDENTITY,
		Vector3.ZERO,
		Vector3.ZERO,
		AIR_DENSITY,
		GRAVITY
	)
	TestAssert.is_true(result.force_world.y > 0.0)


func test_full_transition_points_thrust_forward() -> void:
	var command := PilotCommand.new()
	command.collective = 1.0
	command.transition = 1.0
	var result := FlightModel.new().calculate(
		FlightParameters.new(),
		command,
		Basis.IDENTITY,
		Vector3.ZERO,
		Vector3.ZERO,
		AIR_DENSITY,
		GRAVITY
	)
	TestAssert.is_true(result.thrust_force_world.z < -70000.0)
	TestAssert.is_near(result.thrust_force_world.y, 0.0, 0.005)


func test_mid_transition_rotates_thrust_without_power_collapse() -> void:
	var parameters := FlightParameters.new()
	var command := PilotCommand.new()
	command.collective = 1.0
	command.transition = 0.5
	var result := FlightModel.new().calculate(
		parameters,
		command,
		Basis.IDENTITY,
		Vector3.ZERO,
		Vector3.ZERO,
		AIR_DENSITY,
		GRAVITY
	)
	var expected_thrust := lerpf(
		parameters.hover_thrust_newtons,
		parameters.forward_thrust_newtons,
		0.5
	)
	TestAssert.is_near(result.thrust_newtons, expected_thrust, 0.01)
	TestAssert.is_true(result.thrust_force_world.y > 0.0)
	TestAssert.is_true(result.thrust_force_world.z < 0.0)


func test_drag_opposes_velocity() -> void:
	var result := FlightModel.new().calculate(
		FlightParameters.new(),
		PilotCommand.new(),
		Basis.IDENTITY,
		Vector3(0.0, 0.0, -100.0),
		Vector3.ZERO,
		AIR_DENSITY,
		GRAVITY
	)
	TestAssert.is_true(result.drag_force_world.z > 0.0)
	TestAssert.is_near(result.drag_force_world.x, 0.0, 0.000001)
	TestAssert.is_near(result.drag_force_world.y, 0.0, 0.000001)
	TestAssert.is_true(result.drag_newtons > 0.0)


func test_rotation_input_changes_torque_but_not_linear_force() -> void:
	var model := FlightModel.new()
	var parameters := FlightParameters.new()
	var neutral := model.calculate(
		parameters,
		PilotCommand.new(),
		Basis.IDENTITY,
		Vector3.ZERO,
		Vector3.ZERO,
		AIR_DENSITY,
		GRAVITY
	)
	var command := PilotCommand.new()
	command.pitch = 1.0
	var rotated := model.calculate(
		parameters,
		command,
		Basis.IDENTITY,
		Vector3.ZERO,
		Vector3.ZERO,
		AIR_DENSITY,
		GRAVITY
	)
	TestAssert.is_near(rotated.force_world.distance_to(neutral.force_world), 0.0, 0.000001)
	TestAssert.is_true(rotated.torque_world.x > 0.0)
	TestAssert.is_near(rotated.torque_world.y, 0.0, 0.000001)


func test_one_second_hover_is_repeatable_and_climbs() -> void:
	var first := _simulate_hover_second()
	var second := _simulate_hover_second()
	TestAssert.is_near(first.distance_to(second), 0.0, 0.000001)
	TestAssert.is_true(first.y > 0.0)


func _simulate_hover_second() -> Vector3:
	var parameters := FlightParameters.new()
	var command := PilotCommand.new()
	command.collective = 1.0
	var model := FlightModel.new()
	var velocity := Vector3.ZERO
	var delta := 1.0 / 120.0

	for _step in range(120):
		var result := model.calculate(
			parameters,
			command,
			Basis.IDENTITY,
			velocity,
			Vector3.ZERO,
			AIR_DENSITY,
			GRAVITY
		)
		velocity += result.force_world / parameters.mass_kg * delta

	return velocity