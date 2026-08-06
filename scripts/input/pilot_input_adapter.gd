class_name PilotInputAdapter
extends Node

signal command_updated(command: PilotCommand)
signal camera_toggle_requested()
signal restart_requested()

const REQUIRED_ACTIONS := [
	"flight_roll_left",
	"flight_roll_right",
	"flight_collective_up",
	"flight_collective_down",
	"flight_transition_forward",
	"flight_transition_backward",
	"flight_strafe_left",
	"flight_strafe_right",
	"flight_strafe_up",
	"flight_strafe_down",
	"flight_brake",
	"flight_camera_toggle",
	"flight_restart",
	"flight_release_mouse",
]

const ACTION_KEYS := {
	"flight_roll_left": KEY_Q,
	"flight_roll_right": KEY_E,
	"flight_collective_up": KEY_SPACE,
	"flight_collective_down": KEY_CTRL,
	"flight_transition_forward": KEY_X,
	"flight_transition_backward": KEY_Z,
	"flight_strafe_left": KEY_F,
	"flight_strafe_right": KEY_H,
	"flight_strafe_up": KEY_R,
	"flight_strafe_down": KEY_V,
	"flight_brake": KEY_SHIFT,
	"flight_camera_toggle": KEY_C,
	"flight_restart": KEY_F5,
	"flight_release_mouse": KEY_ESCAPE,
}

@export var control_profile: FlightControlProfile

var _mouse_delta := Vector2.ZERO
var _smoothed_pitch: float = 0.0
var _smoothed_yaw: float = 0.0
var _smoothed_roll: float = 0.0
var _collective: float = 0.74
var _transition_target: float = 0.0
var _transition: float = 0.0


func _ready() -> void:
	reset_controls()
	ensure_input_actions()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var command := compose_command(_mouse_delta, _read_action_strengths(), delta)
	_mouse_delta = Vector2.ZERO
	command_updated.emit(command)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta += event.relative
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("flight_camera_toggle"):
		camera_toggle_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("flight_restart"):
		restart_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("flight_release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func compose_command(
	mouse_delta: Vector2,
	action_strengths: Dictionary,
	delta: float
) -> PilotCommand:
	var profile := _profile()
	var safe_delta := _safe_delta(delta)
	var mouse_velocity := Vector2.ZERO
	if safe_delta > 0.0:
		mouse_velocity = Vector2(
			_finite_or(mouse_delta.x, 0.0),
			_finite_or(mouse_delta.y, 0.0)
		) / safe_delta

	var pitch_sign := 1.0 if profile.invert_pitch else -1.0
	var yaw_sign := 1.0 if profile.invert_yaw else -1.0
	var pitch_scale := maxf(
		_finite_or(profile.full_pitch_mouse_speed_px_s, 950.0),
		1.0
	)
	var yaw_scale := maxf(
		_finite_or(profile.full_yaw_mouse_speed_px_s, 1050.0),
		1.0
	)
	var target_pitch := profile.shaped_axis(
		mouse_velocity.y * pitch_sign / pitch_scale
	)
	var target_yaw := profile.shaped_axis(
		mouse_velocity.x * yaw_sign / yaw_scale
	)
	_smoothed_pitch = _smooth_axis(
		_smoothed_pitch,
		target_pitch,
		profile.pitch_attack_response,
		profile.pitch_release_response,
		safe_delta
	)
	_smoothed_yaw = _smooth_axis(
		_smoothed_yaw,
		target_yaw,
		profile.yaw_attack_response,
		profile.yaw_release_response,
		safe_delta
	)

	var target_roll := (
		_strength(action_strengths, "roll_right")
		- _strength(action_strengths, "roll_left")
	)
	_smoothed_roll = _smooth_axis(
		_smoothed_roll,
		target_roll,
		profile.roll_attack_response,
		profile.roll_release_response,
		safe_delta
	)

	var collective_input := (
		_strength(action_strengths, "collective_up")
		- _strength(action_strengths, "collective_down")
	)
	_collective = clampf(
		_collective
		+ collective_input
		* maxf(_finite_or(profile.collective_rate_per_second, 0.48), 0.0)
		* safe_delta,
		0.0,
		1.0
	)
	if is_zero_approx(collective_input):
		var nominal := clampf(
			_finite_or(profile.nominal_hover_collective, 0.74),
			0.0,
			1.0
		)
		var window := clampf(
			_finite_or(profile.hover_detent_window, 0.035),
			0.0,
			0.2
		)
		if absf(_collective - nominal) <= window:
			_collective = move_toward(
				_collective,
				nominal,
				maxf(
					_finite_or(profile.hover_detent_pull_per_second, 0.18),
					0.0
				) * safe_delta
			)

	_transition_target = clampf(
		_transition_target
		+ (
			_strength(action_strengths, "transition_forward")
			- _strength(action_strengths, "transition_backward")
		) * maxf(
			_finite_or(profile.transition_input_rate_per_second, 0.55),
			0.0
		) * safe_delta,
		0.0,
		1.0
	)
	_transition = clampf(
		_exp_follow(
			_transition,
			_transition_target,
			profile.transition_follow_response,
			safe_delta
		),
		0.0,
		1.0
	)

	var command := PilotCommand.new()
	command.pitch = _smoothed_pitch
	command.yaw = _smoothed_yaw
	command.roll = _smoothed_roll
	command.collective = _collective
	command.transition = _transition
	command.strafe = Vector3(
		_strength(action_strengths, "strafe_right")
		- _strength(action_strengths, "strafe_left"),
		_strength(action_strengths, "strafe_up")
		- _strength(action_strengths, "strafe_down"),
		0.0
	)
	command.brake = _strength(action_strengths, "brake")
	return command.sanitized()


