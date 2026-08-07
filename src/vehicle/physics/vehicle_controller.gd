class_name VehicleController
extends RigidBody3D

@export var definition: VehicleDefinition = VehicleDefinition.new()
@export var automatic_transmission := true
@export var driver_enabled := true
@export var debug_force_override := false
@export var debug_throttle := 0.0
@export var debug_brake := 0.0
@export var debug_steer := 0.0
@export var debug_clutch := 0.0
@export var debug_handbrake := 0.0

const IDS := ["fl", "fr", "rl", "rr"]
const FRONT := ["fl", "fr"]
const REAR := ["rl", "rr"]
const WHEEL_DYNAMICS_HZ := 480.0

var wheel_omega := {"fl": 0.0, "fr": 0.0, "rl": 0.0, "rr": 0.0}
var wheel_force_x := {"fl": 0.0, "fr": 0.0, "rl": 0.0, "rr": 0.0}
var wheel_force_y := {"fl": 0.0, "fr": 0.0, "rl": 0.0, "rr": 0.0}
var abs_factor := {"fl": 1.0, "fr": 1.0, "rl": 1.0, "rr": 1.0}
var tcs_factor := 1.0
var current_gear := 1
var requested_gear := 1
var shift_timer := 0.0
var engine_rpm := 850.0
var elapsed := 0.0
var last_telemetry: Dictionary = {}
var spawn_transform: Transform3D
var damage_state := DamageState.new()
var _last_velocity := Vector3.ZERO
var _contact_impulse := 0.0

func _ready() -> void:
	mass = definition.body.mass_kg
	linear_damp = 0.0
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	angular_damp = 0.0
	angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	can_sleep = false
	contact_monitor = true
	max_contacts_reported = 16
	spawn_transform = global_transform

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_contact_impulse = 0.0
	for i in range(state.get_contact_count()):
		_contact_impulse = maxf(_contact_impulse, state.get_contact_impulse(i).length())
	if _contact_impulse > definition.damage.minor_impulse:
		damage_state.apply_impulse(_contact_impulse, definition.damage)

func _physics_process(delta: float) -> void:
	elapsed += delta
	var input = get_node_or_null("/root/DriveInput")
	var throttle := debug_throttle if debug_force_override else (float(input.get_throttle()) if driver_enabled and input != null else 0.0)
	var brake := debug_brake if debug_force_override else (float(input.get_brake()) if driver_enabled and input != null else 0.0)
	var steer := debug_steer if debug_force_override else (float(input.get_steering()) if driver_enabled and input != null else 0.0)
	var clutch_pedal := debug_clutch if debug_force_override else (float(input.get_clutch()) if driver_enabled and input != null else 0.0)
	var handbrake := debug_handbrake if debug_force_override else (float(input.get_handbrake()) if driver_enabled and input != null else 0.0)
	if not debug_force_override and driver_enabled and input != null:
		if input.shift_up_pressed():
			request_gear(current_gear + 1)
		if input.shift_down_pressed():
			request_gear(current_gear - 1)
		if input.reset_pressed():
			reset_vehicle()

	_update_shift(delta, throttle)
	var speed := linear_velocity.length()
	var local_v := global_basis.inverse() * linear_velocity
	var sideslip := atan2(local_v.x, maxf(absf(-local_v.z), 1.0))
	var effective_steer := steer
	if definition.assists.countersteer_enabled:
		effective_steer = AssistSolver.countersteer(steer, sideslip, definition.assists)
	var max_angle := deg_to_rad(30.0) * clampf(1.0 - speed / 65.0, 0.35, 1.0)
	var steer_angle := clampf(effective_steer, -1.0, 1.0) * max_angle + damage_state.steering_offset
	var target_yaw := (-local_v.z / maxf(definition.body.wheelbase, 0.1)) * tan(steer_angle)
	var stability: Dictionary = {"torque_cut": 0.0, "brake_left": 0.0, "brake_right": 0.0}
	if definition.assists.stability_enabled:
		stability = AssistSolver.stability(angular_velocity.y, target_yaw, definition.assists)

	var clutch := ClutchSolver.engagement(clutch_pedal, automatic_transmission, engine_rpm, definition.engine.idle_rpm)
	if automatic_transmission and throttle > 0.05:
		clutch = maxf(clutch, lerpf(0.45, 0.90, throttle))
	var ratio := TransmissionSolver.ratio(definition.transmission, current_gear)
	var driven_avg := (absf(float(wheel_omega["rl"])) + absf(float(wheel_omega["rr"]))) * 0.5
	var coupled_rpm := definition.engine.idle_rpm
	if absf(ratio) > 0.001:
		coupled_rpm = driven_avg * absf(ratio) * 60.0 / TAU
	var target_rpm := maxf(definition.engine.idle_rpm, coupled_rpm)
	engine_rpm = move_toward(engine_rpm, target_rpm, maxf(2200.0, absf(target_rpm - engine_rpm) * 4.0) * delta)
	engine_rpm = clampf(engine_rpm, definition.engine.idle_rpm, definition.engine.limiter_rpm)
	var engine_torque := EngineSolver.requested_torque(definition.engine, engine_rpm, throttle)
	engine_torque *= damage_state.power_multiplier * (1.0 - float(stability["torque_cut"]))
	var transmitted := ClutchSolver.transmit(engine_torque, clutch, 320.0)
	var axle_torque := transmitted * ratio * 0.90 if shift_timer <= 0.0 else 0.0
	if throttle < 0.02 and speed < 1.0:
		axle_torque = 0.0
	var split := DifferentialSolver.split(axle_torque, float(wheel_omega["rl"]), float(wheel_omega["rr"]), definition.differential)

	var contacts: Dictionary = {}
	for id in IDS:
		contacts[id] = _sample_wheel(id, steer_angle if id in FRONT else 0.0)
	_apply_anti_roll(contacts)
	var rear_slip := maxf(float(contacts["rl"].get("slip_ratio", 0.0)), float(contacts["rr"].get("slip_ratio", 0.0)))
	if definition.assists.tcs_enabled and throttle > 0.05:
		tcs_factor = AssistSolver.tcs_factor(tcs_factor, rear_slip, definition.assists, delta)
	else:
		tcs_factor = move_toward(tcs_factor, 1.0, definition.assists.tcs_recovery_rate * delta)
	split *= tcs_factor
	_simulate_wheels(contacts, split, brake, handbrake, stability, delta)
	_apply_aero_and_resistance(contacts)
	_build_telemetry(contacts, throttle, brake, clutch_pedal, handbrake, steer_angle, stability, delta)
	_last_velocity = linear_velocity

