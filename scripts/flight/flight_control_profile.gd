class_name FlightControlProfile
extends Resource

@export_range(100.0, 4000.0, 1.0) var full_pitch_mouse_speed_px_s: float = 950.0
@export_range(100.0, 4000.0, 1.0) var full_yaw_mouse_speed_px_s: float = 1050.0
@export var invert_pitch: bool = false
@export var invert_yaw: bool = false
@export_range(0.25, 3.0, 0.05) var mouse_response_exponent: float = 1.35
@export_range(0.1, 40.0, 0.1) var pitch_attack_response: float = 11.0
@export_range(0.1, 40.0, 0.1) var pitch_release_response: float = 7.5
@export_range(0.1, 40.0, 0.1) var yaw_attack_response: float = 10.0
@export_range(0.1, 40.0, 0.1) var yaw_release_response: float = 7.0
@export_range(0.1, 40.0, 0.1) var roll_attack_response: float = 6.5
@export_range(0.1, 40.0, 0.1) var roll_release_response: float = 8.0

@export var hover_max_rate_degrees := Vector3(65.0, 52.0, 78.0)
@export var forward_max_rate_degrees := Vector3(95.0, 28.0, 125.0)
@export var rate_gain_newton_meters_per_rad_s := Vector3(210000.0, 160000.0, 240000.0)
@export var max_torque_newton_meters := Vector3(220000.0, 180000.0, 260000.0)

@export_range(0.0, 1.0, 0.001) var nominal_hover_collective: float = 0.74
@export_range(0.0, 0.2, 0.001) var hover_detent_window: float = 0.035
@export_range(0.0, 2.0, 0.01) var hover_detent_pull_per_second: float = 0.18
@export_range(0.0, 2.0, 0.01) var collective_rate_per_second: float = 0.48
@export_range(0.0, 2.0, 0.01) var transition_input_rate_per_second: float = 0.55
@export_range(0.1, 40.0, 0.1) var transition_follow_response: float = 10.0

@export_range(0.1, 40.0, 0.1) var chase_position_response: float = 7.0
@export_range(0.1, 40.0, 0.1) var chase_rotation_response: float = 9.0
@export_range(0.0, 1.0, 0.01) var chase_roll_follow_amount: float = 0.38
@export_range(0.0, 2.0, 0.01) var chase_lookahead_seconds: float = 0.28
@export_range(0.0, 80.0, 0.1) var chase_max_lookahead_meters: float = 28.0
@export_range(50.0, 120.0, 0.1) var min_chase_fov_degrees: float = 76.0
@export_range(50.0, 120.0, 0.1) var max_chase_fov_degrees: float = 92.0
@export_range(1.0, 500.0, 1.0) var chase_fov_full_speed_mps: float = 210.0
@export_range(0.1, 40.0, 0.1) var chase_fov_response: float = 5.0


func shaped_axis(value: float) -> float:
	var bounded := clampf(_finite_or(value, 0.0), -1.0, 1.0)
	var exponent := clampf(_finite_or(mouse_response_exponent, 1.0), 0.25, 3.0)
	return signf(bounded) * pow(absf(bounded), exponent)


func blended_max_rate_radians(transition: float) -> Vector3:
	var weight := clampf(_finite_or(transition, 0.0), 0.0, 1.0)
	var hover := _safe_positive_vector(
		hover_max_rate_degrees,
		Vector3(65.0, 52.0, 78.0)
	)
	var forward := _safe_positive_vector(
		forward_max_rate_degrees,
		Vector3(95.0, 28.0, 125.0)
	)
	var degrees := hover.lerp(forward, weight)
	return Vector3(
		deg_to_rad(degrees.x),
		deg_to_rad(degrees.y),
		deg_to_rad(degrees.z)
	)


func safe_rate_gain() -> Vector3:
	return _safe_positive_vector(
		rate_gain_newton_meters_per_rad_s,
		Vector3(210000.0, 160000.0, 240000.0)
	)


func safe_max_torque() -> Vector3:
	return _safe_positive_vector(
		max_torque_newton_meters,
		Vector3(220000.0, 180000.0, 260000.0)
	)


func _safe_positive_vector(value: Vector3, fallback: Vector3) -> Vector3:
	return Vector3(
		maxf(_finite_or(value.x, fallback.x), 0.0),
		maxf(_finite_or(value.y, fallback.y), 0.0),
		maxf(_finite_or(value.z, fallback.z), 0.0)
	)


func _finite_or(value: float, fallback: float) -> float:
	return value if is_finite(value) else fallback
