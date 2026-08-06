class_name InputProfile
extends Resource


@export_range(0.1, 20.0, 0.1) var keyboard_steering_rise: float = 5.0
@export_range(0.1, 20.0, 0.1) var keyboard_steering_fall: float = 7.0
@export_range(0.1, 20.0, 0.1) var keyboard_throttle_rise: float = 4.0
@export_range(0.1, 20.0, 0.1) var keyboard_brake_rise: float = 6.0
@export_range(0.0, 0.45, 0.01) var controller_steering_deadzone: float = 0.12
@export_range(0.1, 3.0, 0.05) var steering_sensitivity: float = 1.0
@export_range(0.1, 3.0, 0.05) var throttle_sensitivity: float = 1.0
@export_range(0.1, 3.0, 0.05) var brake_sensitivity: float = 1.0


func sanitized_copy() -> InputProfile:
	var result := InputProfile.new()
	result.keyboard_steering_rise = clampf(keyboard_steering_rise, 0.1, 20.0)
	result.keyboard_steering_fall = clampf(keyboard_steering_fall, 0.1, 20.0)
	result.keyboard_throttle_rise = clampf(keyboard_throttle_rise, 0.1, 20.0)
	result.keyboard_brake_rise = clampf(keyboard_brake_rise, 0.1, 20.0)
	result.controller_steering_deadzone = clampf(controller_steering_deadzone, 0.0, 0.45)
	result.steering_sensitivity = clampf(steering_sensitivity, 0.1, 3.0)
	result.throttle_sensitivity = clampf(throttle_sensitivity, 0.1, 3.0)
	result.brake_sensitivity = clampf(brake_sensitivity, 0.1, 3.0)
	return result
