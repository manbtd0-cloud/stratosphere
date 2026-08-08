class_name TrafficAgent
extends RigidBody3D

var traffic_id: StringName = &""
var simulation_level: StringName = &"near"
var lead_distance_m: float = INF
var lane_blocked: bool = false

var _definition: TrafficVehicleDefinition
var _lane: TrafficLane
var _divergence_time_s: float = 0.0
var _mid_progress_m: float = 0.0
var _configured: bool = false

func configure(definition: TrafficVehicleDefinition, lane: TrafficLane) -> PackedStringArray:
	var errors := PackedStringArray()
	if definition == null:
		errors.append("traffic vehicle definition must not be null")
	else:
		for error in definition.validation_errors(): errors.append(error)
	if lane == null:
		errors.append("traffic lane must not be null")
	else:
		for error in lane.validation_errors(): errors.append(error)
	if not errors.is_empty(): return errors
	_definition = definition
	_lane = lane
	mass = definition.mass_kg
	traffic_id = StringName("agent.%s.%s" % [definition.id, lane.id])
	_configured = true
	set_simulation_level(&"near")
	return errors

func set_simulation_level(level: StringName) -> void:
	if level not in [&"near", &"mid", &"far"]:
		return
	simulation_level = level
	match level:
		&"near":
			freeze = false
			visible = true
			sleeping = false
		&"mid":
			freeze = true
			visible = true
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
		&"far":
			freeze = true
			visible = false
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO

func compute_control_state(delta: float, lead_distance: float = INF, blocked: bool = false) -> Dictionary:
	if not _configured or _lane == null or _definition == null:
		return {"throttle": 0.0, "brake": 1.0, "steer": 0.0, "recovery_requested": false, "target_speed_mps": 0.0}
	var nearest := _nearest_path_state(position)
	var nearest_distance: float = float(nearest.distance_m)
	if nearest_distance > _definition.path_divergence_recovery_m:
		_divergence_time_s += maxf(delta, 0.0)
	else:
		_divergence_time_s = 0.0
	var target_direction: Vector3 = nearest.direction
	var body_forward := -basis.z.normalized()
	var steer := clampf(body_forward.cross(target_direction).y * 2.4, -1.0, 1.0)
	var speed := linear_velocity.length()
	var target_speed := _lane.speed_limit_kph / 3.6
	var speed_error := target_speed - speed
	var throttle := clampf(speed_error / 4.0, 0.0, 1.0)
	var brake := clampf(-speed_error / 4.0, 0.0, 1.0)
	var safe_gap := 8.0 + speed * 1.25
	if lead_distance < safe_gap:
		var gap_brake := clampf((safe_gap - maxf(lead_distance, 0.0)) / maxf(safe_gap, 0.1) * 1.4, 0.0, 1.0)
		brake = maxf(brake, gap_brake)
		throttle *= 1.0 - brake
	if blocked:
		throttle = 0.0
		brake = 1.0
	return {
		"throttle": throttle,
		"brake": brake,
		"steer": steer,
		"target_speed_mps": target_speed,
		"nearest_distance_m": nearest_distance,
		"target_index": int(nearest.target_index),
		"recovery_requested": _divergence_time_s >= _definition.recovery_delay_s,
	}

func _physics_process(delta: float) -> void:
	if not _configured:
		return
	if simulation_level == &"near":
		var control := compute_control_state(delta, lead_distance_m, lane_blocked)
		var forward := -global_basis.z.normalized()
		if float(control.throttle) > 0.0:
			apply_central_force(forward * mass * _definition.max_accel_mps2 * float(control.throttle))
		if float(control.brake) > 0.0 and linear_velocity.length_squared() > 0.001:
			apply_central_force(-linear_velocity.normalized() * mass * _definition.max_brake_mps2 * float(control.brake))
		apply_torque(Vector3.UP * mass * _definition.steering_torque_per_kg * float(control.steer))
	elif simulation_level == &"mid":
		_advance_mid(delta)

func recover_to_lane() -> void:
	if not _configured or _lane.sampled_positions.is_empty(): return
	var nearest := _nearest_path_state(position)
	var index: int = int(nearest.nearest_index)
	position = _lane.sampled_positions[index] + Vector3.UP * 0.5
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_divergence_time_s = 0.0
	reset_physics_interpolation()

func lane() -> TrafficLane:
	return _lane

func definition() -> TrafficVehicleDefinition:
	return _definition

func _nearest_path_state(local_position: Vector3) -> Dictionary:
	var positions := _lane.sampled_positions
	var nearest_index := 0
	var nearest_distance_sq := INF
	for index in range(positions.size()):
		var distance_sq := local_position.distance_squared_to(positions[index])
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest_index = index
	var target_index := mini(nearest_index + 1, positions.size() - 1)
	if target_index == nearest_index and nearest_index > 0:
		target_index = nearest_index
		nearest_index -= 1
	var direction := positions[target_index] - positions[nearest_index]
	if direction.length_squared() < 0.0001:
		direction = Vector3.FORWARD
	return {
		"nearest_index": nearest_index,
		"target_index": target_index,
		"distance_m": sqrt(nearest_distance_sq),
		"direction": direction.normalized(),
	}

func _advance_mid(delta: float) -> void:
	if _lane == null or _lane.sampled_positions.size() < 2: return
	_mid_progress_m += (_lane.speed_limit_kph / 3.6) * maxf(delta, 0.0)
	var remaining := _mid_progress_m
	var positions := _lane.sampled_positions
	var total := 0.0
	for index in range(positions.size() - 1): total += positions[index].distance_to(positions[index + 1])
	if total <= 0.001: return
	remaining = fmod(remaining, total)
	for index in range(positions.size() - 1):
		var a := positions[index]
		var b := positions[index + 1]
		var length := a.distance_to(b)
		if remaining <= length:
			var t := remaining / maxf(length, 0.001)
			var direction := (b - a).normalized()
			position = a.lerp(b, t)
			basis = Basis.looking_at(direction, Vector3.UP)
			return
		remaining -= length
