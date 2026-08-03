class_name FlightModel
extends RefCounted

const MIN_SPEED_MPS: float = 0.0001


func calculate(
	parameters: FlightParameters,
	command: PilotCommand,
	basis: Basis,
	linear_velocity_world: Vector3,
	angular_velocity_world: Vector3,
	air_density_kg_m3: float,
	gravity_world: Vector3
) -> FlightForceResult:
	var clean := command.sanitized()
	var orientation := basis.orthonormalized()
	var up := orientation.y.normalized()
	var forward := -orientation.z.normalized()

	var thrust_direction := up.slerp(forward, clean.transition).normalized()
	var available_thrust := lerpf(
		parameters.hover_thrust_newtons,
		parameters.forward_thrust_newtons,
		clean.transition
	)
	var primary_thrust := thrust_direction * available_thrust * clean.collective
	var local_translation := Vector3(clean.strafe.x, clean.strafe.y, -clean.strafe.z)
	var lateral_thrust := (
		orientation
		* local_translation
		* parameters.lateral_thrust_newtons
	)
	var thrust_force := primary_thrust + lateral_thrust

	var speed := linear_velocity_world.length()
	var drag_force := Vector3.ZERO
	var drag_magnitude := 0.0
	if speed > MIN_SPEED_MPS:
		var forward_speed := maxf(linear_velocity_world.dot(forward), 0.0)
		var maximum_speed := maxf(parameters.max_forward_speed_mps, 1.0)
		var overspeed_ratio := maxf(forward_speed - maximum_speed, 0.0) / maximum_speed
		var overspeed_multiplier := 1.0 + overspeed_ratio * overspeed_ratio * 6.0
		var brake_multiplier := 1.0 + clean.brake * 2.0
		drag_magnitude = (
			0.5
			* maxf(air_density_kg_m3, 0.0)
			* speed
			* speed
			* parameters.drag_coefficient
			* parameters.reference_area_m2
			* overspeed_multiplier
			* brake_multiplier
		)
		drag_force = -linear_velocity_world.normalized() * drag_magnitude

	var forward_air_speed := maxf(linear_velocity_world.dot(forward), 0.0)
	var lift_magnitude := (
		0.5
		* maxf(air_density_kg_m3, 0.0)
		* forward_air_speed
		* forward_air_speed
		* parameters.lift_coefficient
		* parameters.reference_area_m2
		* clean.transition
	)
	var lift_force := up * lift_magnitude
	var gravity_force := gravity_world * parameters.mass_kg

	var command_torque_local := Vector3(
		clean.pitch * parameters.pitch_torque_newton_meters,
		clean.yaw * parameters.yaw_torque_newton_meters,
		-clean.roll * parameters.roll_torque_newton_meters
	)
	var command_torque_world := orientation * command_torque_local
	var stability_torque := (
		-angular_velocity_world
		* parameters.stability_strength
		* parameters.mass_kg
	)

	var result := FlightForceResult.new()
	result.thrust_force_world = thrust_force
	result.drag_force_world = drag_force
	result.lift_force_world = lift_force
	result.gravity_force_world = gravity_force
	result.force_world = thrust_force + drag_force + lift_force + gravity_force
	result.torque_world = command_torque_world + stability_torque
	result.thrust_newtons = thrust_force.length()
	result.drag_newtons = drag_magnitude
	result.lift_newtons = lift_magnitude
	return result