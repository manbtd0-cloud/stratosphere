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


func test_zero_rate_error_produces_zero_command_torque() -> void:
	var torque := FlightModel.new().calculate_rate_torque_world(
		FlightControlProfile.new(),
		PilotCommand.new(),
		Basis.IDENTITY,
		Vector3.ZERO
	)
	TestAssert.is_near(torque.length(), 0.0, 0.000001)


func test_rate_error_torque_points_toward_target() -> void:
	var command := PilotCommand.new()
	command.pitch = 1.0
	command.yaw = -1.0
	command.roll = 1.0
	var torque := FlightModel.new().calculate_rate_torque_world(
		FlightControlProfile.new(),
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


func test_zero_demand_does_not_auto_level_a_banked_craft() -> void:
	var banked_basis := Basis.from_euler(Vector3(0.0, 0.0, deg_to_rad(45.0)))
	var torque := FlightModel.new().calculate_rate_torque_world(
		FlightControlProfile.new(),
		PilotCommand.new(),
		banked_basis,
		Vector3.ZERO
	)
	TestAssert.is_near(torque.length(), 0.0, 0.000001)


func test_zero_demand_brakes_existing_rotation() -> void:
	var torque := FlightModel.new().calculate_rate_torque_world(
		FlightControlProfile.new(),
		PilotCommand.new(),
		Basis.IDENTITY,
		Vector3(0.5, -0.25, 0.75)
	)
	TestAssert.is_true(torque.x < 0.0)
	TestAssert.is_true(torque.y > 0.0)
	TestAssert.is_true(torque.z < 0.0)


func test_custom_profile_blends_control_authority_continuously() -> void:
	var profile := FlightControlProfile.new()
	profile.hover_max_rate_degrees = Vector3(60.0, 50.0, 70.0)
	profile.forward_max_rate_degrees = Vector3(100.0, 30.0, 130.0)
	profile.rate_gain_newton_meters_per_rad_s = Vector3.ONE * 1000.0
	profile.max_torque_newton_meters = Vector3.ONE * 100000.0
	var command := PilotCommand.new()
	command.pitch = 1.0
	command.transition = 0.5
	var torque := FlightModel.new().calculate_rate_torque_world(
		profile,
		command,
		Basis.IDENTITY,
		Vector3.ZERO
	)
	TestAssert.is_near(torque.x, deg_to_rad(80.0) * 1000.0, 0.001)


func test_rotation_demand_does_not_change_linear_force_with_custom_profile() -> void:
	var model := FlightModel.new()
	var parameters := FlightParameters.new()
	var profile := FlightControlProfile.new()
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
	var command := PilotCommand.new()
	command.pitch = 1.0
	command.yaw = -0.5
	command.roll = 0.75
	var demanded := model.calculate(
		parameters,
		command,
		Basis.IDENTITY,
		Vector3(0.0, 0.0, -80.0),
		Vector3.ZERO,
		AIR_DENSITY,
		GRAVITY,
		profile
	)
	TestAssert.is_near(demanded.force_world.distance_to(neutral.force_world), 0.0, 0.001)


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


func test_non_finite_motion_inputs_cannot_poison_force_output() -> void:
	var result := FlightModel.new().calculate(
		FlightParameters.new(),
		PilotCommand.new(),
		Basis.IDENTITY,
		Vector3(NAN, INF, -INF),
		Vector3(NAN, INF, -INF),
		INF,
		Vector3(NAN, -INF, INF)
	)
	for component in [
		result.force_world.x,
		result.force_world.y,
		result.force_world.z,
		result.torque_world.x,
		result.torque_world.y,
		result.torque_world.z,
	]:
		TestAssert.is_true(is_finite(component))


func test_rate_controller_converges_and_releases_deterministically() -> void:
	var first := _simulate_rate_command()
	var second := _simulate_rate_command()
	TestAssert.is_near(first.distance_to(second), 0.0, 0.000001)
	TestAssert.is_true(absf(first.x) < 0.05)


func _simulate_rate_command() -> Vector3:
	var model := FlightModel.new()
	var profile := FlightControlProfile.new()
	var command := PilotCommand.new()
	command.pitch = 0.8
	var angular_velocity := Vector3.ZERO
	var inverse_inertia := 1.0 / 6000.0
	var delta := 1.0 / 120.0
	for _step in range(120):
		angular_velocity += model.calculate_rate_torque_world(
			profile, command, Basis.IDENTITY, angular_velocity
		) * inverse_inertia * delta
	command.pitch = 0.0
	for _step in range(120):
		angular_velocity += model.calculate_rate_torque_world(
			profile, command, Basis.IDENTITY, angular_velocity
		) * inverse_inertia * delta
	return angular_velocity


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
