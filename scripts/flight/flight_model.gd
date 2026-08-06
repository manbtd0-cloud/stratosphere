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
	gravity_world: Vector3,
	control_profile: FlightControlProfile = null
) -> FlightForceResult:
	var clean := command.sanitized() if command != null else PilotCommand.new()
	var safe_profile := (
		control_profile if control_profile != null else FlightControlProfile.new()
	)
	var orientation := basis.orthonormalized()
	var up := orientation.y.normalized()
	var forward := -orientation.z.normalized()
	var safe_linear_velocity := _finite_vector_or_zero(linear_velocity_world)
	var safe_gravity := _finite_vector_or_zero(gravity_world)
	var safe_air_density := (
		maxf(air_density_kg_m3, 0.0) if is_finite(air_density_kg_m3) else 0.0
	)

	var thrust_direction := up
	if clean.transition >= 1.0:
		thrust_direction = forward
	elif clean.transition > 0.0:
		thrust_direction = up.slerp(forward, clean.transition).normalized()

	var available_thrust := lerpf(
		parameters.hover_thrust_newtons,
		parameters.forward_thrust_newtons,
		clean.transition
	)
	var primary_thrust_magnitude := available_thrust * clean.collective
	var primary_thrust := thrust_direction * primary_thrust_magnitude
	var local_translation := Vector3(clean.strafe.x, clean.strafe.y, -clean.strafe.z)
	var lateral_thrust := (
		orientation
		* local_translation
		* parameters.lateral_thrust_newtons
	)
	var thrust_force := primary_thrust + lateral_thrust

	var speed := safe_linear_velocity.length()
	var drag_force := Vector3.ZERO
	var drag_magnitude := 0.0
	if speed > MIN_SPEED_MPS:
		var forward_speed := maxf(safe_linear_velocity.dot(forward), 0.0)
		var maximum_speed := maxf(parameters.max_forward_speed_mps, 1.0)
		var overspeed_ratio := maxf(forward_speed - maximum_speed, 0.0) / maximum_speed
		var overspeed_multiplier := 1.0 + overspeed_ratio * overspeed_ratio * 6.0
		var brake_multiplier := 1.0 + clean.brake * 2.0
		drag_magnitude = (
			0.5
			* safe_air_density
			* speed
			* speed
			* parameters.drag_coefficient
			* parameters.reference_area_m2
			* overspeed_multiplier
			* brake_multiplier
		)
		drag_force = -safe_linear_velocity.normalized() * drag_magnitude

	var forward_air_speed := maxf(safe_linear_velocity.dot(forward), 0.0)
	var lift_magnitude := (
		0.5
		* safe_air_density
		* forward_air_speed
		* forward_air_speed
		* parameters.lift_coefficient
		* parameters.reference_area_m2
		* clean.transition
	)
	var lift_force := up * lift_magnitude
	var gravity_force := safe_gravity * parameters.mass_kg
	var command_torque_world := calculate_rate_torque_world(
		safe_profile,
		clean,
		orientation,
		angular_velocity_world
	)

	var result := FlightForceResult.new()
	result.thrust_force_world = thrust_force
	result.drag_force_world = drag_force
	result.lift_force_world = lift_force
	result.gravity_force_world = gravity_force
	result.force_world = thrust_force + drag_force + lift_force + gravity_force
	result.torque_world = command_torque_world
	result.thrust_newtons = primary_thrust_magnitude + lateral_thrust.length()
	result.drag_newtons = drag_magnitude
	result.lift_newtons = lift_magnitude
	return result


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