func ensure_input_actions() -> void:
	for action_name in REQUIRED_ACTIONS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		if InputMap.action_get_events(action_name).is_empty():
			var key_event := InputEventKey.new()
			key_event.physical_keycode = ACTION_KEYS[action_name]
			InputMap.action_add_event(action_name, key_event)


func reset_controls() -> void:
	_mouse_delta = Vector2.ZERO
	_smoothed_pitch = 0.0
	_smoothed_yaw = 0.0
	_smoothed_roll = 0.0
	_collective = clampf(
		_finite_or(_profile().nominal_hover_collective, 0.74),
		0.0,
		1.0
	)
	_transition_target = 0.0
	_transition = 0.0


func get_smoothed_control_demand() -> Vector2:
	return Vector2(_smoothed_yaw, -_smoothed_pitch)


func _profile() -> FlightControlProfile:
	if control_profile == null:
		control_profile = FlightControlProfile.new()
	return control_profile


func _safe_delta(delta: float) -> float:
	return maxf(delta, 0.0) if is_finite(delta) else 0.0


func _exp_follow(current: float, target: float, response: float, delta: float) -> float:
	if delta <= 0.0:
		return current
	var safe_response := clampf(
		response if is_finite(response) else 0.0,
		0.0,
		40.0
	)
	var weight := 1.0 - exp(-safe_response * delta)
	return lerpf(current, target, weight)


func _smooth_axis(
	current: float,
	target: float,
	attack_response: float,
	release_response: float,
	delta: float
) -> float:
	var response := attack_response if absf(target) > absf(current) else release_response
	return clampf(_exp_follow(current, target, response, delta), -1.0, 1.0)


func _read_action_strengths() -> Dictionary:
	return {
		"roll_left": Input.get_action_strength("flight_roll_left"),
		"roll_right": Input.get_action_strength("flight_roll_right"),
		"collective_up": Input.get_action_strength("flight_collective_up"),
		"collective_down": Input.get_action_strength("flight_collective_down"),
		"transition_forward": Input.get_action_strength("flight_transition_forward"),
		"transition_backward": Input.get_action_strength("flight_transition_backward"),
		"strafe_left": Input.get_action_strength("flight_strafe_left"),
		"strafe_right": Input.get_action_strength("flight_strafe_right"),
		"strafe_up": Input.get_action_strength("flight_strafe_up"),
		"strafe_down": Input.get_action_strength("flight_strafe_down"),
		"brake": Input.get_action_strength("flight_brake"),
	}


func _strength(action_strengths: Dictionary, key: String) -> float:
	var value := float(action_strengths.get(key, 0.0))
	return clampf(value, 0.0, 1.0) if is_finite(value) else 0.0


func _finite_or(value: float, fallback: float) -> float:
	return value if is_finite(value) else fallback