func _wheel_anchor(id: String) -> Node3D:
	return get_node("WheelAnchors/Wheel%s" % id.to_upper()) as Node3D

func _sample_wheel(id: String, steer_angle: float) -> Dictionary:
	var anchor := _wheel_anchor(id)
	var up := global_basis.y.normalized()
	var forward := (-global_basis.z).rotated(up, steer_angle).normalized()
	var lateral := up.cross(forward).normalized()
	var max_dist := definition.suspension.rest_length + definition.suspension.max_droop + definition.wheel_radius
	var offsets: Array[float] = [0.0, -definition.wheel_radius * 0.38, definition.wheel_radius * 0.38]
	var hits: Array[Dictionary] = []
	for off in offsets:
		var start := anchor.global_position + lateral * off + up * 0.04
		var end := start - up * (max_dist + 0.08)
		var query := PhysicsRayQueryParameters3D.create(start, end)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			hits.append(hit)
	if hits.is_empty():
		return {"grounded": false, "normal_load": 0.0, "slip_ratio": 0.0, "slip_angle": 0.0, "surface": &"air", "compression": 0.0, "forward": forward, "lateral": lateral, "point": anchor.global_position - up * max_dist}
	var best: Dictionary = hits[0]
	var distance := anchor.global_position.distance_to(best["position"])
	var susp_len := clampf(distance - definition.wheel_radius, 0.0, definition.suspension.rest_length + definition.suspension.max_droop)
	var compression := clampf(definition.suspension.rest_length - susp_len, 0.0, definition.suspension.max_compression)
	var arm: Vector3 = best["position"] - global_position
	var point_vel := linear_velocity + angular_velocity.cross(arm)
	var fwd_speed := point_vel.dot(forward)
	var lat_speed := point_vel.dot(lateral)
	var slip := (float(wheel_omega[id]) * definition.wheel_radius - fwd_speed) / maxf(absf(fwd_speed), 2.0)
	var slip_angle := atan2(lat_speed, maxf(absf(fwd_speed), 2.0))
	var surface_id: StringName = &"asphalt_dry"
	var collider: Object = best.get("collider")
	if collider != null and collider.has_meta("surface_id"):
		surface_id = StringName(collider.get_meta("surface_id"))
	var surface := SurfaceConfig.for_id(surface_id)
	var normal_vel := point_vel.dot(up)
	var load := SuspensionSolver.force(definition.suspension, compression, normal_vel)
	return {"grounded": true, "normal_load": load, "slip_ratio": slip, "slip_angle": slip_angle, "surface": surface_id, "surface_config": surface, "compression": compression, "forward": forward, "lateral": lateral, "point": best["position"], "normal": best["normal"], "fwd_speed": fwd_speed, "lat_speed": lat_speed}

