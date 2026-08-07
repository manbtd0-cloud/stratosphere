class_name InputRouter
extends Node

const InputProfileType = preload("res://src/input/input_profile.gd")
const PAD_STEER_LEFT := &"_pad_drive_steer_left"
const PAD_STEER_RIGHT := &"_pad_drive_steer_right"
const PAD_THROTTLE := &"_pad_drive_throttle"
const PAD_BRAKE := &"_pad_drive_brake"

var profile: InputProfile = InputProfileType.new()
var _steering := 0.0
var _throttle := 0.0
var _brake := 0.0
var _clutch := 0.0

func _init() -> void:
	_ensure_input_actions()

func _physics_process(delta: float) -> void:
	var keyboard_steer := float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	var keyboard_throttle := Input.is_physical_key_pressed(KEY_W)
	var keyboard_brake := Input.is_physical_key_pressed(KEY_S)
	var keyboard_active := absf(keyboard_steer) > 0.001 or keyboard_throttle or keyboard_brake
	if keyboard_active or Input.get_connected_joypads().is_empty():
		sample_keyboard(delta, keyboard_steer, keyboard_throttle, keyboard_brake)
	else:
		sample_analog(
			delta,
			Input.get_axis(PAD_STEER_LEFT, PAD_STEER_RIGHT),
			Input.get_action_strength(PAD_THROTTLE),
			Input.get_action_strength(PAD_BRAKE)
		)
	_clutch = 1.0 if Input.is_action_pressed("drive_clutch") else 0.0

func sample_keyboard(delta: float, steer_axis: float, throttle_pressed: bool, brake_pressed: bool) -> void:
	var active_profile := profile.sanitized_copy()
	var target_steering := clampf(steer_axis, -1.0, 1.0)
	var steering_rate := active_profile.keyboard_steering_rise
	if absf(target_steering) < absf(_steering):
		steering_rate = active_profile.keyboard_steering_fall
	_steering = move_toward(_steering, target_steering, steering_rate * maxf(delta, 0.0))
	_throttle = move_toward(_throttle, 1.0 if throttle_pressed else 0.0, active_profile.keyboard_throttle_rise * maxf(delta, 0.0))
	_brake = move_toward(_brake, 1.0 if brake_pressed else 0.0, active_profile.keyboard_brake_rise * maxf(delta, 0.0))

func sample_analog(_delta: float, steer_axis: float, throttle_strength: float, brake_strength: float) -> void:
	var active_profile := profile.sanitized_copy()
	_steering = _shape_signed_axis(steer_axis, active_profile.controller_steering_deadzone, active_profile.steering_sensitivity)
	_throttle = pow(clampf(throttle_strength, 0.0, 1.0), active_profile.throttle_sensitivity)
	_brake = pow(clampf(brake_strength, 0.0, 1.0), active_profile.brake_sensitivity)

func _shape_signed_axis(value: float, deadzone: float, sensitivity: float) -> float:
	var magnitude := absf(clampf(value, -1.0, 1.0))
	if magnitude <= deadzone:
		return 0.0
	var normalized := (magnitude - deadzone) / maxf(1.0 - deadzone, 0.001)
	return signf(value) * pow(clampf(normalized, 0.0, 1.0), sensitivity)

func get_steering() -> float:
	return _steering
func get_throttle() -> float:
	return _throttle
func get_brake() -> float:
	return _brake
func get_clutch() -> float:
	return _clutch
func get_handbrake() -> float:
	return 1.0 if Input.is_action_pressed("drive_handbrake") else 0.0
func shift_up_pressed() -> bool:
	return Input.is_action_just_pressed("drive_shift_up")
func shift_down_pressed() -> bool:
	return Input.is_action_just_pressed("drive_shift_down")
func reset_pressed() -> bool:
	return Input.is_action_just_pressed("drive_reset")
func camera_next_pressed() -> bool:
	return Input.is_action_just_pressed("camera_next")

func _ensure_input_actions() -> void:
	_add_key_action(&"drive_steer_left", KEY_A)
	_add_key_action(&"drive_steer_right", KEY_D)
	_add_key_action(&"drive_throttle", KEY_W)
	_add_key_action(&"drive_brake", KEY_S)
	_add_key_action(&"drive_clutch", KEY_X)
	_add_key_action(&"drive_handbrake", KEY_SPACE)
	_add_key_action(&"drive_shift_up", KEY_E)
	_add_key_action(&"drive_shift_down", KEY_Q)
	_add_key_action(&"drive_reset", KEY_R)
	_add_key_action(&"camera_next", KEY_C)
	_add_key_action(&"pause", KEY_ESCAPE)

	_add_joy_motion_action(&"drive_steer_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_motion_action(&"drive_steer_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_motion_action(&"drive_throttle", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_joy_motion_action(&"drive_brake", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_add_joy_button_action(&"drive_handbrake", JOY_BUTTON_A)
	_add_joy_button_action(&"drive_shift_down", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_button_action(&"drive_shift_up", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_button_action(&"drive_clutch", JOY_BUTTON_X)
	_add_joy_button_action(&"camera_next", JOY_BUTTON_Y)

	_add_joy_motion_action(PAD_STEER_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_add_joy_motion_action(PAD_STEER_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_add_joy_motion_action(PAD_THROTTLE, JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_joy_motion_action(PAD_BRAKE, JOY_AXIS_TRIGGER_LEFT, 1.0)

func _add_key_action(action: StringName, keycode: Key) -> void:
	_ensure_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey and existing.physical_keycode == keycode:
			return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func _add_joy_motion_action(action: StringName, axis: JoyAxis, axis_value: float) -> void:
	_ensure_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadMotion and existing.axis == axis and is_equal_approx(existing.axis_value, axis_value):
			return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)

func _add_joy_button_action(action: StringName, button: JoyButton) -> void:
	_ensure_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadButton and existing.button_index == button:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.0)
