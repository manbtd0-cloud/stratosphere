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
	TestAssert.is_true(result.total_force_world.y > 0.0)


func test_transition_rotates_thrust_forward() -> void:
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
	TestAssert.is_near(result.thrust_force_world.y, 0.0, 0.000001)


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


func test_pitch_input_creates_local_x_torque() -> void:
	var command := PilotCommand.new()
	command.pitch = 1.0
	var result := FlightModel.new().calculate(
		FlightParameters.new(),
		command,
		Basis.IDENTITY,
		Vector3.ZERO,
		Vector3.ZERO,
		AIR_DENSITY,
		GRAVITY
	)
	TestAssert.is_true(result.total_torque_world.x > 0.0)
	TestAssert.is_near(result.total_torque_world.y, 0.0, 0.000001)


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
		velocity += result.total_force_world / parameters.mass_kg * delta

	return velocity
