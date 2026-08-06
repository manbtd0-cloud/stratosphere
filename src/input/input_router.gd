class_name InputRouter
extends Node


const InputProfileType = preload("res://src/input/input_profile.gd")

var profile: InputProfile = InputProfileType.new()
var _steering := 0.0
var _throttle := 0.0
var _brake := 0.0


func _init() -> void:
	_ensure_input_actions()


func _physics_process(delta: float) -> void:
	var steer_axis := Input.get_axis("drive_steer_left", "drive_steer_right")
	var throttle_pressed := Input.is_action_pressed("drive_throttle")
	var brake_pressed := Input.is_action_pressed("drive_brake")
	sample_keyboard(delta, steer_axis, throttle_pressed, brake_pressed)


func sample_keyboard(
	delta: float,
	steer_axis: float,
	throttle_pressed: bool,
	brake_pressed: bool
) -> void:
	var active_profile := profile.sanitized_copy()
	var target_steering := clampf(steer_axis, -1.0, 1.0)
	var steering_rate := active_profile.keyboard_steering_rise
	if absf(target_steering) < absf(_steering):
		steering_rate = active_profile.keyboard_steering_fall
	_steering = move_toward(_steering, target_steering, steering_rate * maxf(delta, 0.0))
	_throttle = move_toward(
		_throttle,
		1.0 if throttle_pressed else 0.0,
		active_profile.keyboard_throttle_rise * maxf(delta, 0.0)
	)
	_brake = move_toward(
		_brake,
		1.0 if brake_pressed else 0.0,
		active_profile.keyboard_brake_rise * maxf(delta, 0.0)
	)


func get_steering() -> float:
	return _steering


func get_throttle() -> float:
	return _throttle


func get_brake() -> float:
	return _brake


func shift_up_pressed() -> bool:
	return Input.is_action_just_pressed("drive_shift_up")


func shift_down_pressed() -> bool:
	return Input.is_action_just_pressed("drive_shift_down")


func _ensure_input_actions() -> void:
	_add_key_action(&"drive_steer_left", KEY_A)
	_add_key_action(&"drive_steer_right", KEY_D)
	_add_key_action(&"drive_throttle", KEY_W)
	_add_key_action(&"drive_brake", KEY_S)
	_add_key_action(&"drive_handbrake", KEY_SPACE)
	_add_key_action(&"drive_shift_up", KEY_E)
	_add_key_action(&"drive_shift_down", KEY_Q)
	_add_key_action(&"drive_reset", KEY_R)
	_add_key_action(&"camera_next", KEY_C)
	_add_key_action(&"pause", KEY_ESCAPE)


func _add_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)