func _apply_anti_roll(contacts: Dictionary) -> void:
	for pair in [["fl", "fr", definition.suspension.anti_roll_front], ["rl", "rr", definition.suspension.anti_roll_rear]]:
		var left: Dictionary = contacts[pair[0]]
		var right: Dictionary = contacts[pair[1]]
		if not left["grounded"] or not right["grounded"]:
			continue
		var ar := SuspensionSolver.anti_roll(float(pair[2]), float(left["compression"]), float(right["compression"]))
		left["normal_load"] = maxf(0.0, float(left["normal_load"]) + ar.x)
		right["normal_load"] = maxf(0.0, float(right["normal_load"]) + ar.y)

func _simulate_wheels(contacts: Dictionary, drive_split: Vector2, brake: float, handbrake: float, stability: Dictionary, delta: float) -> void:
	var substeps := maxi(1, int(ceil(delta * WHEEL_DYNAMICS_HZ)))
	var dt := delta / float(substeps)
	for _step in range(substeps):
		for id in IDS:
			var contact: Dictionary = contacts[id]
			if not contact["grounded"]:
				wheel_omega[id] = float(wheel_omega[id]) * 0.999
				continue
			var drive := drive_split.x if id == "rl" else (drive_split.y if id == "rr" else 0.0)
			var front: bool = id in FRONT
			var brake_torque := BrakeSolver.axle_torque(definition.brakes, brake, front) * 0.5
			if id in REAR:
				brake_torque += definition.brakes.handbrake_torque * handbrake
			if definition.assists.abs_enabled and brake > 0.01 and handbrake < 0.01:
				abs_factor[id] = BrakeSolver.abs_factor(definition.brakes, float(contact["slip_ratio"]), float(abs_factor[id]), dt)
			else:
				abs_factor[id] = move_toward(float(abs_factor[id]), 1.0, 8.0 * dt)
			brake_torque *= float(abs_factor[id])
			if id in FRONT:
				brake_torque += definition.brakes.max_brake_torque * 0.5 * (float(stability["brake_left"]) if id == "fl" else float(stability["brake_right"]))
			if absf(drive) < 0.01 and brake_torque < 0.01:
				wheel_omega[id] = float(contact["fwd_speed"]) / definition.wheel_radius
				wheel_force_x[id] = TireForceSolver.relax(float(wheel_force_x[id]), 0.0, float(contact["fwd_speed"]), definition.tire.longitudinal_relaxation_length, dt)
			else:
				var surface: SurfaceConfig = contact["surface_config"]
				var dynamic_slip := (float(wheel_omega[id]) * definition.wheel_radius - float(contact["fwd_speed"])) / maxf(absf(float(contact["fwd_speed"])), 2.0)
				contact["slip_ratio"] = dynamic_slip
				var tire := TireForceSolver.calculate(definition.tire, float(contact["normal_load"]), dynamic_slip, float(contact["slip_angle"]), surface)
				var target_fx := float(tire["longitudinal"]) * damage_state.grip_multiplier
				var target_fy := float(tire["lateral"]) * damage_state.grip_multiplier
				wheel_force_x[id] = TireForceSolver.relax(float(wheel_force_x[id]), target_fx, float(contact["fwd_speed"]), definition.tire.longitudinal_relaxation_length, dt)
				wheel_force_y[id] = TireForceSolver.relax(float(wheel_force_y[id]), target_fy, float(contact["fwd_speed"]), definition.tire.lateral_relaxation_length, dt)
				var effective_drive := drive
				if definition.assists.tcs_enabled and id in REAR and effective_drive > 0.0 and dynamic_slip > definition.assists.tcs_target_slip:
					effective_drive *= clampf(definition.assists.tcs_target_slip / maxf(dynamic_slip, 0.001), 0.35, 1.0)
				var reaction := -float(wheel_force_x[id]) * definition.wheel_radius
				var brake_reaction := 0.0
				if absf(float(wheel_omega[id])) > 0.2:
					brake_reaction = brake_torque * signf(float(wheel_omega[id]))
				elif absf(drive + reaction) > 0.01:
					brake_reaction = minf(brake_torque, absf(drive + reaction)) * signf(drive + reaction)
				var torque := effective_drive + reaction - brake_reaction
				wheel_omega[id] = float(wheel_omega[id]) + torque / 1.15 * dt
	for id in IDS:
		var contact: Dictionary = contacts[id]
		if not contact["grounded"]:
			continue
		var suspension_force := Vector3(contact["normal"]) * float(contact["normal_load"])
		apply_force(suspension_force, Vector3(contact["point"]) - global_position)
		var tire_force := Vector3(contact["forward"]) * float(wheel_force_x[id]) + Vector3(contact["lateral"]) * float(wheel_force_y[id])
		apply_force(tire_force, Vector3(contact["point"]) - global_position)

