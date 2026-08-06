class_name FrontierVtolController
extends RigidBody3D

signal telemetry_updated(telemetry: Dictionary)
signal crashed()
signal landed()

enum ContactOutcome {
	LANDED,
	CRASHED,
}

@export var parameters: FlightParameters = FlightParameters.new()
@export var control_profile: FlightControlProfile
@export var safe_landing_vertical_speed_mps: float = 4.0
@export var crash_impact_speed_mps: float = 12.0

var _pilot_command := PilotCommand.new()
var _atmosphere_model := AtmosphereModel.new()
var _flight_model := FlightModel.new()
var _latest_force_result := FlightForceResult.new()
var _grounded: bool = false
var _contact_reported: bool = false


func _init() -> void:
	_apply_physics_contract()


func _ready() -> void:
	_profile()
	_apply_physics_contract()


func set_pilot_command(command: PilotCommand) -> void:
	if command == null:
		_pilot_command = PilotCommand.new()
		return
	_pilot_command = command.sanitized()


func reset_to(transform_value: Transform3D) -> void:
	transform = transform_value
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = false
	_grounded = false
	_contact_reported = false
	_pilot_command = PilotCommand.new()
	_latest_force_result = FlightForceResult.new()


func get_telemetry() -> Dictionary:
	return {
		"speed_mps": linear_velocity.length(),
		"altitude_m": maxf(transform.origin.y, 0.0),
		"transition": _pilot_command.transition,
		"collective": _pilot_command.collective,
		"vertical_speed_mps": linear_velocity.y,
		"angular_velocity_local_rad_s": _local_angular_velocity(
			angular_velocity,
			transform.basis
		),
		"grounded": _grounded,
		"lift_newtons": _latest_force_result.lift_newtons,
		"drag_newtons": _latest_force_result.drag_newtons,
		"thrust_newtons": _latest_force_result.thrust_newtons,
	}


func is_grounded() -> bool:
	return _grounded


func classify_impact(impact_velocity_world: Vector3) -> ContactOutcome:
	var downward_speed := maxf(-impact_velocity_world.y, 0.0)
	if (
		downward_speed <= safe_landing_vertical_speed_mps
		and impact_velocity_world.length() <= crash_impact_speed_mps
	):
		return ContactOutcome.LANDED
	return ContactOutcome.CRASHED


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if parameters == null:
		parameters = FlightParameters.new()
		_apply_physics_contract()

	_update_contact_state(state)

	var air_density := _atmosphere_model.sample_density(state.transform.origin.y)
	_latest_force_result = _flight_model.calculate(
		parameters,
		_pilot_command,
		state.transform.basis,
		state.linear_velocity,
		state.angular_velocity,
		air_density,
		state.total_gravity,
		_profile()
	)

	state.linear_velocity += (
		_latest_force_result.force_world
		* state.inverse_mass
		* state.step
	)
	state.angular_velocity += (
		state.inverse_inertia_tensor
		* _latest_force_result.torque_world
		* state.step
	)
	state.sleeping = false

	telemetry_updated.emit(_telemetry_from_state(state))


func _apply_physics_contract() -> void:
	if parameters == null:
		parameters = FlightParameters.new()
	custom_integrator = true
	mass = maxf(parameters.mass_kg, 0.001)
	gravity_scale = 1.0
	linear_damp = 0.0
	angular_damp = 0.0
	contact_monitor = true
	max_contacts_reported = 8
	continuous_cd = true
	can_sleep = false


func _update_contact_state(state: PhysicsDirectBodyState3D) -> void:
	var has_contact := state.get_contact_count() > 0
	if has_contact and not _contact_reported:
		_contact_reported = true
		match classify_impact(state.linear_velocity):
			ContactOutcome.LANDED:
				landed.emit()
			ContactOutcome.CRASHED:
				crashed.emit()
	elif not has_contact:
		_contact_reported = false
	_grounded = has_contact


func _telemetry_from_state(state: PhysicsDirectBodyState3D) -> Dictionary:
	return {
		"speed_mps": state.linear_velocity.length(),
		"altitude_m": maxf(state.transform.origin.y, 0.0),
		"transition": _pilot_command.transition,
		"collective": _pilot_command.collective,
		"vertical_speed_mps": state.linear_velocity.y,
		"angular_velocity_local_rad_s": _local_angular_velocity(
			state.angular_velocity,
			state.transform.basis
		),
		"grounded": _grounded,
		"lift_newtons": _latest_force_result.lift_newtons,
		"drag_newtons": _latest_force_result.drag_newtons,
		"thrust_newtons": _latest_force_result.thrust_newtons,
	}


func _local_angular_velocity(world_angular_velocity: Vector3, basis: Basis) -> Vector3:
	var safe_velocity := Vector3(
		world_angular_velocity.x if is_finite(world_angular_velocity.x) else 0.0,
		world_angular_velocity.y if is_finite(world_angular_velocity.y) else 0.0,
		world_angular_velocity.z if is_finite(world_angular_velocity.z) else 0.0
	)
	return basis.orthonormalized().transposed() * safe_velocity


func _profile() -> FlightControlProfile:
	if control_profile == null:
		control_profile = FlightControlProfile.new()
	return control_profile
