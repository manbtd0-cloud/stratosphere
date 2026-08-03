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

@export var mouse_sensitivity: float = 0.0035
@export var collective_rate_per_second: float = 0.55
@export var transition_rate_per_second: float = 0.45

var _mouse_delta := Vector2.ZERO
var _collective: float = 0.0
var _transition: float = 0.0


func _ready() -> void:
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
	var safe_delta := maxf(delta, 0.0)
	_collective = clampf(
		_collective
		+ (
			_strength(action_strengths, "collective_up")
			- _strength(action_strengths, "collective_down")
		) * collective_rate_per_second * safe_delta,
		0.0,
		1.0
	)
	_transition = clampf(
		_transition
		+ (
			_strength(action_strengths, "transition_forward")
			- _strength(action_strengths, "transition_backward")
		) * transition_rate_per_second * safe_delta,
		0.0,
		1.0
	)

	var command := PilotCommand.new()
	command.pitch = clampf(-mouse_delta.y * mouse_sensitivity, -1.0, 1.0)
	command.yaw = clampf(-mouse_delta.x * mouse_sensitivity, -1.0, 1.0)
	command.roll = (
		_strength(action_strengths, "roll_right")
		- _strength(action_strengths, "roll_left")
	)
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
	_collective = 0.0
	_transition = 0.0


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
	return clampf(float(action_strengths.get(key, 0.0)), 0.0, 1.0)