func _apply_aero_and_resistance(contacts: Dictionary) -> void:
	var velocity := linear_velocity
	if velocity.length() > 0.05:
		var drag := 0.5 * definition.aero.air_density * definition.body.drag_coefficient * definition.body.frontal_area * velocity.length_squared() * damage_state.drag_multiplier
		apply_central_force(-velocity.normalized() * drag)
	for id in IDS:
		var contact: Dictionary = contacts[id]
		if not contact["grounded"]:
			continue
		var surface: SurfaceConfig = contact["surface_config"]
		var fwd_speed := float(contact["fwd_speed"])
		if absf(fwd_speed) > 0.2:
			var resistance := surface.rolling_resistance_coefficient * float(contact["normal_load"])
			apply_force(-Vector3(contact["forward"]) * signf(fwd_speed) * resistance, Vector3(contact["point"]) - global_position)

func _update_shift(delta: float, throttle: float) -> void:
	if shift_timer > 0.0:
		shift_timer = maxf(0.0, shift_timer - delta)
		if shift_timer <= 0.0:
			current_gear = requested_gear
		return
	if automatic_transmission and current_gear > 0:
		var road_speed := maxf(0.0, (-global_basis.z).dot(linear_velocity))
		var road_rpm := road_speed / definition.wheel_radius * absf(TransmissionSolver.ratio(definition.transmission, current_gear)) * 60.0 / TAU
		var next_gear := TransmissionSolver.automatic_gear(definition.transmission, current_gear, road_rpm, throttle)
		if next_gear != current_gear:
			request_gear(next_gear)

func request_gear(gear: int) -> void:
	gear = clampi(gear, -1, definition.transmission.forward_ratios.size())
	if gear == current_gear or shift_timer > 0.0:
		return
	requested_gear = gear
	shift_timer = definition.transmission.shift_delay

func set_gear_immediate(gear: int) -> void:
	current_gear = clampi(gear, -1, definition.transmission.forward_ratios.size())
	requested_gear = current_gear
	shift_timer = 0.0

func apply_damage_impulse(impulse: float) -> void:
	damage_state.apply_impulse(impulse, definition.damage)

func repair() -> void:
	damage_state.repair()

func reset_vehicle() -> void:
	global_transform = spawn_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	for id in IDS:
		wheel_omega[id] = 0.0
		wheel_force_x[id] = 0.0
		wheel_force_y[id] = 0.0
	reset_physics_interpolation()

func get_telemetry_snapshot() -> Dictionary:
	return last_telemetry.duplicate(true)

func _build_telemetry(contacts: Dictionary, throttle: float, brake: float, clutch: float, handbrake: float, steer_angle: float, stability: Dictionary, delta: float) -> void:
	var wheels := {}
	for id in IDS:
		var d: Dictionary = contacts[id]
		var surface := SurfaceConfig.for_id(StringName(d.get("surface", &"air")))
		var tire := TireForceSolver.calculate(definition.tire, float(d.get("normal_load", 0.0)), float(d.get("slip_ratio", 0.0)), float(d.get("slip_angle", 0.0)), surface)
		wheels[id] = {"grounded": d.get("grounded", false), "rpm": float(wheel_omega[id]) * 60.0 / TAU, "slip_ratio": d.get("slip_ratio", 0.0), "slip_angle": d.get("slip_angle", 0.0), "normal_load": d.get("normal_load", 0.0), "compression": d.get("compression", 0.0), "longitudinal_force": wheel_force_x[id], "lateral_force": wheel_force_y[id], "surface": d.get("surface", &"air"), "abs_factor": abs_factor[id], "aligning_torque": tire["aligning_torque"], "rolling_resistance": tire["rolling_resistance"], "slip_energy": tire["slip_energy"], "grip_utilization": tire["utilization"], "visual_y": -float(d.get("compression", 0.0))}
	last_telemetry = {"time": elapsed, "world_velocity": linear_velocity, "local_velocity": global_basis.inverse() * linear_velocity, "speed_mps": linear_velocity.length(), "acceleration": (linear_velocity - _last_velocity) / maxf(delta, 0.0001), "angular_velocity": angular_velocity, "steering_angle_rad": steer_angle, "throttle": throttle, "brake": brake, "clutch": clutch, "handbrake": handbrake, "gear": current_gear, "engine_rpm": engine_rpm, "engine_torque": EngineSolver.requested_torque(definition.engine, engine_rpm, throttle), "tcs_factor": tcs_factor, "stability": stability, "damage": {"severity": damage_state.severity, "power_multiplier": damage_state.power_multiplier, "grip_multiplier": damage_state.grip_multiplier, "drag_multiplier": damage_state.drag_multiplier}, "body_contact_impulse": _contact_impulse, "wheels": wheels}
